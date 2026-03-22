local AutoFarmService = {}
AutoFarmService.__index = AutoFarmService

function AutoFarmService.new(stateManager, targetService, combatService)
    local self = setmetatable({
        _state = stateManager,
        _target = targetService,
        _combat = combatService,
        _isActive = false,
        _wasFarming = false
    }, AutoFarmService)
    
    return self
end

function AutoFarmService:Start()
    self._isActive = true
    self._wasFarming = false
    print("🚜 AutoFarmService: Pronto para receber Updates.")
end

function AutoFarmService:Stop()
    self._isActive = false
    self._target:ClearTarget()
    self._wasFarming = false
    print("🛑 AutoFarmService: Parado e alvo limpo.")
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
    
    if not currentTarget then
        local targetName = self._state:Get("SelectedMob") or "Nenhum"
        if targetName ~= "Nenhum" then
            currentTarget = self._target:FindNearestMob(targetName)
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
