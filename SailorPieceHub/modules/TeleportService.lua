local GameServices = Import("core/GameServices")
local Remotes = Import("core/Remotes")

local TeleportService = {}
TeleportService.__index = TeleportService

function TeleportService.new()
    local self = setmetatable({
        _lastTeleport = 0,
        _isBusy = false,
        _savedIsland = nil 
    }, TeleportService)
    return self
end

-- =========================================================
-- 🗂️ MÉTODOS DE DADOS (Puxa direto do seu 1_Dados.lua!)
-- =========================================================

function TeleportService:GetIslands()
    local list = {}
    if getgenv().IslandDataMap then
        for island, _ in pairs(getgenv().IslandDataMap) do table.insert(list, island) end
        table.sort(list)
    end
    return list
end

function TeleportService:GetMobsFromIsland(islandName)
    if getgenv().IslandDataMap and getgenv().IslandDataMap[islandName] and getgenv().IslandDataMap[islandName].Mobs then 
        return getgenv().IslandDataMap[islandName].Mobs 
    end
    return {"Nenhum"}
end

function TeleportService:GetIslandByMob(mobName)
    if getgenv().IslandDataMap then
        for island, data in pairs(getgenv().IslandDataMap) do 
            if data.Mobs and table.find(data.Mobs, mobName) then return island end 
        end
    end
    return nil
end

function TeleportService:GetIslandByBoss(bossName)
    if getgenv().IslandDataMap then
        for island, data in pairs(getgenv().IslandDataMap) do 
            if data.Bosses and table.find(data.Bosses, bossName) then return island end 
        end
    end
    return nil
end

function TeleportService:IsBusy() return self._isBusy end

-- =========================================================
-- 🚀 SUA LÓGICA DE MOVIMENTO ORIGINAL (2_Funcoes.lua)
-- =========================================================

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
            if obj.Name == "CheckpointPrompt" or actionText == "set spawn" or (obj.Parent and obj.Parent.Name:find("SpawnPointCrystal")) then
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

function TeleportService:SmartTeleport(islandName, tweenSpeed)
    if self._isBusy then return end
    if not islandName or islandName == "Eventos (Timed Bosses)" then return false end
    
    self._isBusy = true
    self._savedIsland = nil 

    task.spawn(function()
        local dest = (getgenv().TeleportMap and getgenv().TeleportMap[islandName]) or islandName
        if Remotes.TeleportRemote then
            local char = GameServices.LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local oldPos = hrp and hrp.Position or Vector3.zero

            local hum = char and char:FindFirstChild("Humanoid")
            if hum then hum.PlatformStand = false end

            Remotes.TeleportRemote:FireServer(dest)
            
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
