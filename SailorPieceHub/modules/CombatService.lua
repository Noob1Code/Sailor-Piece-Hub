local GameServices = Import("core/GameServices")
local Remotes = Import("core/Remotes")

local CombatService = {}
CombatService.__index = CombatService

function CombatService.new(stateManager)
    local self = setmetatable({
        _state = stateManager, _orbitAngle = 0
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

    self:_equipWeapon()
    
    pcall(function()
        if Remotes.CombatRemote then Remotes.CombatRemote:FireServer() end
        if Remotes.AbilityRemote then for i = 1, 4 do Remotes.AbilityRemote:FireServer(i) end end
    end)
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

    local distanceConfig = self._state:Get("Distance") or 5
    local tweenSpeed = self._state:Get("TweenSpeed") or 150
    local attackPos = self._state:Get("AttackPosition") or "Atrás"

    self:_freezeCharacter(char)

    local forcedSafe = target:GetAttribute("Damage") and target:GetAttribute("Damage") > 100000
    if forcedSafe and attackPos == "Abaixo" then attackPos = "Acima" end

    local pos
    if attackPos == "Orbital" then 
        self:OrbitTarget(target, distanceConfig)
        return true
    elseif attackPos == "Atrás" then 
        pos = targetHrp.Position - (targetHrp.CFrame.LookVector * distanceConfig)
    elseif attackPos == "Abaixo" then 
        pos = targetHrp.Position + Vector3.new(0, -distanceConfig, 0)
    else 
        pos = targetHrp.Position + Vector3.new(0, distanceConfig, 0) 
    end

    local targetCFrame = CFrame.new(pos, targetHrp.Position)
    local distance = (hrp.Position - pos).Magnitude

    if distance > 1000 then 
        return false 
    elseif distance > 15 then
        local tempo = distance / tweenSpeed
        if tempo < 0.1 then tempo = 0.1 end
        GameServices.TweenService:Create(hrp, TweenInfo.new(tempo, Enum.EasingStyle.Linear), {CFrame = targetCFrame}):Play()
    else
        hrp.CFrame = targetCFrame
        hrp.Velocity = Vector3.zero
    end

    return true
end

return CombatService
