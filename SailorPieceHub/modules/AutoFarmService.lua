local AutoFarmService = {}
AutoFarmService.__index = AutoFarmService

function AutoFarmService.new(stateManager, targetService, combatService, teleportService)
    local self = setmetatable({
        _state = stateManager, _target = targetService,
        _combat = combatService, _teleport = teleportService,
        _isActive = false, _wasFarming = false
    }, AutoFarmService)
    return self
end

function AutoFarmService:Start() self._isActive = true; self._wasFarming = false end
function AutoFarmService:Stop() self._isActive = false; self._target:ClearTarget(); self._wasFarming = false end

function AutoFarmService:Update()
    if not self._isActive then return end
    if not self._state:Get("AutoFarm") then
        if self._wasFarming then
            self._target:ClearTarget(); self._combat:ResetMovement(); self._wasFarming = false
        end
        return
    end

    if self._teleport:IsBusy() then return end

    self._wasFarming = true
    local targetName = self._state:Get("SelectedMob") or "Nenhum"
    
    if targetName == "Nenhum" then return end

    local islandNeeded = self._teleport:GetIslandByMob(targetName)
    local currentIsland = self._teleport:GetCurrentIsland()

    if currentIsland and islandNeeded and currentIsland ~= islandNeeded then
        self._target:ClearTarget()
        self._combat:ResetMovement()
        self._teleport:SmartTeleport(islandNeeded, self._state:Get("TweenSpeed"))
        return
    end

    local currentTarget = self._target:FindNearestMob(targetName)

    if currentTarget then 
        local arrived = self._combat:MoveTo(currentTarget)
        if arrived then self._combat:Attack(currentTarget) end
    else 
        self._combat:ResetMovement() 
    end
end

return AutoFarmService
