-- =====================================================================
-- 🎨 UI/Interface.lua (Arquitetura OOP, Sem getgenv)
-- =====================================================================

local Interface = {}
Interface.__index = Interface

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

-- =====================================================================
-- 🎨 TEMA VISUAL PREMIUM
-- =====================================================================
local Theme = {
    Background = Color3.fromRGB(20, 20, 25),
    Sidebar = Color3.fromRGB(28, 28, 35),
    Component = Color3.fromRGB(35, 35, 45),
    Accent = Color3.fromRGB(0, 195, 255),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(160, 160, 170),
    Green = Color3.fromRGB(40, 180, 80),
    Red = Color3.fromRGB(220, 60, 60)
}

-- =====================================================================
-- 🌟 CONSTRUTOR DA CLASSE
-- =====================================================================
function Interface.new(Config, FSM, Constants)
    local self = setmetatable({}, Interface)
    
    -- Injeção de Dependências
    self.Config = Config
    self.FSM = FSM
    self.Constants = Constants
    
    self.Connections = {}
    self.Tabs = {}
    self.CurrentTab = nil
    
    self:BuildUI()
    return self
end

-- =====================================================================
-- 🧹 GARBAGE COLLECTION E DESTRUIÇÃO
-- =====================================================================
function Interface:Destroy()
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
    for _, conn in ipairs(self.Connections) do
        if conn then conn:Disconnect() end
    end
    self.Connections = {}
end

-- =====================================================================
-- 📢 SISTEMA DE NOTIFICAÇÃO INTERNO
-- =====================================================================
function Interface:Notify(title, text, duration)
    duration = duration or 3 
    local Notif = Instance.new("Frame")
    Notif.Size = UDim2.new(1, 0, 0, 65)
    Notif.BackgroundColor3 = Theme.Component
    Notif.BackgroundTransparency = 1 
    Instance.new("UICorner", Notif).CornerRadius = UDim.new(0, 6)
    
    local SideBar = Instance.new("Frame")
    SideBar.Size = UDim2.new(0, 4, 1, 0)
    SideBar.BackgroundColor3 = Theme.Accent
    SideBar.BorderSizePixel = 0
    SideBar.BackgroundTransparency = 1
    SideBar.Parent = Notif
    Instance.new("UICorner", SideBar).CornerRadius = UDim.new(0, 6)
    
    local TitleLbl = Instance.new("TextLabel")
    TitleLbl.Size = UDim2.new(1, -20, 0, 20)
    TitleLbl.Position = UDim2.new(0, 15, 0, 5)
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.Text = title
    TitleLbl.TextColor3 = Theme.Text
    TitleLbl.TextTransparency = 1
    TitleLbl.Font = Enum.Font.GothamBold
    TitleLbl.TextSize = 13
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    TitleLbl.Parent = Notif

    local DescLbl = Instance.new("TextLabel")
    DescLbl.Size = UDim2.new(1, -20, 0, 35)
    DescLbl.Position = UDim2.new(0, 15, 0, 25)
    DescLbl.BackgroundTransparency = 1
    DescLbl.Text = text
    DescLbl.TextColor3 = Theme.TextDim
    DescLbl.TextTransparency = 1
    DescLbl.Font = Enum.Font.Gotham
    DescLbl.TextSize = 12
    DescLbl.TextWrapped = true
    DescLbl.TextXAlignment = Enum.TextXAlignment.Left
    DescLbl.Parent = Notif

    Notif.Parent = self.NotifyFrame

    TweenService:Create(Notif, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
    TweenService:Create(SideBar, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
    TweenService:Create(TitleLbl, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
    TweenService:Create(DescLbl, TweenInfo.new(0.3), {TextTransparency = 0}):Play()

    task.spawn(function()
        task.wait(duration)
        local fadeOut = TweenService:Create(Notif, TweenInfo.new(0.5), {BackgroundTransparency = 1})
        TweenService:Create(SideBar, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
        TweenService:Create(TitleLbl, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
        TweenService:Create(DescLbl, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
        fadeOut:Play()
        fadeOut.Completed:Wait()
        Notif:Destroy()
    end)
end

-- =====================================================================
-- 🛠️ COMPONENTES DA INTERFACE
-- =====================================================================
function Interface:CreateTab(name, icon)
    local Tab = { Window = self }
    
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(1, 0, 0, 40)
    TabBtn.BackgroundColor3 = Theme.Background
    TabBtn.BorderSizePixel = 0
    TabBtn.TextColor3 = Theme.TextDim
    TabBtn.Text = "  " .. (icon or "") .. " " .. name
    TabBtn.Font = Enum.Font.GothamSemibold
    TabBtn.TextSize = 13
    TabBtn.TextXAlignment = Enum.TextXAlignment.Left
    TabBtn.Parent = self.TabSelector
    TabBtn.AutoButtonColor = false 
    
    local TabContent = Instance.new("ScrollingFrame")
    TabContent.Size = UDim2.new(1, -10, 1, -10)
    TabContent.Position = UDim2.new(0, 5, 0, 5)
    TabContent.BackgroundTransparency = 1
    TabContent.ScrollBarThickness = 2
    TabContent.Visible = false
    TabContent.Parent = self.ContentContainer
    
    local ContentLayout = Instance.new("UIListLayout")
    ContentLayout.Parent = TabContent
    ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ContentLayout.Padding = UDim.new(0, 10) 
    
    table.insert(self.Connections, ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() 
        TabContent.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 10) 
    end))

    table.insert(self.Connections, TabBtn.MouseEnter:Connect(function() if self.CurrentTab ~= TabContent then TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Sidebar}):Play() end end))
    table.insert(self.Connections, TabBtn.MouseLeave:Connect(function() if self.CurrentTab ~= TabContent then TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Background}):Play() end end))

    table.insert(self.Connections, TabBtn.MouseButton1Click:Connect(function()
        for _, tabInfo in pairs(self.Tabs) do 
            tabInfo.Content.Visible = false
            TweenService:Create(tabInfo.Button, TweenInfo.new(0.3), {BackgroundColor3 = Theme.Background, TextColor3 = Theme.TextDim}):Play()
        end
        TabContent.Visible = true
        self.CurrentTab = TabContent
        TweenService:Create(TabBtn, TweenInfo.new(0.3), {BackgroundColor3 = Theme.Component, TextColor3 = Theme.Accent}):Play()
    end))

    if not self.CurrentTab then 
        TabContent.Visible = true
        TabBtn.BackgroundColor3 = Theme.Component
        TabBtn.TextColor3 = Theme.Accent
        self.CurrentTab = TabContent 
    end
    table.insert(self.Tabs, {Button = TabBtn, Content = TabContent})
    Tab.Container = TabContent

    function Tab:CreateLabel(text)
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, 0, 0, 20)
        Label.BackgroundTransparency = 1
        Label.TextColor3 = Theme.Accent
        Label.Text = text
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Font = Enum.Font.GothamBold
        Label.TextSize = 12
        Label.Parent = self.Container
        return Label
    end

    function Tab:CreateButton(text, callback, customColor)
        local color = customColor or Theme.Sidebar
        local Btn = Instance.new("TextButton")
        Btn.Size = UDim2.new(1, -10, 0, 35)
        Btn.BackgroundColor3 = color
        Btn.TextColor3 = Theme.Text
        Btn.Text = text
        Btn.Font = Enum.Font.GothamSemibold
        Btn.TextSize = 13
        Btn.Parent = self.Container
        Btn.AutoButtonColor = false
        Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
        
        table.insert(Tab.Window.Connections, Btn.MouseEnter:Connect(function() TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(math.clamp(color.R*255 + 20, 0, 255), math.clamp(color.G*255 + 20, 0, 255), math.clamp(color.B*255 + 20, 0, 255))}):Play() end))
        table.insert(Tab.Window.Connections, Btn.MouseLeave:Connect(function() TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play() end))
        table.insert(Tab.Window.Connections, Btn.MouseButton1Click:Connect(function() callback() end))
        return Btn
    end

    function Tab:CreateToggle(text, defaultState, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 38)
        frame.BackgroundColor3 = Theme.Component
        frame.Parent = self.Container
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -60, 1, 0)
        label.Position = UDim2.new(0, 15, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Theme.Text
        label.Font = Enum.Font.Gotham
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 44, 0, 22)
        btn.Position = UDim2.new(1, -55, 0.5, -11)
        btn.BackgroundColor3 = Theme.Background
        btn.Text = ""
        btn.Parent = frame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 11)

        local indicator = Instance.new("Frame")
        indicator.Size = UDim2.new(0, 18, 0, 18)
        local state = defaultState and true or false
        
        indicator.Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        indicator.BackgroundColor3 = state and Theme.Green or Theme.Red
        indicator.Parent = btn
        Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 9)

        table.insert(Tab.Window.Connections, btn.MouseButton1Click:Connect(function()
            state = not state
            if state then
                TweenService:Create(indicator, TweenInfo.new(0.2), {Position = UDim2.new(1, -20, 0.5, -9), BackgroundColor3 = Theme.Green}):Play()
            else
                TweenService:Create(indicator, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -9), BackgroundColor3 = Theme.Red}):Play()
            end
            callback(state)
            if typeof(Tab.Window.Config.Save) == "function" then Tab.Window.Config:Save() end
        end))
    end

    function Tab:CreateDropdown(title, options, defaultOption, callback)
        options = options or {"Nenhum"}
        defaultOption = defaultOption or options[1] or "Nenhum"

        local DropFrame = Instance.new("Frame")
        DropFrame.Size = UDim2.new(1, -10, 0, 40)
        DropFrame.BackgroundColor3 = Theme.Component
        DropFrame.ClipsDescendants = true
        DropFrame.Parent = self.Container
        Instance.new("UICorner", DropFrame).CornerRadius = UDim.new(0, 6)
        
        local MainBtn = Instance.new("TextButton")
        MainBtn.Size = UDim2.new(1, 0, 0, 40)
        MainBtn.BackgroundTransparency = 1
        MainBtn.TextColor3 = Theme.Text
        MainBtn.Text = "  " .. title .. ": " .. tostring(defaultOption)
        MainBtn.Font = Enum.Font.GothamSemibold
        MainBtn.TextSize = 13
        MainBtn.TextXAlignment = Enum.TextXAlignment.Left
        MainBtn.Parent = DropFrame
        
        local Arrow = Instance.new("TextLabel")
        Arrow.Size = UDim2.new(0, 30, 1, 0)
        Arrow.Position = UDim2.new(1, -30, 0, 0)
        Arrow.BackgroundTransparency = 1
        Arrow.Text = "▼"
        Arrow.TextColor3 = Theme.TextDim
        Arrow.Font = Enum.Font.GothamBold
        Arrow.Parent = MainBtn

        local ListFrame = Instance.new("ScrollingFrame")
        ListFrame.Size = UDim2.new(1, 0, 1, -40)
        ListFrame.Position = UDim2.new(0, 0, 0, 40)
        ListFrame.BackgroundTransparency = 1
        ListFrame.ScrollBarThickness = 2
        ListFrame.Parent = DropFrame
        local ListLayout = Instance.new("UIListLayout"); ListLayout.Parent = ListFrame
        local isOpen = false

        local function updateSelection(opt)
            MainBtn.Text = "  " .. title .. ": " .. tostring(opt)
            callback(opt)
            isOpen = false
            TweenService:Create(DropFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, -10, 0, 40)}):Play()
            Arrow.Text = "▼"
            if typeof(Tab.Window.Config.Save) == "function" then Tab.Window.Config:Save() end
        end

        table.insert(Tab.Window.Connections, MainBtn.MouseButton1Click:Connect(function()
            isOpen = not isOpen
            local targetHeight = isOpen and math.min(ListLayout.AbsoluteContentSize.Y + 40, 160) or 40
            TweenService:Create(DropFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, -10, 0, targetHeight)}):Play()
            Arrow.Text = isOpen and "▲" or "▼"
            ListFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y)
        end))

        local function refresh(newOptions)
            newOptions = newOptions or {"Nenhum"}
            if #newOptions == 0 then newOptions = {"Nenhum"} end
            for _, b in pairs(ListFrame:GetChildren()) do if b:IsA("TextButton") then b:Destroy() end end
            
            for _, opt in ipairs(newOptions) do
                local OptBtn = Instance.new("TextButton")
                OptBtn.Size = UDim2.new(1, 0, 0, 30)
                OptBtn.BackgroundColor3 = Theme.Sidebar
                OptBtn.TextColor3 = Theme.TextDim
                OptBtn.Text = "  " .. tostring(opt)
                OptBtn.Font = Enum.Font.Gotham
                OptBtn.TextSize = 13
                OptBtn.TextXAlignment = Enum.TextXAlignment.Left
                OptBtn.Parent = ListFrame
                OptBtn.AutoButtonColor = false
                
                table.insert(Tab.Window.Connections, OptBtn.MouseEnter:Connect(function() TweenService:Create(OptBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Component, TextColor3 = Theme.Accent}):Play() end))
                table.insert(Tab.Window.Connections, OptBtn.MouseLeave:Connect(function() TweenService:Create(OptBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Sidebar, TextColor3 = Theme.TextDim}):Play() end))
                table.insert(Tab.Window.Connections, OptBtn.MouseButton1Click:Connect(function() updateSelection(opt) end))
            end
            
            local safeOpt = newOptions[1] or "Nenhum"
            MainBtn.Text = "  " .. title .. ": " .. tostring(safeOpt)
            callback(safeOpt)
        end
        refresh(options)
        MainBtn.Text = "  " .. title .. ": " .. tostring(defaultOption)
        return { Refresh = refresh }
    end

    function Tab:CreateTextBox(title, defaultText, callback)
        local Container = Instance.new("Frame")
        Container.Size = UDim2.new(1, -10, 0, 40)
        Container.BackgroundColor3 = Theme.Component
        Container.Parent = self.Container
        Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 6)
        
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(0.6, 0, 1, 0)
        Label.Position = UDim2.new(0, 15, 0, 0)
        Label.BackgroundTransparency = 1
        Label.TextColor3 = Theme.Text
        Label.Text = "  " .. title
        Label.Font = Enum.Font.GothamSemibold
        Label.TextSize = 13
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Container
        
        local TextBox = Instance.new("TextBox")
        TextBox.Size = UDim2.new(0.35, -5, 0.7, 0)
        TextBox.Position = UDim2.new(0.65, 0, 0.15, 0)
        TextBox.BackgroundColor3 = Theme.Background
        TextBox.TextColor3 = Theme.Accent
        TextBox.Text = tostring(defaultText)
        TextBox.Font = Enum.Font.Gotham
        TextBox.TextSize = 13
        TextBox.Parent = Container
        Instance.new("UICorner", TextBox).CornerRadius = UDim.new(0, 4)
        
        table.insert(Tab.Window.Connections, TextBox.FocusLost:Connect(function() 
            local val = TextBox.Text
            if tonumber(val) then callback(tonumber(val)) else callback(val) end 
            if typeof(Tab.Window.Config.Save) == "function" then Tab.Window.Config:Save() end
        end))
    end

    return Tab
end

-- =====================================================================
-- 🚀 CONSTRUÇÃO PRINCIPAL DA INTERFACE (Apenas na chamada do Bootstrapper)
-- =====================================================================
function Interface:BuildUI()
    local uiParent = pcall(function() return CoreGui.Name end) and CoreGui or LP:WaitForChild("PlayerGui")
    if uiParent:FindFirstChild("ComunidadeHubGUI") then uiParent.ComunidadeHubGUI:Destroy() end
    
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "ComunidadeHubGUI"
    self.ScreenGui.Parent = uiParent
    self.ScreenGui.ResetOnSpawn = false
    
    -- Main Frame
    self.MainFrame = Instance.new("Frame")
    self.MainFrame.Size = UDim2.new(0, 580, 0, 480)
    self.MainFrame.Position = UDim2.new(0.5, -290, 0.5, -240)
    self.MainFrame.BackgroundColor3 = Theme.Background
    self.MainFrame.ClipsDescendants = true
    self.MainFrame.Parent = self.ScreenGui
    Instance.new("UICorner", self.MainFrame).CornerRadius = UDim.new(0, 8)
    
    -- Title Bar
    local TitleBar = Instance.new("TextButton")
    TitleBar.Size = UDim2.new(1, 0, 0, 45)
    TitleBar.BackgroundColor3 = Theme.Sidebar
    TitleBar.TextColor3 = Theme.Accent
    TitleBar.Text = "   🌟 Sailor Piece Hub V2"
    TitleBar.Font = Enum.Font.GothamBold
    TitleBar.TextSize = 16
    TitleBar.TextXAlignment = Enum.TextXAlignment.Left
    TitleBar.Parent = self.MainFrame
    TitleBar.AutoButtonColor = false
    Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 8)
    
    -- Drag Logic
    local dragging, dragInput, dragStart, startPos
    table.insert(self.Connections, TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; startPos = self.MainFrame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end))
    table.insert(self.Connections, TitleBar.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end))
    table.insert(self.Connections, UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then local delta = input.Position - dragStart; self.MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end))

    -- Containers
    self.TabSelector = Instance.new("ScrollingFrame")
    self.TabSelector.Size = UDim2.new(0, 160, 1, -45)
    self.TabSelector.Position = UDim2.new(0, 0, 0, 45)
    self.TabSelector.BackgroundColor3 = Theme.Background
    self.TabSelector.BorderSizePixel = 0
    self.TabSelector.ScrollBarThickness = 2
    self.TabSelector.Parent = self.MainFrame
    Instance.new("UIListLayout", self.TabSelector).Padding = UDim.new(0, 2)
    
    self.ContentContainer = Instance.new("Frame")
    self.ContentContainer.Size = UDim2.new(1, -160, 1, -45)
    self.ContentContainer.Position = UDim2.new(0, 160, 0, 45)
    self.ContentContainer.BackgroundTransparency = 1
    self.ContentContainer.Parent = self.MainFrame

    -- Botão de Fechar
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -40, 0.5, -15)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.TextColor3 = Theme.Red
    CloseBtn.Text = "✖"
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 16
    CloseBtn.Parent = TitleBar
    table.insert(self.Connections, CloseBtn.MouseButton1Click:Connect(function()
        if typeof(_G.ComunidadeHub_Cleanup) == "function" then
            _G.ComunidadeHub_Cleanup()
        end
    end))

    -- Área de Toasts
    self.NotifyFrame = Instance.new("Frame")
    self.NotifyFrame.Size = UDim2.new(0, 250, 1, -20)
    self.NotifyFrame.Position = UDim2.new(1, -270, 0, 10)
    self.NotifyFrame.BackgroundTransparency = 1
    self.NotifyFrame.Parent = self.ScreenGui
    local NotifyLayout = Instance.new("UIListLayout")
    NotifyLayout.Parent = self.NotifyFrame
    NotifyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    NotifyLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    NotifyLayout.Padding = UDim.new(0, 10)

    -- ==========================================
    -- 🧩 MONTAGEM DAS ABAS E CONEXÕES
    -- ==========================================
    
    -- Funções Auxiliares utilizando os Constants
    local function GetMobsFromConstants(island)
        local list = {"Nenhum", "Todos"}
        if island == "Todas" then
            for _, data in pairs(self.Constants.IslandDataMap) do
                if data.Mobs then for _, m in ipairs(data.Mobs) do table.insert(list, m) end end
            end
        else
            if self.Constants.IslandDataMap[island] and self.Constants.IslandDataMap[island].Mobs then
                for _, m in ipairs(self.Constants.IslandDataMap[island].Mobs) do table.insert(list, m) end
            end
        end
        return list
    end

    local function GetBossesFromConstants(island)
        local list = {"Nenhum"}
        if island == "Todas" then
            for _, data in pairs(self.Constants.IslandDataMap) do
                if data.Bosses then for _, b in ipairs(data.Bosses) do table.insert(list, b) end end
            end
        else
            if self.Constants.IslandDataMap[island] and self.Constants.IslandDataMap[island].Bosses then
                for _, b in ipairs(self.Constants.IslandDataMap[island].Bosses) do table.insert(list, b) end
            end
        end
        return list
    end

    local function GetQuestsFromConstants(island)
        local list = {"Nenhum"}
        if self.Constants.QuestDataMap[island] then
            for _, q in ipairs(self.Constants.QuestDataMap[island]) do table.insert(list, q.Name) end
        end
        return list
    end

    -- ABA 1: MISSÕES & LEVEL
    local TabMissions = self:CreateTab("Missões", "📜")
    TabMissions:CreateLabel("⚡ MODO AUTO LEVEL MÁXIMO")
    TabMissions:CreateToggle("Auto Farm (Progressão Automática)", self.Config.AutoFarmMaxLevel, function(v) self.Config.AutoFarmMaxLevel = v; if v then self.Config.AutoQuest = false end end)
    
    TabMissions:CreateLabel("🎯 MODO MISSÃO MANUAL")
    local questDropdownRef
    TabMissions:CreateDropdown("Ilha", self.Constants.QuestFilterOptions, self.Config.SelectedQuestIsland, function(s) 
        self.Config.SelectedQuestIsland = s
        if questDropdownRef then questDropdownRef.Refresh(GetQuestsFromConstants(s)) end
    end)
    questDropdownRef = TabMissions:CreateDropdown("Missão", GetQuestsFromConstants(self.Config.SelectedQuestIsland), self.Config.SelectedQuest, function(s) self.Config.SelectedQuest = s end)
    TabMissions:CreateToggle("Auto Quest (Manual)", self.Config.AutoQuest, function(v) self.Config.AutoQuest = v; if v then self.Config.AutoFarmMaxLevel = false end end)

    -- ABA 2: COMBATE & FARM
    local TabCombat = self:CreateTab("Combate", "⚔️")
    TabCombat:CreateLabel("🔍 SISTEMA DE MAPA")
    local mobDropdownRef, bossDropdownRef
    TabCombat:CreateDropdown("Filtro de Ilha", self.Constants.FilterOptions, "Todas", function(s) 
        if mobDropdownRef then mobDropdownRef.Refresh(GetMobsFromConstants(s)) end
        if bossDropdownRef then bossDropdownRef.Refresh(GetBossesFromConstants(s)) end
    end)
    
    mobDropdownRef = TabCombat:CreateDropdown("Alvo (Mob)", GetMobsFromConstants("Todas"), self.Config.SelectedMob, function(s) self.Config.SelectedMob = s end)
    TabCombat:CreateToggle("Auto Farm Mobs", self.Config.AutoFarm, function(v) self.Config.AutoFarm = v end)

    TabCombat:CreateLabel("👑 FILA DE BOSSES")
    bossDropdownRef = TabCombat:CreateDropdown("Alvo (Boss)", GetBossesFromConstants("Todas"), self.Config.SelectedBoss, function(s) self.Config.SelectedBoss = s end)
    
    local BossListLabel = TabCombat:CreateLabel("Fila: " .. (#self.Config.SelectedBosses > 0 and table.concat(self.Config.SelectedBosses, ", ") or "Nenhuma"))
    TabCombat:CreateButton("➕ Adicionar à Fila", function()
        if self.Config.SelectedBoss ~= "Nenhum" and not table.find(self.Config.SelectedBosses, self.Config.SelectedBoss) then
            table.insert(self.Config.SelectedBosses, self.Config.SelectedBoss)
            BossListLabel.Text = "Fila: " .. table.concat(self.Config.SelectedBosses, ", ")
            if self.Config.Save then self.Config:Save() end
        end
    end, Theme.Green)
    TabCombat:CreateButton("🗑️ Limpar Fila", function()
        self.Config.SelectedBosses = {}
        BossListLabel.Text = "Fila: Nenhuma"
        if self.Config.Save then self.Config:Save() end
    end, Theme.Red)
    TabCombat:CreateToggle("Auto Boss", self.Config.AutoBoss, function(v) self.Config.AutoBoss = v end)

    TabCombat:CreateLabel("⚙️ INTELIGÊNCIA DE ATAQUE")
    TabCombat:CreateDropdown("Posição", {"Atrás", "Acima", "Abaixo", "Orbital"}, self.Config.AttackPosition, function(s) self.Config.AttackPosition = s end)
    TabCombat:CreateTextBox("Velocidade (Tween)", self.Config.TweenSpeed, function(v) self.Config.TweenSpeed = v end)
    TabCombat:CreateTextBox("Distância", self.Config.Distance, function(v) self.Config.Distance = v end)

    -- ABA 3: COLETA & ITENS
    local TabCollect = self:CreateTab("Itens", "🎒")
    TabCollect:CreateToggle("Coletar Frutas", self.Config.AutoCollect.Fruits, function(v) self.Config.AutoCollect.Fruits = v end)
    TabCollect:CreateToggle("Fruit Sniper (Agressivo)", self.Config.FruitSniper, function(v) self.Config.FruitSniper = v end)
    TabCollect:CreateToggle("Coletar Hogyoku", self.Config.AutoCollect.Hogyoku, function(v) self.Config.AutoCollect.Hogyoku = v end)
    TabCollect:CreateToggle("Coletar Puzzles", self.Config.AutoCollect.Puzzles, function(v) self.Config.AutoCollect.Puzzles = v end)
    TabCollect:CreateToggle("Coletar Baús", self.Config.AutoCollect.Chests, function(v) self.Config.AutoCollect.Chests = v end)

    -- ABA 4: GACHA E STATUS
    local TabStats = self:CreateTab("Status", "📈")
    TabStats:CreateLabel("STATUS AUTOMÁTICO")
    for _, stat in ipairs(self.Constants.StatsList) do
        local isSelected = table.find(self.Config.SelectedStats, stat) ~= nil
        TabStats:CreateToggle("Focar em " .. stat, isSelected, function(v) 
            if v then if not table.find(self.Config.SelectedStats, stat) then table.insert(self.Config.SelectedStats, stat) end else local idx = table.find(self.Config.SelectedStats, stat); if idx then table.remove(self.Config.SelectedStats, idx) end end 
        end)
    end
    TabStats:CreateToggle("Auto Distribuir", self.Config.AutoStats, function(v) self.Config.AutoStats = v end)

    TabStats:CreateLabel("ROLETAS")
    TabStats:CreateDropdown("Raça Alvo", {"Kitsune", "Mink", "Fishman", "Human", "Skypiean"}, self.Config.AutoReroll.TargetRace, function(s) self.Config.AutoReroll.TargetRace = s end)
    TabStats:CreateToggle("Auto Reroll Raça", self.Config.AutoReroll.Race, function(v) self.Config.AutoReroll.Race = v end)

    -- ABA 5: MISC
    local TabMisc = self:CreateTab("Misc", "⚙️")
    TabMisc:CreateToggle("Super Velocidade", self.Config.SuperSpeed, function(v) self.Config.SuperSpeed = v end)
    TabMisc:CreateTextBox("Multiplicador Velocidade", self.Config.SpeedMultiplier, function(v) self.Config.SpeedMultiplier = v end)
    TabMisc:CreateToggle("Pulo Infinito", self.Config.InfJump, function(v) self.Config.InfJump = v end)
    TabMisc:CreateToggle("Haki do Armamento", self.Config.HacksNativos.HakiArmamento, function(v) self.Config.HacksNativos.HakiArmamento = v end)
    TabMisc:CreateToggle("Haki da Observação", self.Config.HacksNativos.HakiObservacao, function(v) self.Config.HacksNativos.HakiObservacao = v end)
    TabMisc:CreateToggle("No Cutscene", self.Config.HacksNativos.NoCutscene, function(v) self.Config.HacksNativos.NoCutscene = v end)

    self:Notify("Hub Injetado", "Arquitetura OOP Premium construída com sucesso!", 4)
end

return Interface
