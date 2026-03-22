-- =========================================================================
-- 🔄 LoopController
-- Orquestra a execução de todos os serviços do sistema.
-- Separa tarefas que precisam de reflexos rápidos (Combate) de tarefas
-- que podem pensar devagar (Busca de Alvos, Varredura de Mapa).
-- =========================================================================

local GameServices = require(script.Parent.Parent.core.GameServices)

local LoopController = {}
LoopController.__index = LoopController

function LoopController.new()
    local self = setmetatable({
        _isRunning = false,
        _fastTasks = {}, -- Tarefas executadas a cada frame (Músculos)
        _slowTasks = {}, -- Tarefas executadas a cada 1 segundo (Cérebro)
        _fastConnection = nil
    }, LoopController)
    return self
end

-- =========================================================================
-- REGISTRO DE TAREFAS
-- =========================================================================

-- Registra uma função para rodar no Loop Rápido (Ex: Ataques, Movimentação)
-- @param taskFunction (function): A função que será executada
function LoopController:RegisterFastTask(taskFunction)
    if type(taskFunction) == "function" then
        table.insert(self._fastTasks, taskFunction)
    else
        warn("[LoopController] Tentativa de registrar uma Fast Task inválida.")
    end
end

-- Registra uma função para rodar no Loop Lento (Ex: Escanear mapa, Atualizar UI)
-- @param taskFunction (function): A função que será executada
function LoopController:RegisterSlowTask(taskFunction)
    if type(taskFunction) == "function" then
        table.insert(self._slowTasks, taskFunction)
    else
        warn("[LoopController] Tentativa de registrar uma Slow Task inválida.")
    end
end

-- =========================================================================
-- CONTROLE DE EXECUÇÃO
-- =========================================================================

function LoopController:Start()
    if self._isRunning then return end
    self._isRunning = true
    print("🔄 LoopController: Iniciado.")

    -- ⚡ LOOP RÁPIDO (Heartbeat: ~60 vezes por segundo)
    self._fastConnection = GameServices.RunService.Heartbeat:Connect(function(deltaTime)
        if not self._isRunning then return end
        
        for _, taskFn in ipairs(self._fastTasks) do
            -- Usa task.spawn para evitar que o erro de um módulo trave os outros
            task.spawn(taskFn, deltaTime)
        end
    end)

    -- 🧠 LOOP LENTO (task.wait: 1 vez por segundo)
    task.spawn(function()
        while self._isRunning do
            task.wait(1)
            
            for _, taskFn in ipairs(self._slowTasks) do
                -- Novamente, task.spawn isola falhas e mantém a performance fluida
                task.spawn(taskFn)
            end
        end
    end)
end

function LoopController:Stop()
    if not self._isRunning then return end
    self._isRunning = false

    if self._fastConnection then
        self._fastConnection:Disconnect()
        self._fastConnection = nil
    end
    
    print("🛑 LoopController: Parado.")
end

-- Limpa todas as tarefas registradas (Útil ao fechar o script por completo)
function LoopController:Destroy()
    self:Stop()
    table.clear(self._fastTasks)
    table.clear(self._slowTasks)
end

return LoopController
