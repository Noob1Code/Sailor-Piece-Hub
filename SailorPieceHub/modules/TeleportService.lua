local GameServices = Import("core/GameServices")
local Remotes = Import("core/Remotes")

local TeleportService = {}
TeleportService.__index = TeleportService

local TeleportMap = {
    ["Starter"] = "Starter", ["Jungle"] = "Jungle", ["Desert"] = "Desert",
    ["Snow"] = "Snow", ["Sailor"] = "Sailor", ["Shibuya"] = "Shibuya",
    ["Hueco Mundo"] = "HuecoMundo", ["Boss Island"] = "Boss", ["Dungeon"] = "Dungeon",
    ["Shinjuku"] = "Shinjuku", ["Slime"] = "Slime", ["Academy"] = "Academy",
    ["Judgement"] = "Judgement", ["Soul Society"] = "SoulSociety"
}

function TeleportService.new()
    local self = setmetatable({
        _lastTeleport = 0,
        _isBusy = false,
        _savedIsland = nil 
    }, TeleportService)
    return self
end

function TeleportService:IsBusy() return self._isBusy end

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

-- 🔥 SEU AutoSaveSpawn ORIGINAL (Adaptado assíncrono)
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
        local dest = TeleportMap[islandName] or islandName
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
