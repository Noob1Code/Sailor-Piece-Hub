local UIController = {}
UIController.__index = UIController

local IslandDataMap = {
    ["Starter"] = { Mobs = {"Thief"}, Bosses = {"ThiefBoss"} },
    ["Jungle"] = { Mobs = {"Monkey"}, Bosses = {"MonkeyBoss"} },
    ["Desert"] = { Mobs = {"DesertBandit"}, Bosses = {"DesertBoss"} },
    ["Snow"] = { Mobs = {"FrostRogue"}, Bosses = {"SnowBoss"} },
    ["Sailor"] = { Mobs = {}, Bosses = {"JinwooBoss", "AlucardBoss"} }, 
    ["Shibuya"] = { Mobs = {"Sorcerer"}, Bosses = {"PandaMiniBoss", "YujiBoss", "SukunaBoss", "GojoBoss"} },
    ["Hueco Mundo"] = { Mobs = {"Hollow"}, Bosses = {"AizenBoss"} },
    ["Shinjuku"] = { Mobs = {"Curse", "StrongSorcerer"}, Bosses = {} },
    ["Slime"] = { Mobs = {"Slime"}, Bosses = {} },
    ["Academy"] = { Mobs = {"AcademyTeacher"}, Bosses = {} },
    ["Judgement"] = { Mobs = {"Swordsman"}, Bosses = {"YamatoBoss"} },
    ["Soul Society"] = { Mobs = {"Quincy"}, Bosses = {} },
    ["Boss Island"] = { Mobs = {}, Bosses = {"SaberBoss", "QinShiBoss", "IchigoBoss", "GilgameshBoss", "BlessedMaidenBoss", "SaberAlterBoss"} },
    ["Eventos (Timed Bosses)"] = { Mobs = {}, Bosses = {"MadokaBoss", "Rimuru"} }
}

local function getMobList(filter)
    local mobs = {"Nenhum", "Todos"}
    if filter == "Todas" or not filter then
        for _, data in pairs(IslandDataMap) do
            for _, mob in ipairs(data.Mobs) do table.insert(mobs, mob) end
        end
    else
        if IslandDataMap[filter] then
            for _, mob in ipairs(IslandDataMap[filter].Mobs) do table.insert(mobs, mob) end
        end
    end
    return mobs
end

local function getBossList(filter)
    local bosses = {"Nenhum"}
    if filter == "Todas" or not filter then
        for _, data in pairs(IslandDataMap) do
            for _, boss in ipairs(data.Bosses) do table.insert(bosses, boss) end
        end
    else
        if IslandDataMap[filter] then
            for _, boss in ipairs(IslandDataMap[filter].Bosses) do table.insert(bosses, boss) end
        end
    end
    return bosses
end

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
end

function UIController:_buildCombatTab()
    local TabCombat = self._window:CreateTab("Combate", "⚔️")

    TabCombat:CreateLabel("🎯 CONFIGURAÇÕES DE ALVO (MOBS)")

    local filterOptions = {"Todas"}
    for island, _ in pairs(IslandDataMap) do table.insert(filterOptions, island) end

    local mobDropdown
    local bossDropdown

    TabCombat:CreateDropdown("Filtrar por Área", filterOptions, "Todas", function(value)
        local mobs = getMobList(value)
        local bosses = getBossList(value)
        if mobDropdown then mobDropdown.Refresh(mobs) end
        if bossDropdown then bossDropdown.Refresh(bosses) end
    end)

    mobDropdown = TabCombat:CreateDropdown("Inimigo", getMobList("Todas"), self._state:Get("SelectedMob") or "Nenhum", function(value)
        self._state:Set("SelectedMob", value)
    end)

    TabCombat:CreateToggle("Auto Farm Mobs", self._state:Get("AutoFarm"), function(value)
        self._state:Set("AutoFarm", value)
    end)

    TabCombat:CreateLabel("--------------------------------------------------------")
    TabCombat:CreateLabel("👑 FILA DE BOSSES")
    
    local BossListLabel = TabCombat:CreateLabel("Fila: Nenhuma")
    
    local function UpdateBossListLabel()
        local fila = self._state:Get("SelectedBosses") or {}
        if #fila == 0 then BossListLabel.Text = "Fila: Nenhuma"
        else BossListLabel.Text = "Fila: " .. table.concat(fila, ", ") end
    end

    local bossSelecionadoTemp = "Nenhum"
    bossDropdown = TabCombat:CreateDropdown("Selecionar Boss", getBossList("Todas"), "Nenhum", function(value)
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

    TabCombat:CreateToggle("Auto Boss (Fila)", self._state:Get("AutoBoss"), function(value)
        self._state:Set("AutoBoss", value)
    end)

    TabCombat:CreateLabel("--------------------------------------------------------")
    TabCombat:CreateLabel("🔮 INVOCAÇÃO DE BOSS (SUMMON)")
    local SummonBossList = {"Nenhum", "SaberBoss", "QinShiBoss", "IchigoBoss", "GilgameshBoss", "BlessedMaidenBoss", "SaberAlterBoss"}
    
    TabCombat:CreateDropdown("Boss para Invocar", SummonBossList, self._state:Get("SelectedSummonBoss") or "Nenhum", function(value)
        self._state:Set("SelectedSummonBoss", value)
    end)

    TabCombat:CreateToggle("Auto Invocar e Farmar", self._state:Get("AutoSummon"), function(value)
        self._state:Set("AutoSummon", value)
    end)

    TabCombat:CreateLabel("--------------------------------------------------------")
    TabCombat:CreateLabel("⚙️ INTELIGÊNCIA DE COMBATE E MOVIMENTO")

    TabCombat:CreateTextBox("Velocidade do Voo (Padrão 150)", tostring(self._state:Get("TweenSpeed") or 150), function(value)
        local numValue = tonumber(value) or 150
        self._state:Set("TweenSpeed", numValue)
    end)

    TabCombat:CreateDropdown("Posição de Ataque", {"Atrás", "Acima", "Abaixo", "Orbital"}, self._state:Get("AttackPosition") or "Atrás", function(value)
        self._state:Set("AttackPosition", value)
    end)

    TabCombat:CreateTextBox("Distância do Alvo (Studs)", tostring(self._state:Get("Distance") or 5), function(value)
        local numValue = tonumber(value) or 5
        self._state:Set("Distance", numValue)
    end)
end

function UIController:Destroy()
    if self._window and self._window.Destroy then
        self._window:Destroy()
    end
end

return UIController
