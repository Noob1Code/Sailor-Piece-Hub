-- =========================================================================
-- 🖥️ UIController
-- Gerencia a criação da interface e conecta as ações do usuário ao StateManager.
-- Nenhuma lógica de jogo existe aqui. É puramente visual e reativo.
-- =========================================================================

local UIController = {}
UIController.__index = UIController

-- Construtor: Recebe o StateManager via injeção de dependência
function UIController.new(stateManager)
    local self = setmetatable({
        _state = stateManager,
        _window = nil -- Referência para a janela principal da UI
    }, UIController)
    return self
end

-- =========================================================================
-- CONSTRUÇÃO DA INTERFACE
-- =========================================================================

-- Constrói a UI usando uma biblioteca genérica injetada pelo MainController
-- @param uiLibrary: A biblioteca de interface (Ex: Rayfield, sua lib custom, etc)
function UIController:Build(uiLibrary)
    print("🖥️ UIController: Construindo a interface gráfica...")

    -- Inicializa a janela principal
    self._window = uiLibrary.new("Comunidade Hub V22.2 (Arquitetura Modular)")

    -- ⚔️ ABA: COMBATE
    self:_buildCombatTab()

    -- ⚙️ ABA: CONFIGURAÇÕES (Exemplo extra)
    self:_buildSettingsTab()

    print("✅ UIController: Interface renderizada e conectada ao Estado.")
end

-- Constrói a aba de combate separadamente para organização
function UIController:_buildCombatTab()
    local TabCombat = self._window:CreateTab("Combate", "⚔️")

    TabCombat:CreateLabel("🎯 CONFIGURAÇÕES DE ALVO")

    -- Dropdown de Seleção de Mob
    -- O valor inicial vem do StateManager
    TabCombat:CreateDropdown(
        "Selecionar Inimigo", 
        {"Nenhum", "Thief", "Monkey", "DesertBandit"}, 
        self._state:Get("SelectedMob"), 
        function(value)
            -- A UI apenas avisa o estado que o valor mudou
            self._state:Set("SelectedMob", value)
        end
    )

    -- Toggle de AutoFarm
    TabCombat:CreateToggle(
        "Auto Farm Mobs", 
        self._state:Get("AutoFarm"), 
        function(value)
            self._state:Set("AutoFarm", value)
        end
    )

    TabCombat:CreateLabel("------------------------------------------------")
    TabCombat:CreateLabel("⚙️ INTELIGÊNCIA DE MOVIMENTO")

    -- Dropdown de Posição de Ataque
    TabCombat:CreateDropdown(
        "Posição de Ataque", 
        {"Atrás", "Acima", "Abaixo", "Orbital"}, 
        self._state:Get("AttackPosition"), 
        function(value)
            self._state:Set("AttackPosition", value)
        end
    )

    -- Slider / TextBox para Distância
    TabCombat:CreateTextBox(
        "Distância do Alvo (Studs)", 
        tostring(self._state:Get("Distance")), 
        function(value)
            local numValue = tonumber(value) or 5
            self._state:Set("Distance", numValue)
        end
    )
end

-- Constrói a aba de configurações gerais
function UIController:_buildSettingsTab()
    local TabSettings = self._window:CreateTab("Configs", "⚙️")

    -- Exemplo de Botão que avisa um evento visual genérico
    TabSettings:CreateButton("Limpar Cache de Alvos", function()
        -- Note que não chamamos o TargetService aqui diretamente.
        -- O ideal seria criar um Evento Global (Signal) ou um comando no State.
        -- Para simplificar, usamos uma flag de evento no StateManager:
        self._state:Set("Command_ClearTargets", true)
    end)
end

-- Destrói a interface e limpa conexões
function UIController:Destroy()
    if self._window and self._window.Destroy then
        self._window:Destroy()
    end
end

return UIController
