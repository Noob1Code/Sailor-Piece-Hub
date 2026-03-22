-- =========================================================================
-- 📡 Signal (Observer Pattern)
-- Responsável por gerenciar eventos customizados de forma leve e segura.
-- Evita memory leaks e bugs de mutação durante a execução.
-- =========================================================================

local Signal = {}
Signal.__index = Signal

-- Construtor da classe
function Signal.new()
    local self = setmetatable({}, Signal)
    self._listeners = {} -- Array para armazenar as funções conectadas
    return self
end

-- Conecta uma função ao sinal
-- @param fn: Função a ser executada quando o sinal for disparado
-- @return table: Objeto de conexão com método Disconnect()
function Signal:Connect(fn)
    if type(fn) ~= "function" then
        error("Signal:Connect requer uma função como argumento.", 2)
    end

    table.insert(self._listeners, fn)

    -- Retorna um objeto no padrão Roblox (Connection) para facilitar o uso
    local connection = {}
    local disconnected = false

    function connection:Disconnect()
        if disconnected then return end
        disconnected = true
        self._signal:Disconnect(fn)
    end
    
    -- Injetamos a referência do sinal no objeto de conexão
    connection._signal = self 

    return connection
end

-- Desconecta uma função específica do sinal manualmente
-- @param fn: Função que foi conectada anteriormente
function Signal:Disconnect(fn)
    for i, listener in ipairs(self._listeners) do
        if listener == fn then
            table.remove(self._listeners, i)
            break
        end
    end
end

-- Dispara o sinal, invocando todos os ouvintes
-- @param ...: Argumentos variáveis que serão passados para as funções
function Signal:Fire(...)
    -- Clonamos a tabela de listeners antes de iterar.
    -- Isso previne bugs críticos caso um listener se desconecte 
    -- ou conecte outro listener durante o loop de execução.
    local listenersCopy = {}
    for i, listener in ipairs(self._listeners) do
        listenersCopy[i] = listener
    end

    for _, listener in ipairs(listenersCopy) do
        -- Usamos task.spawn (nativo do Roblox) para rodar cada função 
        -- em uma thread separada. Isso garante que se um listener der erro, 
        -- ele não quebra a execução dos outros listeners ou do código principal.
        task.spawn(listener, ...)
    end
end

-- Limpa todos os listeners (Prevenção de Memory Leak)
-- Deve ser chamado quando a classe que possui o sinal for destruída
function Signal:Destroy()
    table.clear(self._listeners)
end

return Signal
