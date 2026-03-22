-- =====================================================================
-- ⚔️ SERVICES: CombatService.lua
-- =====================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer

local CombatService = {}
CombatService.__index = CombatService

function CombatService.new(Constants, Config)
    local self = setmetatable({}, CombatService)
    self.Constants = Constants
    self.Config = Config
    self.OrbitAngle = 0
    self.LastAttackTime = 0
    self.AttackCooldown = 0.1
    self.LastTeleportTime = 0
    
    self.CurrentTween = nil
    self.LastTweenTargetPos = nil
    
    self.Remotes = { Combat = nil, Ability = nil, Teleport = nil }
    self:LoadRemotes()
    return self
end

function CombatService:LoadRemotes()
    pcall(function()
        self.Remotes.Combat = ReplicatedStorage:WaitForChild("CombatSystem"):WaitForChild("Remotes"):WaitForChild("RequestHit")
        self.Remotes.Ability = ReplicatedStorage:WaitForChild("AbilitySystem"):WaitForChild("Remotes"):WaitForChild("RequestAbility")
        self.Remotes.Teleport = ReplicatedStorage:FindFirstChild("TeleportToPortal", true)
    end)
end

function CombatService:SetCharacterFrozen(isFrozen)
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hum and hrp then
        if isFrozen then hrp.Velocity = Vector3.zero; hum.PlatformStand = true else hum.PlatformStand = false end
    end
end

function CombatService:SmartIslandTeleport(islandName)
    if not islandName or islandName == "Eventos (Timed Bosses)" then return false end
    if tick() - self.LastTeleportTime < 3 then return false end 
    
    local dest = self.Constants.TeleportMap[islandName] or islandName
    if self.Remotes.Teleport then
        if self.CurrentTween then self.CurrentTween:Cancel(); self.CurrentTween = nil end
        self:SetCharacterFrozen(true)
        
        self.Remotes.Teleport:FireServer(dest)
        self.LastTeleportTime = tick()
        task.wait(1.5) 
        
        if self.Config.CurrentSpawnIsland ~= islandName then
            local success = self:AutoSaveSpawn() 
            if success then self.Config.CurrentSpawnIsland = islandName end
        end
        
        self:SetCharacterFrozen(false)
        return true
    end
    return false
end

function CombatService:AutoSaveSpawn()
    pcall(function()
        local char = LP.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
        local hrp = char.HumanoidRootPart
        
        local closestPrompt, targetPart = nil, nil
        
        for attempt = 1, 8 do
            local myPos = hrp.Position
            local minDist = math.huge
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("ProximityPrompt") then
                    local actionText = string.lower(obj.ActionText or "")
                    local objName = string.lower(obj.Name or "")
                    if objName == "checkpointprompt" or actionText:find("spawn") or actionText:find("checkpoint") then
                        local part = obj.Parent
                        if part and part:IsA("BasePart") then
                            local dist = (part.Position - myPos).Magnitude
                            if dist < 1500 then minDist = dist; closestPrompt = obj; targetPart = part end
                        end
                    end
                end
            end
            if closestPrompt then break end
            task.wait(0.5)
        end

        if closestPrompt and targetPart then
            self:SetCharacterFrozen(true)
            local distance = (hrp.Position - targetPart.Position).Magnitude
            if distance > 10 then
                local tempo = distance / math.max(self.Config.TweenSpeed, 50)
                local tween = TweenService:Create(hrp, TweenInfo.new(tempo, Enum.EasingStyle.Linear), {CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)})
                tween:Play(); tween.Completed:Wait()
            else
                hrp.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
            end
            
            hrp.Velocity = Vector3.zero
            task.wait(0.5)
            
            -- FIX DE PROXIMITY PROMPT: Garante que é válido e habilitado
            if closestPrompt and closestPrompt:IsA("ProximityPrompt") and closestPrompt.Enabled and fireproximityprompt then 
                fireproximityprompt(closestPrompt)
                task.wait(0.2)
                fireproximityprompt(closestPrompt)
            end
            task.wait(0.5)
            return true 
        end
    end)
    return false
end

function CombatService:MoveToTarget(targetInstance, customDistance)
    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
    
    local hrp = char.HumanoidRootPart
    local targetPos
    
    if targetInstance:IsA("Model") then
        local targetHrp = targetInstance:FindFirstChild("HumanoidRootPart")
        if not targetHrp then return false end
        targetPos = targetHrp.Position
        
        local positionType = self.Config.AttackPosition
        local isLethal = targetInstance:GetAttribute("Damage") and targetInstance:GetAttribute("Damage") > 100000
        if isLethal and positionType == "Abaixo" then positionType = "Acima" end

        local dist = customDistance or self.Config.Distance
        if positionType == "Orbital" then
            self.OrbitAngle = self.OrbitAngle + math.rad(15)
            targetPos = targetPos + Vector3.new(math.cos(self.OrbitAngle) * dist, 5, math.sin(self.OrbitAngle) * dist)
        elseif positionType == "Atrás" then targetPos = targetPos - (targetHrp.CFrame.LookVector * dist)
        elseif positionType == "Abaixo" then targetPos = targetPos + Vector3.new(0, -dist, 0)
        else targetPos = targetPos + Vector3.new(0, dist, 0) end
    elseif targetInstance:IsA("BasePart") then
        targetPos = targetInstance.Position
    else
        return false
    end

    local targetTargetPos = targetInstance:IsA("Model") and targetInstance:FindFirstChild("HumanoidRootPart") and targetInstance.HumanoidRootPart.Position or targetInstance.Position
    local targetCFrame = CFrame.new(targetPos, targetTargetPos)
    local distance = (hrp.Position - targetPos).Magnitude
    
    if distance > 720 then 
        if self.CurrentTween then self.CurrentTween:Cancel(); self.CurrentTween = nil end
        self:SetCharacterFrozen(false)
        return false 
    end
    
    self:SetCharacterFrozen(true)
    
    if distance > 15 then
        if self.CurrentTween and self.CurrentTween.PlaybackState == Enum.PlaybackState.Playing then
            if self.LastTweenTargetPos and (self.LastTweenTargetPos - targetPos).Magnitude > 10 then self.CurrentTween:Cancel() else return true end
        end

        local tempo = distance / math.max(self.Config.TweenSpeed, 50)
        self.LastTweenTargetPos = targetPos
        self.CurrentTween = TweenService:Create(hrp, TweenInfo.new(tempo, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
        self.CurrentTween:Play()
        return true
    else
        if self.CurrentTween then self.CurrentTween:Cancel(); self.CurrentTween = nil end
        hrp.CFrame = targetCFrame
        hrp.Velocity = Vector3.zero
        return true
    end
end

function CombatService:EquipWeapon()
    local char = LP.Character
    local backpack = LP:FindFirstChild("Backpack")
    if not char or not backpack then return end

    if self.Config.SelectedWeapon == "Nenhuma" then
        for _, tool in ipairs(backpack:GetChildren()) do if tool:IsA("Tool") then tool.Parent = char break end end
    else
        local specificWeapon = backpack:FindFirstChild(self.Config.SelectedWeapon)
        if specificWeapon and specificWeapon:IsA("Tool") then specificWeapon.Parent = char end
    end
end

function CombatService:ExecuteAttack(targetInstance)
    self:EquipWeapon()
    local currentTime = tick()
    if currentTime - self.LastAttackTime < self.AttackCooldown then return end
    self.LastAttackTime = currentTime
    
    pcall(function()
        if self.Remotes.Combat then self.Remotes.Combat:FireServer() end
        if self.Remotes.Ability then for i = 1, 4 do self.Remotes.Ability:FireServer(i) end end
    end)
end

return CombatService
