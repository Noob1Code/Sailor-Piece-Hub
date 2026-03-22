-- =========================================================================
-- 👑 BossService
-- Gerencia a Fila de Bosses, Invocação (Summon) e o Boss Sniper (Chat).
-- =========================================================================

local GameServices = Import("core/GameServices")
local Remotes = Import("core/Remotes")

local BossService = {}
BossService.__index = BossService

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
        _bossStateCache = {}, 
        _chatConnections = {},
        _lastTeleportTime = 0,
        _lastSummonTime = 0,
        _patience = 0,
        _currentBossTargetName = nil 
    }, BossService)
    return self
end

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

    pcall(function()
        local TextChatService = game:GetService("TextChatService")
        if TextChatService then
            local conn = TextChatService.MessageReceived:Connect(function(msg)
                if msg and msg.Text then self:_monitorChat(msg.Text) end
            end)
            table.insert(self._chatConnections, conn)
        end
    end)

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
    self._combat:ResetMovement()
    
    for _, conn in ipairs(self._chatConnections) do conn:Disconnect() end
    table.clear(self._chatConnections)
    print("🛑 BossService: Parado.")
end

function BossService:SlowUpdate()
    if not self._isActive then return end

    local isAutoSummon = self._state:Get("AutoSummon")
    local isAutoBoss = self._state:Get("AutoBoss")

    if isAutoSummon then
        local summonBoss = self._state:Get("SelectedSummonBoss")
        if summonBoss and summonBoss ~= "Nenhum" then
            self._currentBossTargetName = summonBoss
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
            return 
        end
    end

    if isAutoBoss then
        local queue = self._state:Get("SelectedBosses") or {}
        local decidedBoss = nil

        for _, b in ipairs(queue) do
            if self._bossStateCache[b] == "Alive" then decidedBoss = b; break end
        end

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

        if decidedBoss and not self._target:FindNearestBoss(decidedBoss) then
            local targetIsland = BossIslands[decidedBoss]
            if targetIsland and tick() - self._lastTeleportTime > 5 then
                if Remotes.TeleportRemote then Remotes.TeleportRemote:FireServer(targetIsland) end
                self._lastTeleportTime = tick()
            end

            self._patience = self._patience + 1
            local maxPatience = (self._bossStateCache[decidedBoss] == "Alive") and 10 or 4
            
            if self._patience > maxPatience then
                self._bossStateCache[decidedBoss] = "Dead"
                self._patience = 0
                self._currentBossTargetName = nil
            end
        else
            self._patience = 0
        end
        return
    end

    self._currentBossTargetName = nil
end

function BossService:FastUpdate()
    if not self._isActive or not self._currentBossTargetName then 
        self._combat:ResetMovement()
        return 
    end

    local boss = self._target:FindNearestBoss(self._currentBossTargetName)
    
    if boss then
        self._combat:MoveTo(boss)
        self._combat:Attack(boss)
    else
        self._combat:ResetMovement()
    end
end

return BossService
