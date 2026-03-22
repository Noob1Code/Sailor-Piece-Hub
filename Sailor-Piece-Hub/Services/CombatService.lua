-- =====================================================================
-- ⚔️ SERVICES: CombatService.lua
-- Responsabilidade: Isolar a movimentação (Tween/TP) e Remotes do jogo.
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
    self:LoadRemotes()
    return self
end

function CombatService:LoadRemotes()
    self.Remotes = {}
    pcall(function()
        self.Remotes.Combat = ReplicatedStorage:WaitForChild("CombatSystem"):WaitForChild("Remotes"):WaitForChild("RequestHit")
        self.Remotes.Ability = ReplicatedStorage:WaitForChild("AbilitySystem"):WaitForChild("Remotes"):WaitForChild("RequestAbility")
        self.Remotes.Teleport = ReplicatedStorage:FindFirstChild("TeleportToPortal", true)
        self.Remotes.AllocateStat = ReplicatedStorage:FindFirstChild("AllocateStat", true)
        self.Remotes.ResetStats = ReplicatedStorage:FindFirstChild("ResetStats", true)
        self.Remotes.UseItem = ReplicatedStorage:FindFirstChild("UseItem", true)
        self.Remotes.TraitReroll = ReplicatedStorage:FindFirstChild("TraitReroll", true)
        self.Remotes.RerollSingleStat = ReplicatedStorage:FindFirstChild("RerollSingleStat", true)
        self.Remotes.HakiArmamento = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("HakiRemote")
        self.Remotes.HakiObservacao = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ObservationHakiRemote")
        self.Remotes.SummonBoss = ReplicatedStorage:FindFirstChild("RequestSummonBoss", true) or ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RequestSummonBoss")
    end)
end

function CombatService:SetCharacterFrozen(isFrozen)
    local char = LP.Character; if not char then return end
    local hum = char:FindFirstChild("Humanoid"); local hrp = char:FindFirstChild("HumanoidRootPart")
    if hum and hrp then if isFrozen then hrp.Velocity = Vector3.zero; hum.PlatformStand = true else hum.PlatformStand = false end end
end

-- ==========================================
-- 🌍 SISTEMA DE TELEPORTE INTELIGENTE
-- ==========================================
function CombatService:SmartIslandTeleport(islandName)
    if not islandName or islandName == "Eventos (Timed Bosses)" then return false end
    if tick() - self.LastTeleportTime < 3 then return false end 
    
    local dest = self.Constants.TeleportMap[islandName] or islandName
    if self.Remotes.Teleport then
        local char = LP.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local oldPos = hrp and hrp.Position or Vector3.zero

        if self.CurrentTween then self.CurrentTween:Cancel(); self.CurrentTween = nil end
        self:SetCharacterFrozen(false)
        
        self.Remotes.Teleport:FireServer(dest)
        self.LastTeleportTime = tick()

        if hrp then
            for i = 1, 15 do task.wait(0.5) if (hrp.Position - oldPos).Magnitude > 200 then break end end
        else task.wait(3) end
        
        task.wait(1.5)
        self:AutoSaveSpawn() 
        return true
    end
    return false
end

function CombatService:AutoSaveSpawn()
    pcall(function()
        local char = LP.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
        local hrp = char.HumanoidRootPart; local closestPrompt, targetPart = nil, nil
        
        for attempt = 1, 8 do
            local myPos = hrp.Position; local minDist = math.huge
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("ProximityPrompt") then
                    local actText = string.lower(obj.ActionText or ""); local objName = string.lower(obj.Name or "")
                    if objName == "checkpointprompt" or actText:find("set spawn") or actText:find("checkpoint") then
                        local part = obj.Parent
                        if part and part:IsA("BasePart") then
                            local dist = (part.Position - myPos).Magnitude
                            if dist < 800 and dist < minDist then minDist = dist; closestPrompt = obj; targetPart = part end
                        end
                    end
                end
            end
            if closestPrompt then break end; task.wait(0.5)
        end

        if closestPrompt and targetPart then
            local dist = (hrp.Position - targetPart.Position).Magnitude
            if dist > 10 then
                local tempo = math.max(0.1, dist / math.max(self.Config.TweenSpeed, 150))
                local tween = TweenService:Create(hrp, TweenInfo.new(tempo, Enum.EasingStyle.Linear), {CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)})
                tween:Play(); tween.Completed:Wait(); task.wait(0.5)
            else hrp.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0); task.wait(0.5) end
            
            -- FIX do ProximityPrompt do Roblox: Envolvido num pcall para evitar crash do CoreScript
            pcall(function()
                if closestPrompt and closestPrompt:IsA("ProximityPrompt") and closestPrompt.Enabled and fireproximityprompt then 
                    fireproximityprompt(closestPrompt); task.wait(0.2); fireproximityprompt(closestPrompt)
                end
            end)
            task.wait(0.5)
            return true 
        end
    end)
    return false
end

-- ==========================================
-- 🏃 MOVIMENTAÇÃO (TWEEN OTIZIMADO PARA EVITAR LAG)
-- ==========================================
function CombatService:MoveToTarget(targetInstance, customDistance)
    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
    
    local hrp = char.HumanoidRootPart
    local targetPos, targetTargetPos
    
    -- RESOLUÇÃO DO ERRO MODEL: Previne ler '.Position' sem BasePart válido.
    if targetInstance:IsA("Model") then
        local targetHrp = targetInstance.PrimaryPart or targetInstance:FindFirstChild("HumanoidRootPart") or targetInstance:FindFirstChildWhichIsA("BasePart", true)
        if not targetHrp then return false end
        
        targetPos = targetHrp.Position
        targetTargetPos = targetHrp.Position
        
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
        targetTargetPos = targetInstance.Position
    else return false end

    self:SetCharacterFrozen(true)
    local targetCFrame = CFrame.new(targetPos, targetTargetPos)
    local distance = (hrp.Position - targetPos).Magnitude
    
    if distance > 1000 then 
        self:SetCharacterFrozen(false)
        if self.CurrentTween then self.CurrentTween:Cancel(); self.CurrentTween = nil end
        return false 
    end
    
    if distance > 15 then
        -- Não recria o Tween de forma compulsiva para não lagar o Profiler do Roblox
        if self.CurrentTween and self.CurrentTween.PlaybackState == Enum.PlaybackState.Playing then
            if self.LastTweenTargetPos and (self.LastTweenTargetPos - targetPos).Magnitude > 5 then
                self.CurrentTween:Cancel()
            else return false end
        end

        local tempo = math.max(0.1, distance / math.max(self.Config.TweenSpeed, 150))
        self.LastTweenTargetPos = targetPos
        self.CurrentTween = TweenService:Create(hrp, TweenInfo.new(tempo, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
        self.CurrentTween:Play()
        return false
    else
        if self.CurrentTween then self.CurrentTween:Cancel(); self.CurrentTween = nil end
        hrp.CFrame = targetCFrame
        hrp.Velocity = Vector3.zero
        return true
    end
end

function CombatService:EquipWeapon()
    local char = LP.Character; local backpack = LP:FindFirstChild("Backpack")
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
