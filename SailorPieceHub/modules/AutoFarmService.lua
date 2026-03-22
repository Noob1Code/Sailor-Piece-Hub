-- =========================================================================
-- 🚜 AutoFarmService
-- Gerencia a lógica de negócio do farm de Mobs.
-- Não possui loops internos; é ativado a cada frame/tick pelo LoopController.
-- =========================================================================

local AutoFarmService = {}
AutoFarmService.__index = AutoFarmService

-- Injeção de dependências: Recebe os serviços necessários para operar
function AutoFarmService.new(stateManager, targetService, combatService)
    local self = setmetatable({
        _state = stateManager,
        _target = targetService,
        _combat = combatService,
        _isActive = false,  -- Controle interno de estado
        _wasFarming = false -- Guarda o estado anterior para saber quando limpamos as variáveis
    }, AutoFarmService)
    
    return self
end

-- =========================================================================
-- MÉTODOS DE CONTROLE
-- =========================================================================

-- Inicia o serviço explicitamente (Pode ser usado para resetar variáveis)
function AutoFarmService:Start()
    self._isActive = true
    self._wasFarming = false
    print("🚜 AutoFarmService: Pronto para receber Updates.")
end

-- Para o serviço explicitamente e limpa o alvo
function AutoFarmService:Stop()
    self._isActive = false
    self._target:ClearTarget()
    self._wasFarming = false
    print("🛑 AutoFarmService: Parado e alvo limpo.")
end

-- =========================================================================
-- LOOP LÓGICO (Chamado pelo LoopController)
-- =========================================================================

-- Função principal de atualização. Deve ser chamada repetidamente.
function AutoFarmService:Update()
    if not self._isActive then return end

    -- 1. Verifica no StateManager se o jogador ativou a chave "AutoFarm"
    local isAutoFarmOn = self._state:Get("AutoFarm")

    -- 2. Tratamento de desligamento: Limpa o alvo caso o jogador acabe de desligar o farm
    if not isAutoFarmOn then
        if self._wasFarming then
            self._target:ClearTarget()
            self._wasFarming = false
        end
        return -- Sai da função cedo para economizar processamento
    end

    self._wasFarming = true

    -- 3. Regra de Negócio: Buscar Alvo
    -- Tenta pegar o alvo atual do cache. Se não houver, procura um novo.
    local currentTarget = self._target:GetTarget()
    
    if not currentTarget then
        local targetName = self._state:Get("SelectedMob") or "Nenhum"
        
        if targetName ~= "Nenhum" then
            currentTarget = self._target:FindNearestMob(targetName)
        end
    end

    -- 4. Regra de Negócio: Atacar Alvo
    if currentTarget then
        -- MoveTo cuida da aproximação e do tweening
        self._combat:MoveTo(currentTarget)
        -- Attack cuida do spam de remotes
        self._combat:Attack(currentTarget)
    end
end

return AutoFarmService
