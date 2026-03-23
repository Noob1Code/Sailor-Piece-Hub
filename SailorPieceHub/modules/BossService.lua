-- =========================================================================
-- 👑 BossService
-- =========================================================================

local GameServices = Import("core/GameServices")
local Remotes = Import("core/Remotes")

local BossService = {}
BossService.__index = BossService

-- 🔥 Cronômetro de Ressurreição dos Bosses Silenciosos
local SilentBosses = {
    ["ThiefBoss"] = 8,
    ["DesertBoss"] = 8,
    ["SnowBoss"] = 8,
    ["PandaMiniBoss"] = 8
}

function BossService.new(stateManager, targetService, combatService, teleportService)
    local self = setmetatable({
        _state = stateManager, _target = targetService, _combat = combatService, _teleport = teleportService,
        _isActive = false, _bossStateCache = {}, _deadTimes = {}, _chatConnections = {},
        _lastSummonTime = 0, _patience = 0, _currentBossTargetName = nil, _wasAutoBossOn = false
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
                self._deadTimes[bossName] = nil
                self._patience = 0 
            end
        end
    elseif msg:find("defeated") then
        for _, bossName in ipairs(queue) do
            local baseName = string.lower(bossName:gsub("Boss", ""):gsub("Mini", "")):gsub("%s+", "")
            if msgNoSpaces:find(baseName) then 
                self._bossStateCache[bossName] = "Dead"
                self._deadTimes[bossName] = tick()
                self._patience = 0 
            end
        end
    end
end

function BossService:Start()
    self._isActive = true; self._bossStateCache = {}; self._deadTimes = {}
    pcall(function()
        local TextChatService = game:GetService("TextChatService")
        if TextChatService then
            table.insert(self._chatConnections, TextChatService.MessageReceived:Connect(function(msg)
                if msg and msg.Text then self:_monitorChat(msg.Text) end
            end))
        end
    end)
    pcall(function()
        local defaultChat = GameServices.ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if defaultChat and defaultChat:FindFirstChild("OnMessageDoneFiltering") then
            table.insert(self._chatConnections, defaultChat.OnMessageDoneFiltering.OnClientEvent:Connect(function(msgData)
                if msgData and msgData.Message then self:_monitorChat(msgData.Message) end
            end))
        end
    end)
end

function BossService:Stop()
    self._isActive = false; self._target:ClearTarget(); self._currentBossTargetName = nil
    self._combat:ResetMovement()
    for _, conn in ipairs(self._chatConnections) do conn:Disconnect() end
    table.clear(self._chatConnections)
end

function BossService:SlowUpdate()
    if not self._isActive then return end
    if self._teleport:IsBusy() then return end

    local isAutoBoss = self._state:Get("AutoBoss")
    local isAutoSummon = self._state:Get("AutoSummon")
    local queue = self._state:Get("SelectedBosses") or {}

    if isAutoBoss and not self._wasAutoBossOn then
        self._bossStateCache = {}; self._deadTimes = {}
        self._combat:ResetMovement()
    end
    self._wasAutoBossOn = isAutoBoss

    -- 🔥 1. ATUALIZA O CRONÔMETRO DOS BOSSES MORTOS
    for _, b in ipairs(queue) do
        if self._bossStateCache[b] == "Dead" and self._deadTimes[b] then
            local waitTime = SilentBosses[b] or 60
            if tick() - self._deadTimes[b] > waitTime then
                self._bossStateCache[b] = "PendingCheck"
                self._deadTimes[b] = nil
                print("👑 O Boss " .. b .. " deve ter renascido. Voltando para a fila!")
            end
        end
    end

    if isAutoSummon then
        local summonBoss = self._state:Get("SelectedSummonBoss")
        if summonBoss and summonBoss ~= "Nenhum" then
            self._currentBossTargetName = summonBoss
            if not self._target:FindNearestBoss(summonBoss) then
                if self._teleport:GetCurrentIsland() ~= "Boss Island" then
                    self._combat:ResetMovement()
                    self._teleport:SmartTeleport("Boss Island", self._state:Get("TweenSpeed"))
                    return
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
        -- 🔥 2. ESCOLHE O PRÓXIMO BOSS DA FILA
        local decidedBoss = nil
        for _, b in ipairs(queue) do
            if self._bossStateCache[b] == "Alive" then decidedBoss = b; break end
        end

        if not decidedBoss and #queue > 0 then
            for _, b in ipairs(queue) do
                if self._bossStateCache[b] ~= "Dead" then 
                    decidedBoss = b; self._bossStateCache[b] = "PendingCheck"; break 
                end
            end
        end

        self._currentBossTargetName = decidedBoss

        if decidedBoss then
            -- 🔥 3. BÚSSOLA DE NAVEGAÇÃO (A mágica das múltiplas ilhas)
            local islandNeeded = self._teleport:GetIslandByBoss(decidedBoss)
            
            if islandNeeded then
                local currentIsland = self._teleport:GetCurrentIsland()
                
                if currentIsland ~= islandNeeded then
                    -- Está na ilha errada. Para de bater, limpa o alvo e VIAJA!
                    self._target:ClearTarget()
                    self._combat:ResetMovement()
                    self._teleport:SmartTeleport(islandNeeded, self._state:Get("TweenSpeed"))
                    return
                end
            end

            -- 🔥 4. JÁ ESTÁ NA ILHA CERTA? PROCURA O BOSS NO MAPA!
            if not self._target:FindNearestBoss(decidedBoss) then
                self._patience = self._patience + 1
                local maxPatience = (self._bossStateCache[decidedBoss] == "Alive") and 10 or 4
                
                if self._patience > maxPatience then
                    self._bossStateCache[decidedBoss] = "Dead"
                    self._deadTimes[decidedBoss] = tick()
                    self._patience = 0
                    self._currentBossTargetName = nil
                end
            else
                self._patience = 0
            end
        else
            -- Se todos os Bosses da fila estiverem "Dead" esperando renascer, limpa o alvo.
            self._currentBossTargetName = nil
        end
        return
    end

    self._currentBossTargetName = nil
end

function BossService:FastUpdate()
    if not self._isActive or self._teleport:IsBusy() then return end
    
    -- 🔥 5. LIBERA O JOGADOR QUANDO A FILA ACABAR
    if not self._currentBossTargetName then
        self._combat:ResetMovement()
        return
    end
    
    local boss = self._target:FindNearestBoss(self._currentBossTargetName)
    if boss then 
        local arrived = self._combat:MoveTo(boss)
        if arrived then self._combat:Attack(boss) end
    else 
        self._combat:ResetMovement() 
    end
end

return BossService
