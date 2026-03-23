local GameServices = Import("core/GameServices")
local Remotes = Import("core/Remotes")
local TweenUtil = Import("utils/TweenUtil")

local TeleportService = {}
TeleportService.__index = TeleportService

local IslandData = {
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
    ["Judgement"] = "Judgement", ["Soul Society"] = "SoulSociety",
    ["Eventos (Timed Bosses)"] = "Eventos"
}

function TeleportService.new()
    local self = setmetatable({
        _lastTeleport = 0,
        _isBusy = false,
        _savedIsland = nil
    }, TeleportService)
    return self
end

function TeleportService:GetIslands()
    local list = {}
    for island, _ in pairs(IslandData) do table.insert(list, island) end
    table.sort(list)
    return list
end

function TeleportService:GetMobsFromIsland(islandName)
    if IslandData[islandName] and IslandData[islandName].Mobs then return IslandData[islandName].Mobs end
    return {"Nenhum"}
end

function TeleportService:GetIslandByMob(mobName)
    for island, data in pairs(IslandData) do if table.find(data.Mobs, mobName) then return island end end
    return nil
end

function TeleportService:GetIslandByBoss(bossName)
    for island, data in pairs(IslandData) do if table.find(data.Bosses, bossName) then return island end end
    return nil
end

function TeleportService:IsBusy() return self._isBusy end

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
                    local baseName = npc.Name:gsub("%d+", "")
                    local island = self:GetIslandByMob(baseName) or self:GetIslandByBoss(baseName) or self:GetIslandByBoss(npc.Name)
                    if island and island ~= "Eventos (Timed Bosses)" then 
                        minDist = dist; closestIsland = island 
                    end
                end
            end
        end
    end
    return closestIsland
end

function TeleportService:SmartTeleport(islandName, tweenSpeed)
    if self._isBusy then return end
    self._isBusy = true
    self._savedIsland = nil 
    task.spawn(function()
        pcall(function()
            local dest = TeleportMap[islandName] or islandName
            if Remotes.TeleportRemote then
                local char = GameServices.LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local oldPos = hrp and hrp.Position or Vector3.zero

                TweenUtil.StopTween(hrp)
                if char and char:FindFirstChild("Humanoid") then char.Humanoid.PlatformStand = false end

                Remotes.TeleportRemote:FireServer(dest)
                print("🗺️ Viajando para a ilha: " .. islandName)

                for i = 1, 15 do
                    task.wait(0.5)
                    local currentHrp = GameServices.LocalPlayer.Character and GameServices.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if currentHrp and (currentHrp.Position - oldPos).Magnitude > 200 then break end
                end
                
                task.wait(1.5) 
                self:_executeSaveSpawn(islandName, tweenSpeed)
            end
        end)
        self._isBusy = false
    end)
end

function TeleportService:_executeSaveSpawn(targetIslandName, tweenSpeed)
    if self._savedIsland == targetIslandName then 
        print("✅ Spawn já estava salvo na ilha: " .. tostring(targetIslandName))
        return 
    end

    local char = GameServices.LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = char.HumanoidRootPart
    local closestPrompt = nil
    local targetPart = nil
    local minDist = math.huge

    for _, obj in pairs(GameServices.Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local actionText = string.lower(obj.ActionText)
            if obj.Name == "CheckpointPrompt" or actionText == "set spawn" or (obj.Parent and obj.Parent.Name:find("SpawnPointCrystal")) then
                local part = obj.Parent
                if part and part:IsA("BasePart") then
                    local dist = (part.Position - hrp.Position).Magnitude
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
        print("🚩 Salvando Spawn na nova ilha...")
        local targetPos = targetPart.Position + Vector3.new(0, 3, 0)
        
        local tw = TweenUtil.MoveToPosition(char, targetPos, tweenSpeed or 150)
        if tw then tw.Completed:Wait() else
            hrp.CFrame = CFrame.new(targetPos)
            task.wait(0.5)
        end
        
        task.wait(0.3)
        if fireproximityprompt then 
            fireproximityprompt(closestPrompt)
            task.wait(0.2)
            fireproximityprompt(closestPrompt)
            self._savedIsland = targetIslandName
            print("✅ Monitor atualizado: Spawn salvo em " .. targetIslandName)
        end
    end
end

return TeleportService
