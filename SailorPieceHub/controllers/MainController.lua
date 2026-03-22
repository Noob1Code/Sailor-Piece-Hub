-- =========================================================================
-- 🧠 MainController
-- O coração da orquestração. Instancia todos os serviços, resolve as 
-- dependências (Dependency Injection) e pluga tudo no LoopController.
-- Nenhuma lógica de gameplay deve existir aqui.
-- =========================================================================

-- Importando o Core (Estado)
local StateManager = require(script.Parent.Parent.core.StateManager)

-- Importando os Controladores
local LoopController = require(script.Parent.LoopController)
-- local UIController = require(script.Parent.Parent.ui.UIController) -- Será adicionado depois

-- Importando os Módulos Lógicos (Serviços)
local TargetService = require(script.Parent.Parent.modules.TargetService)
local CombatService = require(script.Parent.Parent.modules.CombatService)
local AutoFarmService = require(script.Parent.Parent.modules.AutoFarmService)

local MainController = {}
MainController.__index = MainController

-- Construtor: Cria todas as instâncias e injeta as dependências
function MainController.new()
    local self = setmetatable({}, MainController)
    
    print("⏳ MainController: Iniciando injeção de dependências...")

    -- 1. Cria a Fonte Única de Verdade (Estado)
    self._stateManager = StateManager.new({
        AutoFarm = false,
        SelectedMob = "Nenhum",
        AttackPosition = "Atrás",
        Distance = 5,
        TweenSpeed = 150
    })

    -- 2. Cria o Gerenciador de Loops
    self._loopController = LoopController.new()

    -- 3. Instancia os Serviços Base (Sem dependências ou dependendo apenas do Estado)
    self._targetService = TargetService.new()
    self._combatService = CombatService.new(self._stateManager)

    -- 4. Instancia os Serviços de Regra de Negócio (Injetando Base + Estado)
    self._autoFarmService = AutoFarmService.new(
        self._stateManager, 
        self._targetService, 
        self._combatService
    )

    -- 5. (Futuro) Instanciar a UI injetando o MainController ou StateManager
    -- self._uiController = UIController.new(self._stateManager)

    return self
end

-- =========================================================================
-- ORQUESTRAÇÃO E INICIALIZAÇÃO
-- =========================================================================

-- Conecta os módulos aos loops e dá a partida no sistema
function MainController:Init()
    print("🚀 MainController: Conectando módulos e iniciando o sistema...")

    -- Prepara os serviços para rodar
    self._autoFarmService:Start()

    -- Registra o AutoFarm no Loop Rápido (Executado a cada frame para combate fluido)
    self._loopController:RegisterFastTask(function(deltaTime)
        self._autoFarmService:Update()
    end)

    -- Exemplo: Registrar varreduras de mapa no Loop Lento (Executado a cada 1s)
    -- self._loopController:RegisterSlowTask(function()
    --     self._worldService:ScanMap()
    -- end)

    -- Inicia os motores
    self._loopController:Start()
    
    -- (Futuro) Renderiza a interface
    -- self._uiController:BuildAndShow()

    print("✅ Hub Carregado com Sucesso! Arquitetura Modular Ativa.")
end

-- Encerra todo o sistema graciosamente (Clean up)
function MainController:Destroy()
    print("🛑 MainController: Desligando sistema...")
    
    -- Para os loops
    self._loopController:Destroy()
    
    -- Para os serviços
    self._autoFarmService:Stop()
    
    -- Limpa o estado e os eventos
    self._stateManager:Destroy()
    
    -- (Futuro) Destrói a UI
    -- self._uiController:Destroy()
end

return MainController
