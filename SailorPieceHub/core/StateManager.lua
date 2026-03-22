-- =========================================================================
-- 🗄️ StateManager (Single Source of Truth)
-- =========================================================================

local Signal = Import("core/Signal")

local StateManager = {}
StateManager.__index = StateManager

function StateManager.new(defaultState)
    local self = setmetatable({}, StateManager)
    self._state = defaultState or {}
    self._signals = {}
    return self
end

function StateManager:_getSignal(key)
    if not self._signals[key] then self._signals[key] = Signal.new() end
    return self._signals[key]
end

function StateManager:Get(key)
    return self._state[key]
end

function StateManager:Set(key, value)
    local oldValue = self._state[key]
    if oldValue ~= value then
        self._state[key] = value
        self:_getSignal(key):Fire(value, oldValue)
    end
end

function StateManager:Toggle(key)
    local currentValue = self._state[key]
    if type(currentValue) == "boolean" then
        self:Set(key, not currentValue)
    elseif currentValue == nil then
        self:Set(key, true)
    else
        warn("[StateManager] Tentativa de usar Toggle em não-booleano: " .. tostring(key))
    end
end

function StateManager:OnChanged(key, callback)
    return self:_getSignal(key):Connect(callback)
end

function StateManager:Destroy()
    for _, signal in pairs(self._signals) do signal:Destroy() end
    table.clear(self._signals)
    table.clear(self._state)
end

return StateManager
