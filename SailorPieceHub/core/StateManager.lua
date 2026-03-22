-- =========================================================================
-- 🗄️ StateManager (Single Source of Truth)
-- Armazena de forma segura todas as configurações, toggles e escolhas do usuário.
-- Substitui completamente o antigo getgenv().HubConfig.
-- =========================================================================

local Signal = require(script.Parent.Signal)

local StateManager = {}
StateManager.__index = StateManager

-- Construtor da classe
-- @param defaultState (table): Tabela opcional com os valores iniciais
function StateManager.new(defaultState)
    local self = setmetatable({}, StateManager)
    
    self._state = defaultState or {} -- Tabela privada de estados
    self._signals = {}               -- Tabela privada de sinais (eventos) por chave
    
    return self
end

-- Método interno e privado para obter ou criar um sinal para uma chave específica
function StateManager:_getSignal(key)
    if not self._signals[key] then
        self._signals[key] = Signal.new()
    end
    return self._signals[key]
end

-- Retorna o valor atual de uma chave
-- @param key (string): O nome da configuração (ex: "AutoFarm")
function StateManager:Get(key)
    return self._state[key]
end

-- Atualiza o valor de uma chave e dispara o evento SOMENTE se o valor mudar
-- @param key (string): O nome da configuração
-- @param value (any): O novo valor
function StateManager:Set(key, value)
    local oldValue = self._state[key]
    
    if oldValue ~= value then
        self._state[key] = value
        -- Dispara o evento passando o novo valor e o valor antigo
        self:_getSignal(key):Fire(value, oldValue)
    end
end

-- Inverte o valor de uma chave booleana (útil para Toggles da UI)
-- @param key (string): O nome da configuração
function StateManager:Toggle(key)
    local currentValue = self._state[key]
    
    if type(currentValue) == "boolean" then
        self:Set(key, not currentValue)
    elseif currentValue == nil then
        -- Se não existir, assume false e inverte para true
        self:Set(key, true)
    else
        warn("[StateManager] Tentativa de usar Toggle em uma chave não-booleana: " .. tostring(key))
    end
end

-- Registra um ouvinte para escutar mudanças em uma chave específica
-- @param key (string): A chave a ser observada
-- @param callback (function): Função chamada quando o valor mudar
-- @return table: O objeto de conexão (para poder dar Disconnect depois)
function StateManager:OnChanged(key, callback)
    return self:_getSignal(key):Connect(callback)
end

-- Limpa todos os eventos para evitar memory leaks ao fechar o script
function StateManager:Destroy()
    for _, signal in pairs(self._signals) do
        signal:Destroy()
    end
    table.clear(self._signals)
    table.clear(self._state)
end

return StateManager
