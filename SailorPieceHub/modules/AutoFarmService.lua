local AutoFarmService = {}
AutoFarmService.__index = AutoFarmService

function AutoFarmService.new(stateManager, targetService, combatService, teleportService)
    local self = setmetatable({
        _state = stateManager,
        _target = targetService,
        _combat = combatService,
        _teleport = teleportService,
        _isActive = false,
        _wasFarming = false
    }, AutoFarmService)
    return self
end

function AutoFarmService:Start()
    self._isActive = true
    self._wasFarming = false
end

function AutoFarmService:Stop()
    self._isActive = false
    self._target:ClearTarget()
    self._wasFarming = false
end

function AutoFarmService:Update()
    if not self._isActive then return end

    local isAutoFarmOn = self._state:Get("AutoFarm")

    if not isAutoFarmOn then
        if self._wasFarming then
            self._target:ClearTarget()
            self._combat:ResetMovement()
            self._wasFarming = false
        end
        return
    end

    self._wasFarming = true
    local currentTarget = self._target:GetTarget()
    local targetName = self._state:Get("SelectedMob") or "Nenhum"
    
    if not currentTarget and targetName ~= "Nenhum" then
        currentTarget = self._target:FindNearestMob(targetName)
        if not currentTarget then
            local islandNeeded = self._teleport:GetIslandByMob(targetName)
            if islandNeeded then
                self._teleport:TeleportToIsland(islandNeeded)
                self._teleport:SaveSpawn()
            end
        end
    end

    if currentTarget then
        self._combat:MoveTo(currentTarget)
        self._combat:Attack(currentTarget)
    else
        self._combat:ResetMovement()
    end
end

return AutoFarmService
