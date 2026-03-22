-- Substitua apenas esta função dentro do seu CombatService.lua atual:

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
    else
        targetPos = targetInstance.Position
    end

    self:SetCharacterFrozen(true)
    local targetTargetPos = targetInstance:IsA("Model") and targetInstance:FindFirstChild("HumanoidRootPart") and targetInstance.HumanoidRootPart.Position or targetInstance.Position
    local targetCFrame = CFrame.new(targetPos, targetTargetPos)
    local distance = (hrp.Position - targetPos).Magnitude
    
    if distance > 1000 then return false end
    
    if distance > 15 then
        -- 🛡️ PROTEÇÃO ANTI-SPAM (Isso resolve o erro ProfilerDataParser)
        if self.CurrentTween and self.CurrentTween.PlaybackState == Enum.PlaybackState.Playing then
            -- Se o alvo se moveu muito, recalcula. Se não, apenas continua o voo.
            if self.LastTweenTargetPos and (self.LastTweenTargetPos - targetPos).Magnitude > 10 then
                self.CurrentTween:Cancel()
            else
                return false
            end
        end

        local tempo = distance / math.max(self.Config.TweenSpeed, 50)
        self.LastTweenTargetPos = targetPos
        self.CurrentTween = TweenService:Create(hrp, TweenInfo.new(tempo, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
        self.CurrentTween:Play()
        return false
    else
        -- Chegou perto: cancela o voo e ataca
        if self.CurrentTween then self.CurrentTween:Cancel(); self.CurrentTween = nil end
        hrp.CFrame = targetCFrame
        hrp.Velocity = Vector3.zero
        return true
    end
end
