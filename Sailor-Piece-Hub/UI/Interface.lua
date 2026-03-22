local Interface = {}
Interface.__index = Interface

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

function Interface.new(Config, FSM, Constants)
    local self = setmetatable({}, Interface)
    self.Config = Config
    self.FSM = FSM
    self.Constants = Constants
    self.Connections = {}
    self.Tabs = {}
    self.ActiveTabBtn = nil

    self:BuildUI()
    return self
end

function Interface:Destroy()
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
    for _, conn in ipairs(self.Connections) do
        if conn then conn:Disconnect() end
    end
    self.Connections = {}
end

function Interface:BuildUI()
    if CoreGui:FindFirstChild("ComunidadeHubUI") then
        CoreGui.ComunidadeHubUI:Destroy()
    end

    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "ComunidadeHubUI"
    self.ScreenGui.Parent = CoreGui
    self.ScreenGui.ResetOnSpawn = false

    local Theme = {
        Background = Color3.fromRGB(20, 20, 20),
        Sidebar = Color3.fromRGB(30, 30, 30),
        Component = Color3.fromRGB(40, 40, 40),
        Accent = Color3.fromRGB(0, 195, 255),
        Text = Color3.fromRGB(255, 255, 255),
        TextDim = Color3.fromRGB(150, 150, 150),
        Red = Color3.fromRGB(200, 50, 50)
    }

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 600, 0, 400)
    MainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
    MainFrame.BackgroundColor3 = Theme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = self.ScreenGui
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.BackgroundTransparency = 1
    Title.Text = "  SAILOR PIECE HUB"
    Title.TextColor3 = Theme.Accent
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 18
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = MainFrame

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 40, 0, 40)
    CloseBtn.Position = UDim2.new(1, -40, 0, 0)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Theme.Red
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 18
    CloseBtn.Parent = MainFrame
    CloseBtn.MouseButton1Click:Connect(function()
        self.Config.IsRunning = false
        if _G.ComunidadeHub_Cleanup then _G.ComunidadeHub_Cleanup() end
    end)

    local Sidebar = Instance.new("ScrollingFrame")
    Sidebar.Size = UDim2.new(0, 160, 1, -40)
    Sidebar.Position = UDim2.new(0, 0, 0, 40)
    Sidebar.BackgroundColor3 = Theme.Sidebar
    Sidebar.BorderSizePixel = 0
    Sidebar.ScrollBarThickness = 2
    Sidebar.Parent = MainFrame
    local SidebarLayout = Instance.new("UIListLayout")
    SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    SidebarLayout.Parent = Sidebar

    local ContentArea = Instance.new("Frame")
    ContentArea.Size = UDim2.new(1, -160, 1, -40)
    ContentArea.Position = UDim2.new(0, 160, 0, 40)
    ContentArea.BackgroundTransparency = 1
    ContentArea.Parent = MainFrame

    local function CreateTab(name)
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1, 0, 0, 40)
        tabBtn.BackgroundColor3 = Theme.Sidebar
        tabBtn.BorderSizePixel = 0
        tabBtn.Text = name
        tabBtn.TextColor3 = Theme.TextDim
        tabBtn.Font = Enum.Font.GothamSemibold
        tabBtn.TextSize = 14
        tabBtn.Parent = Sidebar

        local page = Instance.new("ScrollingFrame")
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.ScrollBarThickness = 4
        page.Visible = false
        page.Parent = ContentArea
        local pageLayout = Instance.new("UIListLayout")
        pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pageLayout.Padding = UDim.new(0, 8)
        pageLayout.Parent = page
        local pagePadding = Instance.new("UIPadding")
        pagePadding.PaddingTop = UDim.new(0, 10)
        pagePadding.PaddingLeft = UDim.new(0, 10)
        pagePadding.PaddingRight = UDim.new(0, 15)
        pagePadding.PaddingBottom = UDim.new(0, 10)
        pagePadding.Parent = page

        tabBtn.MouseButton1Click:Connect(function()
            if self.ActiveTabBtn then
                self.ActiveTabBtn.TextColor3 = Theme.TextDim
                self.ActiveTabBtn.BackgroundColor3 = Theme.Sidebar
                self.Tabs[self.ActiveTabBtn.Text].Visible = false
            end
            tabBtn.TextColor3 = Theme.Accent
            tabBtn.BackgroundColor3 = Theme.Component
            page.Visible = true
            self.ActiveTabBtn = tabBtn
        end)

        self.Tabs[name] = page
        return page
    end

    local function CreateToggle(parent, text, configKey, subTable)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 35)
        frame.BackgroundColor3 = Theme.Component
        frame.Parent = parent
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -60, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Theme.Text
        label.Font = Enum.Font.Gotham
        label.TextSize = 14
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 40, 0, 20)
        btn.Position = UDim2.new(1, -50, 0.5, -10)
        btn.BackgroundColor3 = Theme.Background
        btn.Text = ""
        btn.Parent = frame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

        local indicator = Instance.new("Frame")
        indicator.Size = UDim2.new(0, 16, 0, 16)
        
        local defaultState = false
        if subTable then defaultState = self.Config[subTable][configKey] else defaultState = self.Config[configKey] end
        
        indicator.Position = defaultState and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        indicator.BackgroundColor3 = defaultState and Theme.Accent or Theme.Red
        indicator.Parent = btn
        Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 4)

        local state = defaultState

        btn.MouseButton1Click:Connect(function()
            state = not state
            if subTable then
                self.Config[subTable][configKey] = state
            else
                self.Config[configKey] = state
            end

            if state then
                TweenService:Create(indicator, TweenInfo.new(0.2), {Position = UDim2.new(1, -18, 0.5, -8), BackgroundColor3 = Theme.Accent}):Play()
            else
                TweenService:Create(indicator, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -8), BackgroundColor3 = Theme.Red}):Play()
            end
        end)
    end

    local function CreateSlider(parent, text, min, max, configKey)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 50)
        frame.BackgroundColor3 = Theme.Component
        frame.Parent = parent
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -60, 0, 20)
        label.Position = UDim2.new(0, 10, 0, 5)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Theme.Text
        label.Font = Enum.Font.Gotham
        label.TextSize = 14
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame

        local valLabel = Instance.new("TextLabel")
        valLabel.Size = UDim2.new(0, 40, 0, 20)
        valLabel.Position = UDim2.new(1, -50, 0, 5)
        valLabel.BackgroundTransparency = 1
        valLabel.Text = tostring(self.Config[configKey] or min)
        valLabel.TextColor3 = Theme.Accent
        valLabel.Font = Enum.Font.GothamBold
        valLabel.TextSize = 14
        valLabel.TextXAlignment = Enum.TextXAlignment.Right
        valLabel.Parent = frame

        local sliderBG = Instance.new("TextButton")
        sliderBG.Size = UDim2.new(1, -20, 0, 8)
        sliderBG.Position = UDim2.new(0, 10, 0, 32)
        sliderBG.BackgroundColor3 = Theme.Background
        sliderBG.Text = ""
        sliderBG.AutoButtonColor = false
        sliderBG.Parent = frame
        Instance.new("UICorner", sliderBG).CornerRadius = UDim.new(0, 4)

        local initialRel = ((self.Config[configKey] or min) - min) / (max - min)
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(initialRel, 0, 1, 0)
        fill.BackgroundColor3 = Theme.Accent
        fill.Parent = sliderBG
        Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)

        local dragging = false
        local function updateSlider(input)
            local relX = math.clamp((input.Position.X - sliderBG.AbsolutePosition.X) / sliderBG.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + (max - min) * relX)
            fill.Size = UDim2.new(relX, 0, 1, 0)
            valLabel.Text = tostring(val)
            self.Config[configKey] = val
        end

        sliderBG.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true; updateSlider(input)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then updateSlider(input) end
        end)
    end

    local function CreateDropdown(parent, text, options, configKey, isTableConfig)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 35)
        frame.BackgroundColor3 = Theme.Component
        frame.ClipsDescendants = true
        frame.Parent = parent
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 35)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.Parent = frame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.5, -10, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Theme.Text
        label.Font = Enum.Font.Gotham
        label.TextSize = 14
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame

        local selectedLabel = Instance.new("TextLabel")
        selectedLabel.Size = UDim2.new(0.5, -30, 1, 0)
        selectedLabel.Position = UDim2.new(0.5, 0, 0, 0)
        selectedLabel.BackgroundTransparency = 1
        
        local initialVal = isTableConfig and (self.Config[configKey][1] or "Nenhum") or (self.Config[configKey] or "Nenhum")
        selectedLabel.Text = tostring(initialVal)
        
        selectedLabel.TextColor3 = Theme.Accent
        selectedLabel.Font = Enum.Font.GothamBold
        selectedLabel.TextSize = 12
        selectedLabel.TextXAlignment = Enum.TextXAlignment.Right
        selectedLabel.Parent = frame

        local icon = Instance.new("TextLabel")
        icon.Size = UDim2.new(0, 20, 1, 0)
        icon.Position = UDim2.new(1, -25, 0, 0)
        icon.BackgroundTransparency = 1
        icon.Text = "▼"
        icon.TextColor3 = Theme.TextDim
        icon.Font = Enum.Font.Gotham
        icon.TextSize = 14
        icon.Parent = frame

        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.new(1, 0, 0, 120)
        scroll.Position = UDim2.new(0, 0, 0, 35)
        scroll.BackgroundTransparency = 1
        scroll.ScrollBarThickness = 2
        scroll.Parent = frame
        local scrollLayout = Instance.new("UIListLayout")
        scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
        scrollLayout.Parent = scroll

        local expanded = false
        btn.MouseButton1Click:Connect(function()
            expanded = not expanded
            icon.Text = expanded and "▲" or "▼"
            TweenService:Create(frame, TweenInfo.new(0.2), {Size = expanded and UDim2.new(1, 0, 0, 155) or UDim2.new(1, 0, 0, 35)}):Play()
        end)

        local function Populate(newOptions)
            for _, child in ipairs(scroll:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end
            for _, opt in ipairs(newOptions) do
                local optBtn = Instance.new("TextButton")
                optBtn.Size = UDim2.new(1, 0, 0, 30)
                optBtn.BackgroundColor3 = Theme.Background
                optBtn.BorderSizePixel = 0
                optBtn.Text = tostring(opt)
                optBtn.TextColor3 = Theme.TextDim
                optBtn.Font = Enum.Font.Gotham
                optBtn.TextSize = 13
                optBtn.Parent = scroll
                optBtn.MouseButton1Click:Connect(function()
                    selectedLabel.Text = tostring(opt)
                    if isTableConfig then
                        self.Config[configKey] = {opt}
                    else
                        self.Config[configKey] = opt
                    end
                    expanded = false
                    icon.Text = "▼"
                    TweenService:Create(frame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 35)}):Play()
                end)
            end
            scroll.CanvasSize = UDim2.new(0, 0, 0, #newOptions * 30)
        end
        Populate(options)
        return Populate
    end

    -- Abas e Conteúdos
    local pageMain = CreateTab("Principal (Farm)")
    CreateToggle(pageMain, "Auto Farm Max Level", "AutoFarmMaxLevel")
    CreateToggle(pageMain, "Auto Farm Mob", "AutoFarm")
    
    local allMobs = {"Nenhum", "Todos"}
    for _, islandData in pairs(self.Constants.IslandDataMap) do
        if islandData.Mobs then
            for _, mob in ipairs(islandData.Mobs) do table.insert(allMobs, mob) end
        end
    end
    CreateDropdown(pageMain, "Selecionar Mob", allMobs, "SelectedMob")
    
    CreateToggle(pageMain, "Auto Boss", "AutoBoss")
    local allBosses = {"Nenhum"}
    for _, islandData in pairs(self.Constants.IslandDataMap) do
        if islandData.Bosses then
            for _, boss in ipairs(islandData.Bosses) do table.insert(allBosses, boss) end
        end
    end
    CreateDropdown(pageMain, "Selecionar Boss", allBosses, "SelectedBosses", true)
    CreateToggle(pageMain, "Auto Dummy", "AutoDummy")

    local pageCombat = CreateTab("Combate & Config")
    CreateDropdown(pageCombat, "Posição de Ataque", {"Atrás", "Acima", "Abaixo", "Orbital"}, "AttackPosition")
    CreateSlider(pageCombat, "Distância de Ataque", 1, 50, "Distance")
    CreateSlider(pageCombat, "Velocidade do Voo", 50, 400, "TweenSpeed")

    local pageQuest = CreateTab("Missões")
    CreateToggle(pageQuest, "Auto Quest Manual", "AutoQuest")
    local questIslands = {}
    for island, _ in pairs(self.Constants.QuestDataMap) do table.insert(questIslands, island) end
    local updateQuests = CreateDropdown(pageQuest, "Ilha da Missão", questIslands, "SelectedQuestIsland")
    CreateDropdown(pageQuest, "Nome da Missão", {"Nenhum"}, "SelectedQuest") 

    local pageItems = CreateTab("Coleta & Itens")
    CreateToggle(pageItems, "Fruit Sniper (Imediato)", "FruitSniper")
    CreateToggle(pageItems, "Coletar Frutas", "Fruits", "AutoCollect")
    CreateToggle(pageItems, "Coletar Hogyokus", "Hogyoku", "AutoCollect")
    CreateToggle(pageItems, "Coletar Puzzles", "Puzzles", "AutoCollect")
    CreateToggle(pageItems, "Coletar Baús", "Chests", "AutoCollect")

    local pageGacha = CreateTab("Status & Gacha")
    CreateToggle(pageGacha, "Auto Distribuir Status", "AutoStats")
    CreateDropdown(pageGacha, "Status para Focar", self.Constants.StatsList, "SelectedStats", true)
    CreateToggle(pageGacha, "Auto Reroll Raça", "Race", "AutoReroll")
    CreateDropdown(pageGacha, "Raça Desejada", {"Kitsune", "Mink", "Fishman", "Human", "Skypiean"}, "TargetRace", "AutoReroll")
    CreateToggle(pageGacha, "Auto Reroll Clã", "Clan", "AutoReroll")
    CreateDropdown(pageGacha, "Clã Desejado", {"Gojo", "Zenith", "Yeager"}, "TargetClan", "AutoReroll")
    CreateSlider(pageGacha, "Baús Abertos por Vez", 1, 10, "ChestOpenAmount")
    CreateToggle(pageGacha, "Abrir Baú Comum", "Common", "AutoOpenChests")
    CreateToggle(pageGacha, "Abrir Baú Raro", "Rare", "AutoOpenChests")
    CreateToggle(pageGacha, "Abrir Baú Épico", "Epic", "AutoOpenChests")
    CreateToggle(pageGacha, "Abrir Baú Lendário", "Legendary", "AutoOpenChests")

    local pageMisc = CreateTab("Miscelânea")
    CreateToggle(pageMisc, "Super Velocidade", "SuperSpeed")
    CreateSlider(pageMisc, "Velocidade", 1, 10, "SpeedMultiplier")
    CreateToggle(pageMisc, "Pulo Infinito", "InfJump")
    CreateToggle(pageMisc, "Haki do Armamento", "HakiArmamento", "HacksNativos")
    CreateToggle(pageMisc, "Haki da Observação", "HakiObservacao", "HacksNativos")
    CreateToggle(pageMisc, "Remover Cutscenes", "NoCutscene", "HacksNativos")

    for _, btn in ipairs(Sidebar:GetChildren()) do
        if btn:IsA("TextButton") then
            btn.TextColor3 = Theme.Accent
            btn.BackgroundColor3 = Theme.Component
            self.Tabs[btn.Text].Visible = true
            self.ActiveTabBtn = btn
            break
        end
    end
end

return Interface
