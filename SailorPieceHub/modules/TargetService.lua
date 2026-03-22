-- =========================================================================
-- 🎯 TargetService
-- =========================================================================

local GameServices = Import("core/GameServices")

local TargetService = {}
TargetService.__index = TargetService

function TargetService.new()
    local self = setmetatable({ _currentTarget = nil }, TargetService)
    return self
end

function TargetService:_isValid(target)
    if not target or not target.Parent then return false end
    local hum = target:FindFirstChild("Humanoid")
    local hrp = target:FindFirstChild("HumanoidRootPart")
    return (hum and hrp and hum.Health > 0)
end

function TargetService:GetTarget()
    if self:_isValid(self._currentTarget) then return self._currentTarget else self._currentTarget = nil return nil end
end

function TargetService:SetTarget(target)
    if self:_isValid(target) then self._currentTarget = target end
end

function TargetService:ClearTarget()
    self._currentTarget = nil
end

function TargetService:_getMyPosition()
    local char = GameServices.LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    return hrp and hrp.Position or Vector3.zero
end

function TargetService:FindNearestMob(mobName)
    if self:GetTarget() then
        local currentNameBase = self._currentTarget.Name:gsub("%d+", "")
        if mobName == "Todos" or currentNameBase == mobName then return self._currentTarget end
    end

    local npcsFolder = GameServices.Workspace:FindFirstChild("NPCs")
    if not npcsFolder then return nil end

    local myPos = self:_getMyPosition()
    local closestMob = nil
    local minDist = math.huge

    for _, npc in pairs(npcsFolder:GetChildren()) do
        if self:_isValid(npc) and not npc:GetAttribute("IsTrainingDummy") then
            local isBoss = npc.Name:lower():find("boss") or npc:GetAttribute("Boss")
            if not isBoss then
                local baseName = npc.Name:gsub("%d+", "")
                if mobName == "Todos" or baseName == mobName then
                    local dist = (myPos - npc.HumanoidRootPart.Position).Magnitude
                    if dist < minDist then minDist = dist; closestMob = npc end
                end
            end
        end
    end

    self._currentTarget = closestMob
    return closestMob
end

function TargetService:FindNearestBoss(bossName)
    if not bossName or bossName == "Nenhum" then return nil end
    if self:GetTarget() and self._currentTarget.Name:find(bossName) then return self._currentTarget end

    local myPos = self:_getMyPosition()
    local closestBoss = nil
    local minDist = math.huge

    for _, obj in pairs(GameServices.Workspace:GetChildren()) do
        if obj.Name:find("BossSpawn_") or obj.Name:find("TimedBoss") or obj.Name == "NPCs" then
            for _, boss in pairs(obj:GetChildren()) do
                if self:_isValid(boss) then
                    local isRecognizedBoss = boss:GetAttribute("Boss") or boss:GetAttribute("_IsTimedBoss") or boss.Name:lower():find("boss")
                    if isRecognizedBoss and boss.Name:find(bossName) then
                        local dist = (myPos - boss.HumanoidRootPart.Position).Magnitude
                        if dist < minDist then minDist = dist; closestBoss = boss end
                    end
                end
            end
        end
    end

    self._currentTarget = closestBoss
    return closestBoss
end

return TargetService
