-- =========================================================================
-- 🗺️ TeleportService (Refatorado 100% POO)
-- =========================================================================

local GameServices = Import("core/GameServices")
local Remotes = Import("core/Remotes")

local TeleportService = {}
TeleportService.__index = TeleportService

-- 🔥 DADOS MIGRADOS DO 1_Dados.lua DIRETAMENTE PARA A CLASSE PRIVADA
local IslandDataMap = {
    ["Starter"] = { Mobs = {"Thief"}, Bosses = {"ThiefBoss"} },
    ["Jungle"] = { Mobs = {"Monkey"}, Bosses = {"MonkeyBoss"} },
    ["Desert"] = { Mobs = {"DesertBandit"}, Bosses = {"DesertBoss"} },
    ["Snow"] = { Mobs = {"FrostRogue"}, Bosses = {"SnowBoss"} },
    ["Sailor"] = { Mobs = {}, Bosses = {"JinwooBoss", "AlucardBoss"} }, 
    ["Shibuya"] = { Mobs = {"Sorcerer"}, Bosses = {"PandaMiniBoss", "YujiBoss", "SukunaBoss", "GojoBoss"} },
    ["Hueco Mundo"] = { Mobs = {"Hollow"}, Bosses = {"AizenBoss"} },
    ["Shinjuku"] = { Mobs = {"Curse", "StrongSorcerer"}, Bosses = {} },
    ["Slime"] = { Mobs = {"Slime"}, Bosses = {} },
    ["Academy"] = { Mobs = {"AcademyTeacher"}, Bosses = {} },
    ["Judgement"] = { Mobs = {"Swordsman"}, Bosses = {"YamatoBoss"} },
    ["Soul Society"] = { Mobs = {"Quincy"}, Bosses = {} },
    ["Boss Island"] = { Mobs = {}, Bosses = {"SaberBoss", "QinShiBoss", "IchigoBoss", "GilgameshBoss", "BlessedMaidenBoss", "SaberAlterBoss"} },
    ["Eventos (Timed Bosses)"] = { Mobs = {}, Bosses = {"MadokaBoss", "Rimuru"} }
}

local TeleportMap = {
    ["Starter"] = "Starter", ["Jungle"] = "Jungle", ["Desert"] = "Desert",
    ["Snow"] = "Snow", ["Sailor"] = "Sailor", ["Shibuya"] = "Shibuya",
    ["Hueco Mundo"] = "HuecoMundo", ["Boss Island"] = "Boss", ["Dungeon"] = "Dungeon",
    ["Shinjuku"] = "Shinjuku", ["Slime"] = "Slime", ["Academy"] = "Academy",
    ["Judgement"] = "Judgement", ["Soul Society"] = "SoulSociety"
}

function TeleportService.new()
    local self = setmetatable({
        _lastTeleportTime = 0,
        _isBusy = false,
        _savedIsland = nil 
    }, TeleportService)
    return self
end

function TeleportService:IsBusy() 
    return self._isBusy 
end

-- =========================================================================
-- 🗂️ MÉTODOS DE CONSULTA (GETTERS)
-- =========================================================================

function TeleportService:GetIslands()
    local list = {}
    for island, _ in pairs(IslandDataMap) do table.insert(list, island) end
    table.sort(list)
    return list
end

function TeleportService:GetMobsFromIsland(islandName)
    if IslandDataMap[islandName] and IslandDataMap[islandName].Mobs then
        return IslandDataMap[islandName].Mobs
    end
    return {"Nenhum"}
end

-- Lógica migrada do getIslandByTarget original
function TeleportService:_getIslandByTarget(typeStr, name)
    for island, data in pairs(IslandDataMap) do
        if typeStr == "Mob" and data.Mobs then
            for _, mob in ipairs(data.Mobs) do if mob == name then return island end end
        elseif typeStr == "Boss" and data.Bosses then
            for _, boss in ipairs(data.Bosses) do if boss == name then return island end end
        end
    end
    return nil
end

function TeleportService:GetIslandByMob(mobName)
    return self:_getIslandByTarget("Mob", mobName)
end

function TeleportService:GetIslandByBoss(bossName)
    return self:_getIslandByTarget("Boss", bossName)
end

-- Lógica migrada do getCurrentIsland original
function TeleportService:GetCurrentIsland()
    local char = GameServices.LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = char.HumanoidRootPart.Position
    local closestIsland = nil
    local minDist = math.huge
    
    local npcsFolder = GameServices.Workspace:FindFirstChild("NPCs")
    if npcsFolder then
        for _, npc in pairs(npcsFolder:GetChildren()) do
            local hrp = npc:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (myPos - hrp.Position).Magnitude
                if dist < minDist then
                    local isBoss = npc.Name:lower():find("boss") or npc:GetAttribute("Boss")
                    local baseName = npc.Name:gsub("%d+", "")
                    local island = self:_getIslandByTarget(isBoss and "Boss" or "Mob", baseName)
                    if island and island ~= "Eventos (Timed Bosses)" then 
                        minDist = dist
                        closestIsland = island 
                    end
                end
            end
        end
    end
    return closestIsland
end

-- =========================================================================
-- 🚀 MÉTODOS DE AÇÃO MIGRADOS DO 2_Funcoes.lua PARA CLASSE
-- =========================================================================

-- Lógica migrada do SafeTeleport original
function TeleportService:SafeTeleport(targetPos, heightOffset, tweenSpeed)
    local char = GameServices.LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    
    local distance = (hrp.Position - targetPos).Magnitude
    local tempo = distance / (tweenSpeed or 150)
    if tempo < 0.1 then tempo = 0.1 end 
    
    local tween = GameServices.TweenService:Create(hrp, TweenInfo.new(tempo, Enum.EasingStyle.Linear), {CFrame = CFrame.new(targetPos + Vector3.new(0, heightOffset or 0, 0))})
    tween:Play()
    return tween
end

-- Lógica migrada do AutoSaveSpawn original
function TeleportService:AutoSaveSpawn(targetIslandName, tweenSpeed)
    if self._savedIsland == targetIslandName then return end

    local char = GameServices.LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = char.HumanoidRootPart
    local myPos = hrp.Position
    local closestPrompt = nil
    local targetPart = nil
    local minDist = math.huge

    for _, obj in pairs(GameServices.Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local actionText = string.lower(obj.ActionText)
            local promptName = obj.Name
            
            if promptName == "CheckpointPrompt" or actionText == "set spawn" or (obj.Parent and obj.Parent.Name:find("SpawnPointCrystal")) then
                local part = obj.Parent
                if part and part:IsA("BasePart") then
                    local dist = (part.Position - myPos).Magnitude
                    if dist < minDist and dist < 800 then
                        minDist = dist
                        closestPrompt = obj
                        targetPart = part
                    end
                end
            end
        end
    end

    if closestPrompt and targetPart then
        print("🚩 Salvando Spawn...")
        local tween = self:SafeTeleport(targetPart.Position, 2, tweenSpeed)
        
        if tween then 
            tween.Completed:Wait() 
            task.wait(0.5) 
        else
            hrp.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
            task.wait(0.5)
        end
        
        if fireproximityprompt then 
            fireproximityprompt(closestPrompt)
            task.wait(0.2)
            fireproximityprompt(closestPrompt)
        end
        
        self._savedIsland = targetIslandName
        task.wait(0.5)
    end
end

-- Lógica migrada do SmartIslandTeleport original
function TeleportService:SmartTeleport(islandName, tweenSpeed)
    if self._isBusy then return end
    if not islandName or islandName == "Eventos (Timed Bosses)" then return false end
    
    -- Cooldown inteligente original
    if tick() - self._lastTeleportTime < 3 then return false end 
    
    self._isBusy = true
    self._savedIsland = nil 

    task.spawn(function()
        local dest = TeleportMap[islandName] or islandName
        if Remotes.TeleportRemote then
            local char = GameServices.LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local oldPos = hrp and hrp.Position or Vector3.zero

            local hum = char and char:FindFirstChild("Humanoid")
            if hum then hum.PlatformStand = false end

            Remotes.TeleportRemote:FireServer(dest)
            self._lastTeleportTime = tick()
            
            if hrp then
                for i = 1, 15 do 
                    task.wait(0.5)
                    local currentHrp = GameServices.LocalPlayer.Character and GameServices.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if currentHrp and (currentHrp.Position - oldPos).Magnitude > 200 then break end
                end
            else
                task.wait(3)
            end
            
            task.wait(1.5) 
            self:AutoSaveSpawn(islandName, tweenSpeed)
        end
        self._isBusy = false
    end)
end

return TeleportService
