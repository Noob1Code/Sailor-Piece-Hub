local StateManager = Import("core/StateManager")
local LoopController = Import("controllers/LoopController")
local TargetService = Import("modules/TargetService")
local CombatService = Import("modules/CombatService")
local AutoFarmService = Import("modules/AutoFarmService")
local BossService = Import("modules/BossService")
local TeleportService = Import("modules/TeleportService")

local UIController = Import("ui/UIController")
local UILibrary = Import("ui/UILibrary")

local MainController = {}
MainController.__index = MainController

function MainController.new()
    local self = setmetatable({}, MainController)
    print("⏳ MainController: Iniciando injeção de dependências...")

    self._stateManager = StateManager.new({
        AutoFarm = false, SelectedMob = "Nenhum", 
        AutoBoss = false, SelectedBosses = {}, SelectedSummonBoss = "Nenhum", AutoSummon = false,
        AttackPosition = "Atrás", Distance = 5, TweenSpeed = 150
    })

    self._loopController = LoopController.new()
    self._targetService = TargetService.new()
    self._combatService = CombatService.new(self._stateManager)
    
    local TeleportService = Import("modules/TeleportService")
    self._teleportService = TeleportService.new()
    
    self._autoFarmService = AutoFarmService.new(self._stateManager, self._targetService, self._combatService, self._teleportService)
    self._bossService = BossService.new(self._stateManager, self._targetService, self._combatService, self._teleportService) 

    self._uiController = UIController.new(self._stateManager)

    return self
end

function MainController:Init()
    print("🚀 MainController: Conectando módulos e iniciando o sistema...")
    
    self._autoFarmService:Start()
    self._bossService:Start()

    self._loopController:RegisterFastTask(function(deltaTime)
        self._autoFarmService:Update()
        self._bossService:FastUpdate()
    end)

    self._loopController:RegisterSlowTask(function()
        self._bossService:SlowUpdate()
    end)

    self._loopController:Start()
    self._uiController:Build(UILibrary)

    print("✅ Hub Carregado com Sucesso! Arquitetura Modular Ativa.")
end

function MainController:Destroy()
    print("🛑 MainController: Desligando sistema...")
    self._loopController:Destroy()
    self._autoFarmService:Stop()
    self._bossService:Stop()
    self._stateManager:Destroy()
    self._uiController:Destroy()
end

return MainController
