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

local Library = {}
Library.__index = Library

function Library.new(title)
    local self = setmetatable({}, Library)
    self.Tabs = {}
    self.CurrentTab = nil
    
    local uiParent = pcall(function() return CoreGui.Name end) and CoreGui or LP:WaitForChild("PlayerGui")
    if uiParent:FindFirstChild("ComunidadeHubGUI") then uiParent.ComunidadeHubGUI:Destroy() end
    
    self.ScreenGui = Instance.new("ScreenGui"); self.ScreenGui.Name = "ComunidadeHubGUI"; self.ScreenGui.Parent = uiParent; self.ScreenGui.ResetOnSpawn = false
    self.MainFrame = Instance.new("Frame"); self.MainFrame.Size = UDim2.new(0, 540, 0, 460); self.MainFrame.Position = UDim2.new(0.5, -270, 0.5, -230); self.MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20); self.MainFrame.ClipsDescendants = true; self.MainFrame.Parent = self.ScreenGui
    Instance.new("UICorner", self.MainFrame).CornerRadius = UDim.new(0, 8)
    
    local TitleBar = Instance.new("TextButton"); TitleBar.Size = UDim2.new(1, 0, 0, 40); TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 30); TitleBar.TextColor3 = Color3.fromRGB(255, 255, 255); TitleBar.Text = "   🌟 " .. title; TitleBar.Font = Enum.Font.GothamBold; TitleBar.TextSize = 14; TitleBar.TextXAlignment = Enum.TextXAlignment.Left; TitleBar.Parent = self.MainFrame; TitleBar.AutoButtonColor = false
    Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 8)
    
    local dragging, dragInput, dragStart, startPos
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = self.MainFrame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    TitleBar.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
    UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then local delta = input.Position - dragStart; self.MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)

    self.TabSelector = Instance.new("ScrollingFrame"); self.TabSelector.Size = UDim2.new(0, 150, 1, -40); self.TabSelector.Position = UDim2.new(0, 0, 0, 40); self.TabSelector.BackgroundColor3 = Color3.fromRGB(20, 20, 25); self.TabSelector.BorderSizePixel = 0; self.TabSelector.ScrollBarThickness = 2; self.TabSelector.Parent = self.MainFrame
    Instance.new("UIListLayout", self.TabSelector).Padding = UDim.new(0, 2)
    self.ContentContainer = Instance.new("Frame"); self.ContentContainer.Size = UDim2.new(1, -150, 1, -40); self.ContentContainer.Position = UDim2.new(0, 150, 0, 40); self.ContentContainer.BackgroundTransparency = 1; self.ContentContainer.Parent = self.MainFrame

    local function doCleanup()
        getgenv().isRunning = false 
        for _, conn in ipairs(scriptConnections) do if conn then conn:Disconnect() end end
        pcall(function()
            local char = LP.Character; if char then unfreezeCharacter(char) end
            LP:SetAttribute("RaceExtraJumps", 0); LP:SetAttribute("AutoArmHaki", false)
            LP:SetAttribute("AutoObsHaki", false); LP:SetAttribute("DisableScreenShake", false)
            LP:SetAttribute("DisableCutscene", false); LP:SetAttribute("DisablePvP", false)
        end)
        if self.ScreenGui then self.ScreenGui:Destroy() end
    end
    _G.ComunidadeHub_Cleanup = doCleanup 

    local CloseBtn = Instance.new("TextButton"); CloseBtn.Size = UDim2.new(0, 30, 0, 30); CloseBtn.Position = UDim2.new(1, -35, 0.5, -15); CloseBtn.BackgroundTransparency = 1; CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80); CloseBtn.Text = "X"; CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.Parent = TitleBar
    CloseBtn.MouseButton1Click:Connect(doCleanup)

    local MinBtn = Instance.new("TextButton"); MinBtn.Size = UDim2.new(0, 30, 0, 30); MinBtn.Position = UDim2.new(1, -65, 0.5, -15); MinBtn.BackgroundTransparency = 1; MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255); MinBtn.Text = "-"; MinBtn.Font = Enum.Font.GothamBold; MinBtn.Parent = TitleBar
    local isMinimized = false
    MinBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized; MinBtn.Text = isMinimized and "+" or "-"
        self.MainFrame:TweenSize(isMinimized and UDim2.new(0, 540, 0, 40) or UDim2.new(0, 540, 0, 460), "Out", "Quart", 0.3, true)
        self.TabSelector.Visible = not isMinimized; self.ContentContainer.Visible = not isMinimized
    end)

    return self
end

function Library:CreateTab(name, icon)
    local Tab = {}
    Tab.Window = self
    
    local TabBtn = Instance.new("TextButton"); TabBtn.Size = UDim2.new(1, 0, 0, 35); TabBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25); TabBtn.BorderSizePixel = 0; TabBtn.TextColor3 = Color3.fromRGB(180, 180, 180); TabBtn.Text = "  " .. (icon or "") .. " " .. name; TabBtn.Font = Enum.Font.GothamSemibold; TabBtn.TextSize = 13; TabBtn.TextXAlignment = Enum.TextXAlignment.Left; TabBtn.Parent = self.TabSelector
    local TabContent = Instance.new("ScrollingFrame"); TabContent.Size = UDim2.new(1, -10, 1, -10); TabContent.Position = UDim2.new(0, 5, 0, 5); TabContent.BackgroundTransparency = 1; TabContent.ScrollBarThickness = 2; TabContent.Visible = false; TabContent.Parent = self.ContentContainer
    local ContentLayout = Instance.new("UIListLayout"); ContentLayout.Parent = TabContent; ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder; ContentLayout.Padding = UDim.new(0, 6)
    ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() TabContent.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 10) end)

    TabBtn.MouseButton1Click:Connect(function()
        for _, tabInfo in pairs(self.Tabs) do tabInfo.Content.Visible = false; tabInfo.Button.BackgroundColor3 = Color3.fromRGB(20, 20, 25) end
        TabContent.Visible = true; TabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    end)

    if not self.CurrentTab then TabContent.Visible = true; TabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45); self.CurrentTab = TabContent end
    table.insert(self.Tabs, {Button = TabBtn, Content = TabContent})
    Tab.Container = TabContent

    -- MÉTODOS DA ABA
    function Tab:CreateLabel(text)
        local Label = Instance.new("TextLabel"); Label.Size = UDim2.new(1, 0, 0, 20); Label.BackgroundTransparency = 1; Label.TextColor3 = Color3.fromRGB(150, 150, 180); Label.Text = text; Label.TextXAlignment = Enum.TextXAlignment.Left; Label.Font = Enum.Font.GothamBold; Label.TextSize = 12; Label.Parent = self.Container
        return Label
    end

    function Tab:CreateButton(text, callback, color)
        local Btn = Instance.new("TextButton"); Btn.Size = UDim2.new(1, -5, 0, 32); Btn.BackgroundColor3 = color or Color3.fromRGB(45, 100, 255); Btn.TextColor3 = Color3.fromRGB(255, 255, 255); Btn.Text = text; Btn.Font = Enum.Font.GothamSemibold; Btn.TextSize = 13; Btn.Parent = self.Container
        Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4); Btn.MouseButton1Click:Connect(callback)
        return Btn
    end

    function Tab:CreateToggle(text, defaultState, callback)
        local state = defaultState
        local ToggleBtn = Instance.new("TextButton"); ToggleBtn.Size = UDim2.new(1, -5, 0, 32); ToggleBtn.BackgroundColor3 = state and Color3.fromRGB(40, 180, 80) or Color3.fromRGB(40, 40, 50); ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255); ToggleBtn.Text = text .. " [" .. (state and "ON" or "OFF") .. "]"; ToggleBtn.Font = Enum.Font.GothamSemibold; ToggleBtn.TextSize = 13; ToggleBtn.Parent = self.Container
        Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 4)
        
        ToggleBtn.MouseButton1Click:Connect(function()
            state = not state; ToggleBtn.BackgroundColor3 = state and Color3.fromRGB(40, 180, 80) or Color3.fromRGB(40, 40, 50)
            ToggleBtn.Text = text .. " [" .. (state and "ON" or "OFF") .. "]"
            callback(state)
            if getgenv().SaveSettings then getgenv().SaveSettings() end
        end)
    end

    function Tab:CreateDropdown(title, options, defaultOption, callback)
        local DropFrame = Instance.new("Frame"); DropFrame.Size = UDim2.new(1, -5, 0, 32); DropFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40); DropFrame.ClipsDescendants = true; DropFrame.Parent = self.Container
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
            MainBtn.Text = "  " .. title .. ": " .. (newOptions[1] or "Nenhum"); callback(newOptions[1] or "Nenhum") 
        end
        refresh(options); MainBtn.Text = "  " .. title .. ": " .. defaultOption; callback(defaultOption)
        return { Refresh = refresh }
    end

    function Tab:CreateTextBox(title, defaultText, callback)
        local Container = Instance.new("Frame"); Container.Size = UDim2.new(1, -5, 0, 32); Container.BackgroundColor3 = Color3.fromRGB(30, 30, 40); Container.Parent = self.Container
        Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 4)
        local Label = Instance.new("TextLabel"); Label.Size = UDim2.new(0.6, 0, 1, 0); Label.BackgroundTransparency = 1; Label.TextColor3 = Color3.fromRGB(200, 200, 200); Label.Text = "  " .. title; Label.Font = Enum.Font.GothamSemibold; Label.TextSize = 12; Label.TextXAlignment = Enum.TextXAlignment.Left; Label.Parent = Container
        local TextBox = Instance.new("TextBox"); TextBox.Size = UDim2.new(0.35, -5, 0.8, 0); TextBox.Position = UDim2.new(0.65, 0, 0.1, 0); TextBox.BackgroundColor3 = Color3.fromRGB(20, 20, 25); TextBox.TextColor3 = Color3.fromRGB(255, 255, 255); TextBox.Text = tostring(defaultText); TextBox.Font = Enum.Font.Gotham; TextBox.TextSize = 12; TextBox.Parent = Container
        Instance.new("UICorner", TextBox).CornerRadius = UDim.new(0, 4)
        TextBox.FocusLost:Connect(function() 
            local val = TextBox.Text; if tonumber(val) then callback(tonumber(val)) else callback(val) end 
            if getgenv().SaveSettings then getgenv().SaveSettings() end
        end)
    end

    return Tab
end

local UI = Library.new("Comunidade Hub V22.2 (Modularizado OOP)")

-- ABA 1: DASHBOARD
local TabDash = UI:CreateTab("Dashboard", "📊")
TabDash:CreateLabel("INFORMAÇÕES DO JOGADOR")
local InfoRace = TabDash:CreateLabel("Raça: Carregando...")
local InfoClan = TabDash:CreateLabel("Clã: Carregando...")
local InfoDamage = TabDash:CreateLabel("Bônus Melee/Sword: Carregando...")
local InfoBoss = TabDash:CreateLabel("Bônus Boss/Crit: Carregando...")
local InfoPity = TabDash:CreateLabel("Sorte: Carregando...")

task.spawn(function()
    while getgenv().isRunning and task.wait(1) do
        pcall(function()
            InfoRace.Text = "Raça Atual: " .. tostring(LP:GetAttribute("CurrentRace") or "Humano") .. " (+ " .. tostring(LP:GetAttribute("RaceExtraJumps") or 0) .. " Pulos)"
            InfoClan.Text = "Clã Atual: " .. tostring(LP:GetAttribute("CurrentClan") or "Nenhum")
            InfoDamage.Text = "Multiplicadores: Melee [" .. tostring(LP:GetAttribute("RaceMeleeDamage") or 0) .. "] | Sword [" .. tostring(LP:GetAttribute("RaceSwordDamage") or 0) .. "]"
            InfoBoss.Text = "Bônus em Bosses: Dano [" .. tostring(LP:GetAttribute("BossRush_Damage") or 0) .. "] | Crítico [" .. tostring(LP:GetAttribute("BossRush_CritDamage") or 0) .. "]"
            InfoPity.Text = "Bônus de Sorte: " .. tostring(LP:GetAttribute("RaceLuckBonus") or 0)
        end)
    end
end)

-- ABA 2: MISSÕES
local TabMissions = UI:CreateTab("Missões", "📜")
TabMissions:CreateLabel("⚡ MODO AUTO LEVEL MÁXIMO (1 AO MAX)")
TabMissions:CreateToggle("ATIVAR PILOTO AUTOMÁTICO", HubConfig.AutoFarmMaxLevel, function(v) HubConfig.AutoFarmMaxLevel = v; if v then HubConfig.AutoQuest = false end end)
TabMissions:CreateLabel("--------------------------------------------------------")
TabMissions:CreateLabel("🎯 MODO MISSÃO MANUAL (FARM DE ITENS)")
TabMissions:CreateDropdown("Escolha a Ilha", HubConfig.QuestFilterOptions, HubConfig.SelectedQuestIsland, function(s) HubConfig.SelectedQuestIsland = s; local quests = getQuestsForIsland(s); if getgenv().QuestDropdownRef then getgenv().QuestDropdownRef.Refresh(quests) end end)
local initialQuests = getQuestsForIsland(HubConfig.SelectedQuestIsland)
getgenv().QuestDropdownRef = TabMissions:CreateDropdown("Escolha a Missão", initialQuests, HubConfig.SelectedQuest or initialQuests[1], function(s) HubConfig.SelectedQuest = s end)
TabMissions:CreateToggle("FARM MISSÃO SELECIONADA", HubConfig.AutoQuest, function(v) HubConfig.AutoQuest = v; if v then HubConfig.AutoFarmMaxLevel = false end end)

-- ABA 3: COMBATE
local TabCombat = UI:CreateTab("Combate", "⚔️")
TabCombat:CreateLabel("🔍 SISTEMA DE MAPA")
TabCombat:CreateButton("Varrer Ilha (Atualizar NPCs Existentes)", function() HubConfig.AvailableMobs = getMobList(HubConfig.SelectedFilter); if getgenv().MobDropdownRef then getgenv().MobDropdownRef.Refresh(HubConfig.AvailableMobs) end end)
TabCombat:CreateDropdown("Filtrar por Área", HubConfig.FilterOptions, HubConfig.SelectedFilter, function(s) HubConfig.SelectedFilter = s; HubConfig.AvailableMobs = getMobList(s); HubConfig.Bosses = getBossList(s); if getgenv().MobDropdownRef then getgenv().MobDropdownRef.Refresh(HubConfig.AvailableMobs) end; if getgenv().BossDropdownRef then getgenv().BossDropdownRef.Refresh(HubConfig.Bosses) end end)
getgenv().MobDropdownRef = TabCombat:CreateDropdown("Inimigo", HubConfig.AvailableMobs, HubConfig.SelectedMob, function(s) HubConfig.SelectedMob = s end)
TabCombat:CreateToggle("Auto Farm Mobs", HubConfig.AutoFarm, function(v) HubConfig.AutoFarm = v end)
TabCombat:CreateLabel("--------------------------------------------------------")
TabCombat:CreateTextBox("Buscar Boss (Digite e Enter)", "", function(text)
    local currentBosses = getBossList(HubConfig.SelectedFilter); local filtered = {}; text = tostring(text):lower()
    if text == "" then filtered = currentBosses else table.insert(filtered, "Nenhum"); for _, boss in ipairs(currentBosses) do if boss ~= "Nenhum" and boss:lower():find(text) then table.insert(filtered, boss) end end end
    if getgenv().BossDropdownRef then getgenv().BossDropdownRef.Refresh(filtered) end
end)
getgenv().BossDropdownRef = TabCombat:CreateDropdown("Boss", HubConfig.Bosses, HubConfig.SelectedBoss, function(s) HubConfig.SelectedBoss = s end)
TabCombat:CreateToggle("Auto Boss", HubConfig.AutoBoss, function(v) HubConfig.AutoBoss = v end)
TabCombat:CreateToggle("Auto Training Dummy", HubConfig.AutoDummy, function(v) HubConfig.AutoDummy = v end)

TabCombat:CreateLabel("--------------------------------------------------------")
TabCombat:CreateLabel("⚙️ INTELIGÊNCIA DE COMBATE")
TabCombat:CreateDropdown("Posição de Ataque", {"Atrás", "Acima", "Abaixo", "Orbital"}, HubConfig.AttackPosition, function(s) HubConfig.AttackPosition = s end)
TabCombat:CreateTextBox("Distância do Alvo (Studs)", HubConfig.Distance, function(v) HubConfig.Distance = tonumber(v) or 5 end)

TabCombat:CreateLabel("--------------------------------------------------------")
TabCombat:CreateLabel("🗡️ ESCOLHA SUA ARMA")
TabCombat:CreateButton("Atualizar Lista de Armas no Inventário", function() HubConfig.AvailableWeapons = getWeaponList(); if getgenv().WeaponDropdownRef then getgenv().WeaponDropdownRef.Refresh(HubConfig.AvailableWeapons) end end)
getgenv().WeaponDropdownRef = TabCombat:CreateDropdown("Arma para Auto Farm", HubConfig.AvailableWeapons, HubConfig.SelectedWeapon, function(s) HubConfig.SelectedWeapon = s end)

-- ABA 4: ITENS
local TabCollect = UI:CreateTab("Itens", "🎒")
TabCollect:CreateToggle("Auto Group Reward", HubConfig.AutoGroupReward, function(v) HubConfig.AutoGroupReward = v end)
TabCollect:CreateToggle("Coletar Frutas (Map Scan)", HubConfig.AutoCollect.Fruits, function(v) HubConfig.AutoCollect.Fruits = v end)
TabCollect:CreateToggle("Coletar Hogyoku", HubConfig.AutoCollect.Hogyoku, function(v) HubConfig.AutoCollect.Hogyoku = v end)
TabCollect:CreateToggle("Coletar Puzzles", HubConfig.AutoCollect.Puzzles, function(v) HubConfig.AutoCollect.Puzzles = v end)
TabCollect:CreateToggle("Coletar Baús do Chão", HubConfig.AutoCollect.Chests, function(v) HubConfig.AutoCollect.Chests = v end)

-- ABA 5: STATUS
local TabStats = UI:CreateTab("Status", "📈")
local InfoPoints = TabStats:CreateLabel("Pontos Disponíveis: Carregando...")
TabStats:CreateLabel("--------------------------------------------------------")
TabStats:CreateLabel("DISTRIBUIÇÃO MANUAL")
TabStats:CreateDropdown("Atributo", HubConfig.StatsList, HubConfig.ManualStat, function(s) HubConfig.ManualStat = s end)
TabStats:CreateTextBox("Quantidade", HubConfig.ManualAmount, function(v) HubConfig.ManualAmount = tonumber(v) or 1 end)
TabStats:CreateButton("➕ Adicionar Pontos", function() if AllocateStatRemote then AllocateStatRemote:FireServer(HubConfig.ManualStat, HubConfig.ManualAmount) end end, Color3.fromRGB(40, 150, 80))
TabStats:CreateLabel("--------------------------------------------------------")
TabStats:CreateLabel("DISTRIBUIÇÃO AUTOMÁTICA (DIVISÃO)")
for _, stat in ipairs(HubConfig.StatsList) do
    local isSelected = table.find(HubConfig.SelectedStats, stat) ~= nil
    TabStats:CreateToggle("Auto Upar " .. stat, isSelected, function(v) if v then if not table.find(HubConfig.SelectedStats, stat) then table.insert(HubConfig.SelectedStats, stat) end else local idx = table.find(HubConfig.SelectedStats, stat); if idx then table.remove(HubConfig.SelectedStats, idx) end end end)
end
TabStats:CreateLabel("--------------------------------------------------------")
TabStats:CreateToggle("Ativar Auto Distribuir", HubConfig.AutoStats, function(v) HubConfig.AutoStats = v end)
TabStats:CreateButton("🔄 Reset Status", function() if ResetStatsRemote then ResetStatsRemote:FireServer() end end, Color3.fromRGB(200, 60, 60))
task.spawn(function() while getgenv().isRunning and task.wait(1) do pcall(function() local data = LP:FindFirstChild("Data"); if data and data:FindFirstChild("StatPoints") then InfoPoints.Text = "Pontos Disponíveis: " .. tostring(data.StatPoints.Value) else InfoPoints.Text = "Pontos Disponíveis: 0" end end) end end)

-- ABA 6: ROLETA
local TabRoleta = UI:CreateTab("Roleta", "🎲")
TabRoleta:CreateTextBox("Raça Sniper", HubConfig.AutoReroll.TargetRace, function(v) HubConfig.AutoReroll.TargetRace = tostring(v) end)
TabRoleta:CreateToggle("Iniciar Sniper Raça", HubConfig.AutoReroll.Race, function(v) HubConfig.AutoReroll.Race = v end)
TabRoleta:CreateToggle("Abrir Todos Baús", HubConfig.AutoOpenChests.Common, function(v) HubConfig.AutoOpenChests.Common = v; HubConfig.AutoOpenChests.Rare = v; HubConfig.AutoOpenChests.Epic = v; HubConfig.AutoOpenChests.Mythical = v end)

-- ABA 7: MUNDO
local TabWorld = UI:CreateTab("Mundo", "🌍")
local MundoPronto = false 
TabWorld:CreateLabel("PORTAIS INSTANTÂNEOS")
TabWorld:CreateDropdown("Viajar para Ilha", HubConfig.Islands, "Starter", function(s) if MundoPronto and TeleportRemote then TeleportRemote:FireServer(s) end end)
TabWorld:CreateLabel("IR ATÉ NPC (VOANDO)")
TabWorld:CreateDropdown("Selecione o NPC", HubConfig.NPCs, "EnchantNPC", function(s) if MundoPronto then local npc = Workspace:FindFirstChild("ServiceNPCs") and Workspace.ServiceNPCs:FindFirstChild(s); if npc and npc:FindFirstChild("HumanoidRootPart") then unfreezeCharacter(LP.Character); SafeTeleport(npc.HumanoidRootPart.Position + Vector3.new(0, 0, 5)) end end end)
MundoPronto = true

-- ABA 8: NATIVOS
local TabNativos = UI:CreateTab("Nativos", "🕵️‍♂️")
TabNativos:CreateLabel("HACKS NATIVOS (Indetectáveis)")
TabNativos:CreateToggle("Haki do Armamento", HubConfig.HacksNativos.HakiArmamento, function(v) HubConfig.HacksNativos.HakiArmamento = v; pcall(function() LP:SetAttribute("AutoArmHaki", v) end) end)
TabNativos:CreateToggle("Haki da Observação", HubConfig.HacksNativos.HakiObservacao, function(v) HubConfig.HacksNativos.HakiObservacao = v; pcall(function() LP:SetAttribute("AutoObsHaki", v) end) end)
TabNativos:CreateToggle("Hack de Pulos Extras", HubConfig.HacksNativos.PuloExtra, function(v) HubConfig.HacksNativos.PuloExtra = v; if not v then pcall(function() LP:SetAttribute("RaceExtraJumps", 0) end) end end)

-- ABA 9: FRUIT SNIPER
local TabSniper = UI:CreateTab("Fruit V2", "🍎")
TabSniper:CreateToggle("Sniper de Frutas Instantâneo", HubConfig.FruitSniper, function(v) HubConfig.FruitSniper = v end)

-- ABA 10: MISC
local TabMisc = UI:CreateTab("Misc", "⚙️")
TabMisc:CreateToggle("Super Velocidade", HubConfig.SuperSpeed, function(v) HubConfig.SuperSpeed = v end)
TabMisc:CreateToggle("Pulo Infinito", HubConfig.InfJump, function(v) HubConfig.InfJump = v end)

print("✅ Comunidade Hub - Interface OOP Carregada!")
