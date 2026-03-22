-- =========================================================================
-- 👑 BossService
-- Gerencia a Fila de Bosses, Invocação (Summon) e o Boss Sniper (Chat).
-- =========================================================================

local GameServices = Import("core/GameServices")
local Remotes = Import("core/Remotes")

local BossService = {}
BossService.__index = BossService

-- Mapeamento estático para remover a dependência de globais (1_Dados)
local BossIslands = {
    ["ThiefBoss"] = "Starter", ["MonkeyBoss"] = "Jungle", ["DesertBoss"] = "Desert",
    ["SnowBoss"] = "Snow", ["JinwooBoss"] = "Sailor", ["AlucardBoss"] = "Sailor",
    ["PandaMiniBoss"] = "Shibuya", ["YujiBoss"] = "Shibuya", ["SukunaBoss"] = "Shibuya", ["GojoBoss"] = "Shibuya",
    ["AizenBoss"] = "Hueco Mundo", ["YamatoBoss"] = "Judgement",
    ["SaberBoss"] = "Boss", ["QinShiBoss"] = "Boss", ["IchigoBoss"] = "Boss", ["GilgameshBoss"] = "Boss", ["BlessedMaidenBoss"] = "Boss", ["SaberAlterBoss"] = "Boss",
    ["MadokaBoss"] = "Eventos", ["Rimuru"] = "Eventos"
}

function BossService.new(stateManager, targetService, combatService)
    local self = setmetatable({
        _state = stateManager,
        _target = targetService,
        _combat = combatService,
        _isActive = false,
        _bossStateCache = {}, -- Guarda "Alive", "Dead", "PendingCheck"
        _chatConnections = {},
        _lastTeleportTime = 0,
        _lastSummonTime = 0,
        _patience = 0,
        _currentBossTargetName = nil -- O nome do boss que decidimos focar
    }, BossService)
    return self
end

-- =========================================================================
-- MONITORAMENTO (BOSS SNIPER)
-- =========================================================================

function BossService:_monitorChat(mensagem)
    if not self._state:Get("AutoBoss") then return end
    
    local msg = string.lower(mensagem)
    local msgNoSpaces = msg:gsub("%s+", "")
    local queue = self._state:Get("SelectedBosses") or {}

    if msg:find("spawned") then
        for _, bossName in ipairs(queue) do
            local baseName = string.lower(bossName:gsub("Boss", ""):gsub("Mini", "")):gsub("%s+", "")
            if msgNoSpaces:find(baseName) then
                self._bossStateCache[bossName] = "Alive"
                self._patience = 0
                -- Exemplo de uso de notificação se a UI estivesse pronta:
                -- self._state:Set("Notify", {Title="🚨 Boss Sniper", Text=bossName.." spawnou!"})
            end
        end
    elseif msg:find("defeated") then
        for _, bossName in ipairs(queue) do
            local baseName = string.lower(bossName:gsub("Boss", ""):gsub("Mini", "")):gsub("%s+", "")
            if msgNoSpaces:find(baseName) then
                self._bossStateCache[bossName] = "Dead"
                self._patience = 0
            end
        end
    end
end

function BossService:Start()
    self._isActive = true
    self._bossStateCache = {}
    print("👑 BossService: Monitoramento iniciado.")

    -- Conecta no novo sistema de chat do Roblox
    pcall(function()
        local TextChatService = GameServices.HttpService:GetService("TextChatService")
        if TextChatService then
            local conn = TextChatService.MessageReceived:Connect(function(msg)
                if msg and msg.Text then self:_monitorChat(msg.Text) end
            end)
            table.insert(self._chatConnections, conn)
        end
    end)

    -- Conecta no sistema de chat legado
    pcall(function()
        local defaultChat = GameServices.ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if defaultChat and defaultChat:FindFirstChild("OnMessageDoneFiltering") then
            local conn = defaultChat.OnMessageDoneFiltering.OnClientEvent:Connect(function(msgData)
                if msgData and msgData.Message then self:_monitorChat(msgData.Message) end
            end)
            table.insert(self._chatConnections, conn)
        end
    end)
end

function BossService:Stop()
    self._isActive = false
    self._target:ClearTarget()
    self._currentBossTargetName = nil
    for _, conn in ipairs(self._chatConnections) do conn:Disconnect() end
    table.clear(self._chatConnections)
    print("🛑 BossService: Parado.")
end

-- =========================================================================
-- LÓGICA DE DECISÃO (Cérebro - Roda a cada 1 segundo)
-- =========================================================================

function BossService:SlowUpdate()
    if not self._isActive then return end

    local isAutoSummon = self._state:Get("AutoSummon")
    local isAutoBoss = self._state:Get("AutoBoss")

    -- 1. PRIORIDADE: AUTO SUMMON
    if isAutoSummon then
        local summonBoss = self._state:Get("SelectedSummonBoss")
        if summonBoss and summonBoss ~= "Nenhum" then
            self._currentBossTargetName = summonBoss
            
            -- Se não achamos o boss no mapa, tentamos teleportar e invocar
            if not self._target:FindNearestBoss(summonBoss) then
                if tick() - self._lastTeleportTime > 5 then
                    if Remotes.TeleportRemote then Remotes.TeleportRemote:FireServer("Boss") end
                    self._lastTeleportTime = tick()
                end
                
                if tick() - self._lastSummonTime > 5 and Remotes.SummonBossRemote then
                    Remotes.SummonBossRemote:FireServer(summonBoss)
                    self._lastSummonTime = tick()
                end
            end
            return -- Bloqueia a fila normal se o Summon estiver ligado
        end
    end

    -- 2. PRIORIDADE: FILA DE BOSSES
    if isAutoBoss then
        local queue = self._state:Get("SelectedBosses") or {}
        local decidedBoss = nil

        -- Procura primeiro os que temos certeza que estão vivos (Sniper)
        for _, b in ipairs(queue) do
            if self._bossStateCache[b] == "Alive" then decidedBoss = b; break end
        end

        -- Se não tiver nenhum "Alive", assume PendingCheck no primeiro da fila
        if not decidedBoss and #queue > 0 then
            for _, b in ipairs(queue) do
                if self._bossStateCache[b] ~= "Dead" then 
                    decidedBoss = b
                    self._bossStateCache[b] = "PendingCheck"
                    break 
                end
            end
        end

        self._currentBossTargetName = decidedBoss

        -- Se decidimos um Boss, gerencia a paciência e teleporte
        if decidedBoss and not self._target:FindNearestBoss(decidedBoss) then
            local targetIsland = BossIslands[decidedBoss]
            if targetIsland and tick() - self._lastTeleportTime > 5 then
                if Remotes.TeleportRemote then Remotes.TeleportRemote:FireServer(targetIsland) end
                self._lastTeleportTime = tick()
            end

            -- Sistema de Paciência: Se não achou na ilha após X segundos, marca como morto
            self._patience = self._patience + 1
            local maxPatience = (self._bossStateCache[decidedBoss] == "Alive") and 10 or 4
            
            if self._patience > maxPatience then
                self._bossStateCache[decidedBoss] = "Dead"
                self._patience = 0
                self._currentBossTargetName = nil
            end
        else
            self._patience = 0 -- Achou o boss, reseta paciência
        end
        return
    end

    self._currentBossTargetName = nil
end

-- =========================================================================
-- LÓGICA DE AÇÃO (Músculos - Roda a cada frame)
-- =========================================================================

function BossService:FastUpdate()
    if not self._isActive or not self._currentBossTargetName then return end

    local boss = self._target:FindNearestBoss(self._currentBossTargetName)
    
    if boss then
        self._combat:MoveTo(boss)
        self._combat:Attack(boss)
    end
end

return BossService
