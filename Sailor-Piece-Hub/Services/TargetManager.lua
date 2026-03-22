-- =====================================================================
-- 🎯 SERVICES: TargetManager.lua
-- Responsabilidade: Manter referência limpa dos alvos na memória.
-- =====================================================================
local TargetManager = {}
TargetManager.__index = TargetManager

function TargetManager.new()
    local self = setmetatable({}, TargetManager)
    self.CurrentTarget = nil
    self.InteractionTarget = nil 
    self._targetConnection = nil
    self._interactionConnection = nil
    return self
end

function TargetManager:SetTarget(targetInstance)
    if self._targetConnection then self._targetConnection:Disconnect(); self._targetConnection = nil end
    self.CurrentTarget = targetInstance
    if targetInstance then
        self._targetConnection = targetInstance.AncestryChanged:Connect(function(_, newParent)
            if not newParent then self:ClearTarget() end
        end)
    end
end

function TargetManager:GetTarget()
    local target = self.CurrentTarget
    if target and target:FindFirstChild("Humanoid") and target.Humanoid.Health > 0 then return target end
    if target then self:ClearTarget() end
    return nil
end

function TargetManager:ClearTarget()
    self.CurrentTarget = nil
    if self._targetConnection then self._targetConnection:Disconnect(); self._targetConnection = nil end
end

function TargetManager:SetInteractionTarget(npcInstance)
    if self._interactionConnection then self._interactionConnection:Disconnect(); self._interactionConnection = nil end
    self.InteractionTarget = npcInstance
    if npcInstance then
        self._interactionConnection = npcInstance.AncestryChanged:Connect(function(_, newParent)
            if not newParent then self:ClearInteractionTarget() end
        end)
    end
end

function TargetManager:GetInteractionTarget() return self.InteractionTarget end

function TargetManager:ClearInteractionTarget()
    self.InteractionTarget = nil
    if self._interactionConnection then self._interactionConnection:Disconnect(); self._interactionConnection = nil end
end

function TargetManager:Destroy()
    self:ClearTarget()
    self:ClearInteractionTarget()
end

return TargetManager
