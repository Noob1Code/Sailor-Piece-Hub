local LP = getgenv().LP
local CoreGui = getgenv().CoreGui
local UserInputService = getgenv().UserInputService
local Workspace = getgenv().Workspace
local HubConfig = getgenv().HubConfig
local TeleportRemote = getgenv().TeleportRemote
local AllocateStatRemote = getgenv().AllocateStatRemote
local ResetStatsRemote = getgenv().ResetStatsRemote
local UseItemRemote = getgenv().UseItemRemote
local TraitRerollRemote = getgenv().TraitRerollRemote
local RerollSingleStatRemote = getgenv().RerollSingleStatRemote
local scriptConnections = getgenv().scriptConnections
local getMobList = getgenv().getMobList
local getBossList = getgenv().getBossList
local getQuestsForIsland = getgenv().getQuestsForIsland
local getWeaponList = getgenv().getWeaponList
local unfreezeCharacter = getgenv().unfreezeCharacter
local SafeTeleport = getgenv().SafeTeleport
local MobDropdownRef, BossDropdownRef, QuestDropdownRef, WeaponDropdownRef

getgenv().UI = { Tabs = {}, CurrentTab = nil }
local UI = getgenv().UI

UI.Init = function()
    local uiParent = pcall(function() return CoreGui.Name end) and CoreGui or LP:WaitForChild("PlayerGui")
    if uiParent:FindFirstChild("ComunidadeHubGUI") then uiParent.ComunidadeHubGUI:Destroy() end
    
    local ScreenGui = Instance.new("ScreenGui"); ScreenGui.Name = "ComunidadeHubGUI"; ScreenGui.Parent = uiParent; ScreenGui.ResetOnSpawn = false
    local MainFrame = Instance.new("Frame"); MainFrame.Size = UDim2.new(0, 540, 0, 460); MainFrame.Position = UDim2.new(0.5, -270, 0.5, -230); MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20); MainFrame.ClipsDescendants = true; MainFrame.Parent = ScreenGui
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
    
    local TitleBar = Instance.new("TextButton"); TitleBar.Size = UDim2.new(1, 0, 0, 40); TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 30); TitleBar.TextColor3 = Color3.fromRGB(255, 255, 255); TitleBar.Text = "   🌟 Comunidade Hub V22.2 (Modularizado)"; TitleBar.Font = Enum.Font.GothamBold; TitleBar.TextSize = 14; TitleBar.TextXAlignment = Enum.TextXAlignment.Left; TitleBar.Parent = MainFrame; TitleBar.AutoButtonColor = false
    Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 8)
    
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = MainFrame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then update(input) end
    end)

    local TabSelectorContainer = Instance.new("ScrollingFrame"); TabSelectorContainer.Size = UDim2.new(0, 150, 1, -40); TabSelectorContainer.Position = UDim2.new(0, 0, 0, 40); TabSelectorContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 25); TabSelectorContainer.BorderSizePixel = 0; TabSelectorContainer.ScrollBarThickness = 2; TabSelectorContainer.Parent = MainFrame
    local TabListLayout = Instance.new("UIListLayout"); TabListLayout.Parent = TabSelectorContainer; TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder; TabListLayout.Padding = UDim.new(0, 2)
    local ContentContainer = Instance.new("Frame"); ContentContainer.Size = UDim2.new(1, -150, 1, -40); ContentContainer.Position = UDim2.new(0, 150, 0, 40); ContentContainer.BackgroundTransparency = 1; ContentContainer.Parent = MainFrame

    local function doCleanup()
        getgenv().isRunning = false 
        for _, conn in ipairs(scriptConnections) do if conn then conn:Disconnect() end end
        pcall(function()
            local char = LP.Character; if char then unfreezeCharacter(char) end
            LP:SetAttribute("RaceExtraJumps", 0); LP:SetAttribute("AutoArmHaki", false)
            LP:SetAttribute("AutoObsHaki", false); LP:SetAttribute("DisableScreenShake", false)
            LP:SetAttribute("DisableCutscene", false); LP:SetAttribute("DisablePvP", false)
        end)
        if ScreenGui then ScreenGui:Destroy() end
    end
    _G.ComunidadeHub_Cleanup = doCleanup 

    local CloseBtn = Instance.new("TextButton"); CloseBtn.Size = UDim2.new(0, 30, 0, 30); CloseBtn.Position = UDim2.new(1, -35, 0.5, -15); CloseBtn.BackgroundTransparency = 1; CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80); CloseBtn.Text = "X"; CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.Parent = TitleBar
    CloseBtn.MouseButton1Click:Connect(doCleanup)

    local MinBtn = Instance.new("TextButton"); MinBtn.Size = UDim2.new(0, 30, 0, 30); MinBtn.Position = UDim2.new(1, -65, 0.5, -15); MinBtn.BackgroundTransparency = 1; MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255); MinBtn.Text = "-"; MinBtn.Font = Enum.Font.GothamBold; MinBtn.Parent = TitleBar
    local isMinimized = false
    MinBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized; MinBtn.Text = isMinimized and "+" or "-"
        MainFrame:TweenSize(isMinimized and UDim2.new(0, 540, 0, 40) or UDim2.new(0, 540, 0, 460), "Out", "Quart", 0.3, true)
        TabSelectorContainer.Visible = not isMinimized; ContentContainer.Visible = not isMinimized
    end)

    UI.TabSelectorContainer = TabSelectorContainer; UI.ContentContainer = ContentContainer
end

UI.CreateTab = function(name, icon)
    local TabBtn = Instance.new("TextButton"); TabBtn.Size = UDim2.new(1, 0, 0, 35); TabBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25); TabBtn.BorderSizePixel = 0; TabBtn.TextColor3 = Color3.fromRGB(180, 180, 180); TabBtn.Text = "  " .. (icon or "") .. " " .. name; TabBtn.Font = Enum.Font.GothamSemibold; TabBtn.TextSize = 13; TabBtn.TextXAlignment = Enum.TextXAlignment.Left; TabBtn.Parent = UI.TabSelectorContainer
    local TabContent = Instance.new("ScrollingFrame"); TabContent.Size = UDim2.new(1, -10, 1, -10); TabContent.Position = UDim2.new(0, 5, 0, 5); TabContent.BackgroundTransparency = 1; TabContent.ScrollBarThickness = 2; TabContent.Visible = false; TabContent.Parent = UI.ContentContainer
    local ContentLayout = Instance.new("UIListLayout"); ContentLayout.Parent = TabContent; ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder; ContentLayout.Padding = UDim.new(0, 6)
    ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() TabContent.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 10) end)

    TabBtn.MouseButton1Click:Connect(function()
        for _, tabInfo in pairs(UI.Tabs) do tabInfo.Content.Visible = false tabInfo.Button.BackgroundColor3 = Color3.fromRGB(20, 20, 25) end
        TabContent.Visible = true; TabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    end)

    if not UI.CurrentTab then TabContent.Visible = true; TabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45); UI.CurrentTab = TabContent end
    table.insert(UI.Tabs, {Button = TabBtn, Content = TabContent}); return TabContent
end

UI.CreateLabel = function(parent, text)
    local Label = Instance.new("TextLabel"); Label.Size = UDim2.new(1, 0, 0, 20); Label.BackgroundTransparency = 1; Label.TextColor3 = Color3.fromRGB(150, 150, 180); Label.Text = text; Label.TextXAlignment = Enum.TextXAlignment.Left; Label.Font = Enum.Font.GothamBold; Label.TextSize = 12; Label.Parent = parent
    return Label
end

UI.CreateButton = function(parent, text, callback, color)
    local Btn = Instance.new("TextButton"); Btn.Size = UDim2.new(1, -5, 0, 32); Btn.BackgroundColor3 = color or Color3.fromRGB(45, 100, 255); Btn.TextColor3 = Color3.fromRGB(255, 255, 255); Btn.Text = text; Btn.Font = Enum.Font.GothamSemibold; Btn.TextSize = 13; Btn.Parent = parent
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4); Btn.MouseButton1Click:Connect(callback)
    return Btn
end

UI.CreateToggle = function(parent, text, defaultState, callback)
    local ToggleBtn = Instance.new("TextButton"); ToggleBtn.Size = UDim2.new(1, -5, 0, 32); ToggleBtn.BackgroundColor3 = defaultState and Color3.fromRGB(40, 180, 80) or Color3.fromRGB(40, 40, 50); ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255); ToggleBtn.Text = text .. " [" .. (defaultState and "ON" or "OFF") .. "]"; ToggleBtn.Font = Enum.Font.GothamSemibold; ToggleBtn.TextSize = 13; ToggleBtn.Parent = parent
    Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 4)
    local state = defaultState
    ToggleBtn.MouseButton1Click:Connect(function()
        state = not state; ToggleBtn.BackgroundColor3 = state and Color3.fromRGB(40, 180, 80) or Color3.fromRGB(40, 40, 50)
        ToggleBtn.Text = text .. " [" .. (state and "ON" or "OFF") .. "]"
        callback(state)
        if getgenv().SaveSettings then getgenv().SaveSettings() end
    end)
end

UI.CreateDropdown = function(parent, title, options, defaultOption, callback)
    local DropFrame = Instance.new("Frame"); DropFrame.Size = UDim2.new(1, -5, 0, 32); DropFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40); DropFrame.ClipsDescendants = true; DropFrame.Parent = parent
    Instance.new("UICorner", DropFrame).CornerRadius = UDim.new(0, 4)
    local MainBtn = Instance.new("TextButton"); MainBtn.Size = UDim2.new(1, 0, 0, 32); MainBtn.BackgroundTransparency = 1; MainBtn.TextColor3 = Color3.fromRGB(200, 200, 200); MainBtn.Text = "  " .. title .. ": " .. defaultOption; MainBtn.Font = Enum.Font.GothamSemibold; MainBtn.TextSize = 12; MainBtn.TextXAlignment = Enum.TextXAlignment.Left; MainBtn.Parent = DropFrame
    
    local ListFrame = Instance.new("ScrollingFrame"); ListFrame.Size = UDim2.new(1, 0, 1, -32); ListFrame.Position = UDim2.new(0, 0, 0, 32); ListFrame.BackgroundTransparency = 1; ListFrame.ScrollBarThickness = 2; ListFrame.Parent = DropFrame
    local ListLayout = Instance.new("UIListLayout"); ListLayout.Parent = ListFrame
    local isOpen = false

    local function updateSelection(opt)
        MainBtn.Text = "  " .. title .. ": " .. opt; callback(opt)
        isOpen = false; DropFrame.Size = UDim2.new(1, -5, 0, 32)
        if getgenv().SaveSettings then getgenv().SaveSettings() end
    end

    MainBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        DropFrame.Size = isOpen and UDim2.new(1, -5, 0, math.min(ListLayout.AbsoluteContentSize.Y + 32, 120)) or UDim2.new(1, -5, 0, 32)
        ListFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y)
    end)

    local function refresh(newOptions)
        for _, b in pairs(ListFrame:GetChildren()) do if b:IsA("TextButton") then b:Destroy() end end
        for _, opt in ipairs(newOptions) do
            local OptBtn = Instance.new("TextButton"); OptBtn.Size = UDim2.new(1, 0, 0, 25); OptBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45); OptBtn.TextColor3 = Color3.fromRGB(180, 180, 180); OptBtn.Text = "  " .. opt; OptBtn.Font = Enum.Font.Gotham; OptBtn.TextSize = 12; OptBtn.TextXAlignment = Enum.TextXAlignment.Left; OptBtn.Parent = ListFrame
            OptBtn.MouseButton1Click:Connect(function() updateSelection(opt) end)
        end
        MainBtn.Text = "  " .. title .. ": " .. (newOptions[1] or "Nenhum")
        callback(newOptions[1] or "Nenhum") 
    end

    refresh(options)
    MainBtn.Text = "  " .. title .. ": " .. defaultOption
    callback(defaultOption)

    return { Refresh = refresh }
end

UI.CreateTextBox = function(parent, title, defaultText, callback)
    local Container = Instance.new("Frame"); Container.Size = UDim2.new(1, -5, 0, 32); Container.BackgroundColor3 = Color3.fromRGB(30, 30, 40); Container.Parent = parent
    Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 4)
    local Label = Instance.new("TextLabel"); Label.Size = UDim2.new(0.6, 0, 1, 0); Label.BackgroundTransparency = 1; Label.TextColor3 = Color3.fromRGB(200, 200, 200); Label.Text = "  " .. title; Label.Font = Enum.Font.GothamSemibold; Label.TextSize = 12; Label.TextXAlignment = Enum.TextXAlignment.Left; Label.Parent = Container
    local TextBox = Instance.new("TextBox"); TextBox.Size = UDim2.new(0.35, -5, 0.8, 0); TextBox.Position = UDim2.new(0.65, 0, 0.1, 0); TextBox.BackgroundColor3 = Color3.fromRGB(20, 20, 25); TextBox.TextColor3 = Color3.fromRGB(255, 255, 255); TextBox.Text = tostring(defaultText); TextBox.Font = Enum.Font.Gotham; TextBox.TextSize = 12; TextBox.Parent = Container
    Instance.new("UICorner", TextBox).CornerRadius = UDim.new(0, 4)
    TextBox.FocusLost:Connect(function() 
        local val = TextBox.Text; if tonumber(val) then callback(tonumber(val)) else callback(val) end 
        if getgenv().SaveSettings then getgenv().SaveSettings() end
    end)
end

UI.Init()

-- ABA 1: DASHBOARD
local TabDash = UI.CreateTab("Dashboard", "📊")
UI.CreateLabel(TabDash, "INFORMAÇÕES DO JOGADOR")
local InfoRace = UI.CreateLabel(TabDash, "Raça: Carregando...")
local InfoClan = UI.CreateLabel(TabDash, "Clã: Carregando...")
local InfoDamage = UI.CreateLabel(TabDash, "Bônus Melee/Sword: Carregando...")
local InfoBoss = UI.CreateLabel(TabDash, "Bônus Boss/Crit: Carregando...")
local InfoPity = UI.CreateLabel(TabDash, "Sorte: Carregando...")

task.spawn(function()
    while getgenv().isRunning and task.wait(1) do
        pcall(function()
            local race = LP:GetAttribute("CurrentRace") or "Humano"; local clan = LP:GetAttribute("CurrentClan") or "Nenhum"
            local meleeDmg = LP:GetAttribute("RaceMeleeDamage") or 0; local swordDmg = LP:GetAttribute("RaceSwordDamage") or 0
            local bossDmg = LP:GetAttribute("BossRush_Damage") or 0; local bossCrit = LP:GetAttribute("BossRush_CritDamage") or 0
            local luck = LP:GetAttribute("RaceLuckBonus") or 0; local jumps = LP:GetAttribute("RaceExtraJumps") or 0
            InfoRace.Text = "Raça Atual: " .. tostring(race) .. " (+ " .. tostring(jumps) .. " Pulos)"
            InfoClan.Text = "Clã Atual: " .. tostring(clan)
            InfoDamage.Text = "Multiplicadores: Melee [" .. tostring(meleeDmg) .. "] | Sword [" .. tostring(swordDmg) .. "]"
            InfoBoss.Text = "Bônus em Bosses: Dano [" .. tostring(bossDmg) .. "] | Crítico [" .. tostring(bossCrit) .. "]"
            InfoPity.Text = "Bônus de Sorte: " .. tostring(luck)
        end)
    end
end)

-- ABA 2: MISSÕES
local TabMissions = UI.CreateTab("Missões", "📜")
UI.CreateLabel(TabMissions, "⚡ MODO AUTO LEVEL MÁXIMO (1 AO MAX)")
UI.CreateToggle(TabMissions, "ATIVAR PILOTO AUTOMÁTICO", false, function(v) HubConfig.AutoFarmMaxLevel = v; if v then HubConfig.AutoQuest = false end end)
UI.CreateLabel(TabMissions, "--------------------------------------------------------")
UI.CreateLabel(TabMissions, "🎯 MODO MISSÃO MANUAL (FARM DE ITENS)")
UI.CreateDropdown(TabMissions, "Escolha a Ilha", HubConfig.QuestFilterOptions, "Starter", function(s) HubConfig.SelectedQuestIsland = s; local quests = getQuestsForIsland(s); if QuestDropdownRef then QuestDropdownRef.Refresh(quests) end end)
local initialQuests = getQuestsForIsland(HubConfig.SelectedQuestIsland)
QuestDropdownRef = UI.CreateDropdown(TabMissions, "Escolha a Missão", initialQuests, initialQuests[1], function(s) HubConfig.SelectedQuest = s end)
UI.CreateToggle(TabMissions, "FARM MISSÃO SELECIONADA", false, function(v) HubConfig.AutoQuest = v; if v then HubConfig.AutoFarmMaxLevel = false end end)

-- ABA 3: COMBATE
local TabCombat = UI.CreateTab("Combate", "⚔️")
UI.CreateLabel(TabCombat, "🔍 SISTEMA DE MAPA")
UI.CreateButton(TabCombat, "Varrer Ilha (Atualizar NPCs Existentes)", function() HubConfig.AvailableMobs = getMobList(HubConfig.SelectedFilter); if MobDropdownRef then MobDropdownRef.Refresh(HubConfig.AvailableMobs) end end)
UI.CreateLabel(TabCombat, "--------------------------------------------------------")
UI.CreateDropdown(TabCombat, "Filtrar por Área", HubConfig.FilterOptions, "Todas", function(s) HubConfig.SelectedFilter = s; HubConfig.AvailableMobs = getMobList(s); HubConfig.Bosses = getBossList(s); if MobDropdownRef then MobDropdownRef.Refresh(HubConfig.AvailableMobs) end; if BossDropdownRef then BossDropdownRef.Refresh(HubConfig.Bosses) end end)
MobDropdownRef = UI.CreateDropdown(TabCombat, "Inimigo", HubConfig.AvailableMobs, "Nenhum", function(s) HubConfig.SelectedMob = s end)
UI.CreateToggle(TabCombat, "Auto Farm Mobs", false, function(v) HubConfig.AutoFarm = v end)
UI.CreateLabel(TabCombat, "--------------------------------------------------------")
UI.CreateTextBox(TabCombat, "Buscar Boss (Digite e Enter)", "", function(text)
    local currentBosses = getBossList(HubConfig.SelectedFilter); local filtered = {}; text = tostring(text):lower()
    if text == "" then filtered = currentBosses else table.insert(filtered, "Nenhum"); for _, boss in ipairs(currentBosses) do if boss ~= "Nenhum" and boss:lower():find(text) then table.insert(filtered, boss) end end end
    if BossDropdownRef then BossDropdownRef.Refresh(filtered) end
end)
BossDropdownRef = UI.CreateDropdown(TabCombat, "Boss", HubConfig.Bosses, "Nenhum", function(s) HubConfig.SelectedBoss = s end)
UI.CreateToggle(TabCombat, "Auto Boss", false, function(v) HubConfig.AutoBoss = v end)
UI.CreateToggle(TabCombat, "Auto Training Dummy", false, function(v) HubConfig.AutoDummy = v end)
UI.CreateLabel(TabCombat, "--------------------------------------------------------")
UI.CreateLabel(TabCombat, "⚙️ INTELIGÊNCIA DE COMBATE")
UI.CreateDropdown(TabCombat, "Posição de Ataque", {"Atrás", "Acima", "Abaixo", "Orbital"}, HubConfig.AttackPosition, function(s) 
    HubConfig.AttackPosition = s 
end)
UI.CreateTextBox(TabCombat, "Distância do Alvo (Studs)", HubConfig.Distance, function(v) 
    HubConfig.Distance = tonumber(v) or 5 
end)

UI.CreateLabel(TabCombat, "--------------------------------------------------------")
UI.CreateLabel(TabCombat, "🗡️ ESCOLHA SUA ARMA")
UI.CreateButton(TabCombat, "Atualizar Lista de Armas no Inventário", function() HubConfig.AvailableWeapons = getWeaponList(); if WeaponDropdownRef then WeaponDropdownRef.Refresh(HubConfig.AvailableWeapons) end end)
WeaponDropdownRef = UI.CreateDropdown(TabCombat, "Arma para Auto Farm", HubConfig.AvailableWeapons, "Nenhuma", function(s) HubConfig.SelectedWeapon = s end)

-- ABA 4: ITENS
local TabCollect = UI.CreateTab("Itens", "🎒")
UI.CreateToggle(TabCollect, "Auto Group Reward", false, function(v) HubConfig.AutoGroupReward = v end)
UI.CreateToggle(TabCollect, "Coletar Frutas (Map Scan)", false, function(v) HubConfig.AutoCollect.Fruits = v end)
UI.CreateToggle(TabCollect, "Coletar Hogyoku", false, function(v) HubConfig.AutoCollect.Hogyoku = v end)
UI.CreateToggle(TabCollect, "Coletar Puzzles", false, function(v) HubConfig.AutoCollect.Puzzles = v end)
UI.CreateToggle(TabCollect, "Coletar Baús do Chão", false, function(v) HubConfig.AutoCollect.Chests = v end)

-- ABA 5: STATUS
local TabStats = UI.CreateTab("Status", "📈")
local InfoPoints = UI.CreateLabel(TabStats, "Pontos Disponíveis: Carregando...")
UI.CreateLabel(TabStats, "--------------------------------------------------------")
UI.CreateLabel(TabStats, "DISTRIBUIÇÃO MANUAL")
HubConfig.ManualStat = "Melee"; HubConfig.ManualAmount = 1
UI.CreateDropdown(TabStats, "Atributo", HubConfig.StatsList, "Melee", function(s) HubConfig.ManualStat = s end)
UI.CreateTextBox(TabStats, "Quantidade", 1, function(v) HubConfig.ManualAmount = tonumber(v) or 1 end)
UI.CreateButton(TabStats, "➕ Adicionar Pontos", function() if AllocateStatRemote then AllocateStatRemote:FireServer(HubConfig.ManualStat, HubConfig.ManualAmount) end end, Color3.fromRGB(40, 150, 80))
UI.CreateLabel(TabStats, "--------------------------------------------------------")
UI.CreateLabel(TabStats, "DISTRIBUIÇÃO AUTOMÁTICA (DIVISÃO)")
for _, stat in ipairs(HubConfig.StatsList) do
    UI.CreateToggle(TabStats, "Auto Upar " .. stat, false, function(v) if v then if not table.find(HubConfig.SelectedStats, stat) then table.insert(HubConfig.SelectedStats, stat) end else local idx = table.find(HubConfig.SelectedStats, stat); if idx then table.remove(HubConfig.SelectedStats, idx) end end end)
end
UI.CreateLabel(TabStats, "--------------------------------------------------------")
UI.CreateToggle(TabStats, "Ativar Auto Distribuir", false, function(v) HubConfig.AutoStats = v end)
UI.CreateButton(TabStats, "🔄 Reset Status", function() if ResetStatsRemote then ResetStatsRemote:FireServer() end end, Color3.fromRGB(200, 60, 60))
task.spawn(function() while getgenv().isRunning and task.wait(1) do pcall(function() local data = LP:FindFirstChild("Data"); if data and data:FindFirstChild("StatPoints") then InfoPoints.Text = "Pontos Disponíveis: " .. tostring(data.StatPoints.Value) else InfoPoints.Text = "Pontos Disponíveis: 0" end end) end end)

-- ABA 6: ROLETA
local TabRoleta = UI.CreateTab("Roleta", "🎲")
UI.CreateTextBox(TabRoleta, "Raça Sniper", HubConfig.AutoReroll.TargetRace, function(v) HubConfig.AutoReroll.TargetRace = tostring(v) end)
UI.CreateToggle(TabRoleta, "Iniciar Sniper Raça", false, function(v) HubConfig.AutoReroll.Race = v end)
UI.CreateToggle(TabRoleta, "Abrir Todos Baús", false, function(v) HubConfig.AutoOpenChests.Common = v; HubConfig.AutoOpenChests.Rare = v; HubConfig.AutoOpenChests.Epic = v; HubConfig.AutoOpenChests.Mythical = v end)

-- ABA 7: MUNDO
local TabWorld = UI.CreateTab("Mundo", "🌍")
local MundoPronto = false 
UI.CreateLabel(TabWorld, "PORTAIS INSTANTÂNEOS")
UI.CreateDropdown(TabWorld, "Viajar para Ilha", HubConfig.Islands, "Starter", function(s) if MundoPronto and TeleportRemote then TeleportRemote:FireServer(s) end end)
UI.CreateLabel(TabWorld, "IR ATÉ NPC (VOANDO)")
UI.CreateDropdown(TabWorld, "Selecione o NPC", HubConfig.NPCs, "EnchantNPC", function(s) if MundoPronto then local npc = Workspace:FindFirstChild("ServiceNPCs") and Workspace.ServiceNPCs:FindFirstChild(s); if npc and npc:FindFirstChild("HumanoidRootPart") then unfreezeCharacter(LP.Character); SafeTeleport(npc.HumanoidRootPart.Position + Vector3.new(0, 0, 5)) end end end)
MundoPronto = true

-- ABA 8: NATIVOS
local TabNativos = UI.CreateTab("Nativos", "🕵️‍♂️")
UI.CreateLabel(TabNativos, "HACKS NATIVOS (Indetectáveis)")
UI.CreateToggle(TabNativos, "Haki do Armamento", false, function(v) pcall(function() LP:SetAttribute("AutoArmHaki", v) end) end)
UI.CreateToggle(TabNativos, "Haki da Observação", false, function(v) pcall(function() LP:SetAttribute("AutoObsHaki", v) end) end)
UI.CreateToggle(TabNativos, "Hack de Pulos Extras", false, function(v) HubConfig.HacksNativos.PuloExtra = v; if not v then pcall(function() LP:SetAttribute("RaceExtraJumps", 0) end) end end)
UI.CreateLabel(TabNativos, "QUALIDADE DE VIDA")
UI.CreateToggle(TabNativos, "Remover Tremores (NoShake)", false, function(v) pcall(function() LP:SetAttribute("DisableScreenShake", v) end) end)
UI.CreateToggle(TabNativos, "Pular Animações (NoCutscene)", false, function(v) pcall(function() LP:SetAttribute("DisableCutscene", v) end) end)
UI.CreateToggle(TabNativos, "Modo Proteção PvP", false, function(v) pcall(function() LP:SetAttribute("DisablePvP", v) end) end)

-- ABA 9: FRUIT SNIPER V2
local TabSniper = UI.CreateTab("Fruit V2", "🍎")
UI.CreateLabel(TabSniper, "FRUIT SNIPER NATIVO (REAL-TIME)")
UI.CreateToggle(TabSniper, "Sniper de Frutas Instantâneo", false, function(v) HubConfig.FruitSniper = v end)

-- ABA 10: MISC
local TabMisc = UI.CreateTab("Misc", "⚙️")
UI.CreateToggle(TabMisc, "Super Velocidade", false, function(v) HubConfig.SuperSpeed = v end)
UI.CreateToggle(TabMisc, "Pulo Infinito", false, function(v) HubConfig.InfJump = v end)

print("✅ Comunidade Hub - Módulos Carregados com Sucesso!")
