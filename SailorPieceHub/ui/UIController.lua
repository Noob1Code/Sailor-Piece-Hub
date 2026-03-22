local UIController = {}
UIController.__index = UIController

function UIController.new(stateManager)
    local self = setmetatable({
        _state = stateManager,
        _window = nil
    }, UIController)
    return self
end

function UIController:Build(uiLibrary)
    print("🖥️ UIController: Construindo a interface gráfica...")
    self._window = uiLibrary.new("Comunidade Hub V22.2 (Arquitetura Modular)")
    
    self:_buildCombatTab()
    self:_buildSettingsTab()
end

function UIController:_buildCombatTab()
    local TabCombat = self._window:CreateTab("Combate", "⚔️")
    local TeleportData = Import("modules/TeleportService").new()

    TabCombat:CreateLabel("🎯 CONFIGURAÇÕES DE ALVO (MOBS)")

    local listaIlhas = TeleportData:GetIslands()
    local primeiraIlha = listaIlhas[1] or "Starter"
    local mobDropdown
    TabCombat:CreateDropdown("Filtrar por Ilha", listaIlhas, primeiraIlha, function(value)
        local mobsDaIlha = TeleportData:GetMobsFromIsland(value)
        if mobDropdown then mobDropdown.Refresh(mobsDaIlha) end
    end)

    mobDropdown = TabCombat:CreateDropdown("Selecionar Inimigo", TeleportData:GetMobsFromIsland(primeiraIlha), "Nenhum", function(value)
        self._state:Set("SelectedMob", value)
    end)

    TabCombat:CreateToggle("Auto Farm Mobs", self._state:Get("AutoFarm"), function(value)
        self._state:Set("AutoFarm", value)
    end)

    TabCombat:CreateLabel("------------------------------------------------")
    TabCombat:CreateLabel("👑 FILA DE BOSSES E SNIPER")
    
    local BossListLabel = TabCombat:CreateLabel("Fila: Nenhuma")
    
    local function UpdateBossListLabel()
        local fila = self._state:Get("SelectedBosses") or {}
        if #fila == 0 then BossListLabel.Text = "Fila: Nenhuma"
        else BossListLabel.Text = "Fila: " .. table.concat(fila, ", ") end
    end

    local TodosOsBosses = {"ThiefBoss", "MonkeyBoss", "DesertBoss", "SnowBoss", "JinwooBoss", "AlucardBoss", "YujiBoss", "SukunaBoss", "GojoBoss", "PandaMiniBoss", "AizenBoss", "YamatoBoss", "GilgameshBoss", "SaberBoss"}
    
    local bossSelecionadoTemp = "Nenhum"
    TabCombat:CreateDropdown("Selecionar Boss", TodosOsBosses, "Nenhum", function(value)
        bossSelecionadoTemp = value
    end)

    TabCombat:CreateButton("➕ Adicionar Boss à Fila", function()
        if bossSelecionadoTemp ~= "Nenhum" then
            local fila = self._state:Get("SelectedBosses") or {}
            if not table.find(fila, bossSelecionadoTemp) then
                table.insert(fila, bossSelecionadoTemp)
                self._state:Set("SelectedBosses", fila)
                UpdateBossListLabel()
            end
        end
    end, Color3.fromRGB(40, 150, 80))

    TabCombat:CreateButton("🗑️ Limpar Fila", function()
        self._state:Set("SelectedBosses", {})
        UpdateBossListLabel()
    end, Color3.fromRGB(200, 100, 60))

    TabCombat:CreateToggle("Auto Boss (Fila / Sniper)", self._state:Get("AutoBoss"), function(value)
        self._state:Set("AutoBoss", value)
    end)

    TabCombat:CreateLabel("------------------------------------------------")
    TabCombat:CreateLabel("🔮 INVOCAÇÃO DE BOSS (SUMMON)")
    local SummonBossList = {"Nenhum", "SaberBoss", "QinShiBoss", "IchigoBoss", "GilgameshBoss", "BlessedMaidenBoss", "SaberAlterBoss"}
    
    TabCombat:CreateDropdown("Boss para Invocar", SummonBossList, self._state:Get("SelectedSummonBoss"), function(value)
        self._state:Set("SelectedSummonBoss", value)
    end)

    TabCombat:CreateToggle("Auto Invocar e Farmar", self._state:Get("AutoSummon"), function(value)
        self._state:Set("AutoSummon", value)
    end)

    TabCombat:CreateLabel("------------------------------------------------")
    TabCombat:CreateLabel("⚙️ INTELIGÊNCIA DE MOVIMENTO")

    TabCombat:CreateDropdown("Posição de Ataque", {"Atrás", "Acima", "Abaixo", "Orbital"}, self._state:Get("AttackPosition"), function(value)
        self._state:Set("AttackPosition", value)
    end)

    TabCombat:CreateTextBox("Distância do Alvo (Studs)", tostring(self._state:Get("Distance")), function(value)
        local numValue = tonumber(value) or 5
        self._state:Set("Distance", numValue)
    end)
end

function UIController:_buildSettingsTab()
    local TabSettings = self._window:CreateTab("Configs", "⚙️")
    TabSettings:CreateButton("Limpar Cache de Alvos", function()
        self._state:Set("Command_ClearTargets", true)
    end)
end

function UIController:Destroy()
    if self._window and self._window.Destroy then
        self._window:Destroy()
    end
end

return UIController
