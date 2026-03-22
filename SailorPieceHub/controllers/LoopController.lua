-- =========================================================================
-- 🔄 LoopController
-- =========================================================================

local GameServices = Import("core/GameServices")

local LoopController = {}
LoopController.__index = LoopController

function LoopController.new()
    local self = setmetatable({
        _isRunning = false,
        _fastTasks = {},
        _slowTasks = {},
        _fastConnection = nil
    }, LoopController)
    return self
end

function LoopController:RegisterFastTask(taskFunction)
    if type(taskFunction) == "function" then table.insert(self._fastTasks, taskFunction) end
end

function LoopController:RegisterSlowTask(taskFunction)
    if type(taskFunction) == "function" then table.insert(self._slowTasks, taskFunction) end
end

function LoopController:Start()
    if self._isRunning then return end
    self._isRunning = true
    print("🔄 LoopController: Iniciado.")

    self._fastConnection = GameServices.RunService.Heartbeat:Connect(function(deltaTime)
        if not self._isRunning then return end
        for _, taskFn in ipairs(self._fastTasks) do task.spawn(taskFn, deltaTime) end
    end)

    task.spawn(function()
        while self._isRunning do
            task.wait(1)
            for _, taskFn in ipairs(self._slowTasks) do task.spawn(taskFn) end
        end
    end)
end

function LoopController:Stop()
    if not self._isRunning then return end
    self._isRunning = false
    if self._fastConnection then self._fastConnection:Disconnect(); self._fastConnection = nil end
    print("🛑 LoopController: Parado.")
end

function LoopController:Destroy()
    self:Stop()
    table.clear(self._fastTasks)
    table.clear(self._slowTasks)
end

return LoopController
