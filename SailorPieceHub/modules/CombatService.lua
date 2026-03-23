local GameServices = Import("core/GameServices")
local Remotes = Import("core/Remotes")
local TweenUtil = Import("utils/TweenUtil")

local CombatService = {}
CombatService.__index = CombatService

function CombatService.new(stateManager)
    local self = setmetatable({
        _state = stateManager, _orbitAngle = 0, _currentTween = nil
    }, CombatService)
    return self
end

function CombatService:_freezeCharacter(char)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if hrp and hum then hrp.Velocity = Vector3.zero; hum.PlatformStand = true end
end

function CombatService:ResetMovement()
    local char = GameServices.LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.PlatformStand = false end
    end
    if self._currentTween then 
        self._currentTween:Cancel()
        self._currentTween = nil 
    end
end

function CombatService:_equipWeapon()
    local char = GameServices.LocalPlayer.Character
    local backpack = GameServices.LocalPlayer:FindFirstChild("Backpack")
    local selectedWeapon = self._state:Get("SelectedWeapon")

    if not char or not backpack then return end

    if selectedWeapon == "Nenhuma" or not selectedWeapon then
        for _, tool in pairs(backpack:GetChildren()) do 
            if tool:IsA("Tool") then tool.Parent = char; break end 
        end
    else
        local specificWeapon = backpack:FindFirstChild(selectedWeapon)
        if specificWeapon and specificWeapon:IsA("Tool") then specificWeapon.Parent = char end
    end
end

function CombatService:Attack(target)
    if not target or not target:FindFirstChild("Humanoid") then return false end
    if target.Humanoid.Health <= 0 then return false end

    local char = GameServices.LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local targetHrp = target:FindFirstChild("HumanoidRootPart")
    
    if hrp and targetHrp then
        if (hrp.Position - targetHrp.Position).Magnitude > 80 then return false end
    end

    self:_equipWeapon()
    if Remotes.CombatRemote then Remotes.CombatRemote:FireServer() end
    if Remotes.AbilityRemote then for i = 1, 4 do Remotes.AbilityRemote:FireServer(i) end end
    return true
end

function CombatService:OrbitTarget(target, distance)
    local char = GameServices.LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = char.HumanoidRootPart
    local targetHrp = target:FindFirstChild("HumanoidRootPart")
    if not targetHrp then return end

    self:_freezeCharacter(char)
    self._orbitAngle = self._orbitAngle + math.rad(15)
    local pos = targetHrp.Position + Vector3.new(math.cos(self._orbitAngle) * distance, 5, math.sin(self._orbitAngle) * distance)
    hrp.CFrame = CFrame.new(pos, targetHrp.Position)
    hrp.Velocity = Vector3.zero
end

function CombatService:MoveTo(target)
    local char = GameServices.LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
    
    local hrp = char.HumanoidRootPart
    local targetHrp = target:FindFirstChild("HumanoidRootPart")
    if not targetHrp then return false end

    local distance = self._state:Get("Distance") or 5
    local tweenSpeed = self._state:Get("TweenSpeed") or 150
    local attackPos = self._state:Get("AttackPosition") or "Atrás"

    if attackPos == "Orbital" then self:OrbitTarget(target, distance); return true end
    self:_freezeCharacter(char)

    local forcedSafe = target:GetAttribute("Damage") and target:GetAttribute("Damage") > 100000
    if forcedSafe and attackPos == "Abaixo" then attackPos = "Acima" end

    local pos
    if attackPos == "Atrás" then pos = targetHrp.Position - (targetHrp.CFrame.LookVector * distance)
    elseif attackPos == "Abaixo" then pos = targetHrp.Position + Vector3.new(0, -distance, 0)
    else pos = targetHrp.Position + Vector3.new(0, distance, 0) end

    local targetCFrame = CFrame.new(pos, targetHrp.Position)
    local distToPos = (hrp.Position - pos).Magnitude

    if distToPos > 3000 then 
        self:ResetMovement()
        hrp.CFrame = targetCFrame
        hrp.Velocity = Vector3.zero
        return true 
    end

    if distToPos <= 60 then
        self:ResetMovement()
        hrp.CFrame = targetCFrame
        hrp.Velocity = Vector3.zero
    else
        if not self._currentTween then
            self._currentTween = TweenUtil.MoveToPosition(char, pos, tweenSpeed)
            if self._currentTween then
                self._currentTween.Completed:Connect(function() 
                    self._currentTween = nil 
                end)
            end
        end
    end
    return true
end

return CombatService
