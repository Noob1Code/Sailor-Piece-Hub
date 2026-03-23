-- =========================================================================
-- 👑 BossService
-- =========================================================================

local GameServices = Import("core/GameServices")
local Remotes = Import("core/Remotes")

local BossService = {}
BossService.__index = BossService

-- 🔥 Cronômetro VIP (Apenas estes vão ser re-checados por tempo de 8s)
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

-- 📡 O SEU SNIPER DE CHAT (Event-Driven)
function BossService:_monitorChat(mensagem)
    if not self._state:Get("AutoBoss") then return end
    local msg = string.lower(mensagem)
    local msgNoSpaces = msg:gsub("%s+", "")
    local queue = self._state:Get("SelectedBosses") or {}

    if msg:find("spawned") then
        for _, bossName in ipairs(queue) do
            local baseName = string.lower(bossName:gsub("Boss", ""):gsub("Mini", "")):gsub("%s+", "")
            if msgNoSpaces:find(baseName) then 
                -- 🔥 Acorda o Boss de Tempo!
                self._bossStateCache[bossName] = "Alive"
                self._deadTimes[bossName] = nil
                self._patience = 0 
                print("🚨 [Boss Sniper] " .. bossName .. " APARECEU NO CHAT! Interceptando...")
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
        -- Varredura inicial: Coloca todos para checar a primeira vez!
        for _, b in ipairs(queue) do self._bossStateCache[b] = "PendingCheck" end
    end
    self._wasAutoBossOn = isAutoBoss

    -- 🔥 1. RESSURREIÇÃO RESTRITA: Apenas SilentBosses ganham nova chance por tempo
    for _, b in ipairs(queue) do
        if self._bossStateCache[b] == "Dead" and self._deadTimes[b] then
            if SilentBosses[b] then
                if tick() - self._deadTimes[b] > SilentBosses[b] then
                    self._bossStateCache[b] = "PendingCheck"
                    self._deadTimes[b] = nil
                    print("👑 Boss Silencioso " .. b .. " renasceu. Voltando para a fila!")
                end
            end
            -- Se for Boss de Tempo (Aizen, Sukuna) ou Invocação (Saber), 
            -- ele simplesmente fica "Dead" aqui e NÃO gera teleporte até o chat avisar!
        end
    end

    -- =========================================================
    -- PRIORIDADE 1: INVOCAÇÃO (SUMMON EXCLUSIVO)
    -- =========================================================
    if isAutoSummon then
        local summonBoss = self._state:Get("SelectedSummonBoss")
        if summonBoss and summonBoss ~= "Nenhum" then
            self._currentBossTargetName = summonBoss
            if not self._target:FindNearestBoss(summonBoss) then
                local currentIsland = self._teleport:GetCurrentIsland()
                if currentIsland ~= "Boss Island" then
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

    -- =========================================================
    -- PRIORIDADE 2: FILA DE BOSSES
    -- =========================================================
    if isAutoBoss then
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
            local islandNeeded = self._teleport:GetIslandByBoss(decidedBoss)
            if islandNeeded then
                local currentIsland = self._teleport:GetCurrentIsland()
                if currentIsland ~= islandNeeded then
                    self._target:ClearTarget()
                    self._combat:ResetMovement()
                    self._teleport:SmartTeleport(islandNeeded, self._state:Get("TweenSpeed"))
                    return
                end
            end

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
            self._currentBossTargetName = nil
        end
        return
    end

    self._currentBossTargetName = nil
end

function BossService:FastUpdate()
    if not self._isActive or self._teleport:IsBusy() then return end
    
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
