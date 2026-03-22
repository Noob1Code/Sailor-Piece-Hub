-- =====================================================================
-- 🚀 COMUNIDADE HUB V22.2 - UI MODERNA & 100% FUNCIONAL
-- =====================================================================

-- IMPORTAÇÕES GLOBAIS (Seguindo sua arquitetura)
local LP = getgenv().LP or game:GetService("Players").LocalPlayer
local CoreGui = getgenv().CoreGui or game:GetService("CoreGui")
local UserInputService = getgenv().UserInputService or game:GetService("UserInputService")
local Workspace = getgenv().Workspace or game:GetService("Workspace")
local TweenService = getgenv().TweenService or game:GetService("TweenService")

local HubConfig = getgenv().HubConfig or { AutoCollect = {}, AutoReroll = {}, AutoOpenChests = {}, HacksNativos = {} }
local TeleportRemote = getgenv().TeleportRemote
local AllocateStatRemote = getgenv().AllocateStatRemote
local ResetStatsRemote = getgenv().ResetStatsRemote
local scriptConnections = getgenv().scriptConnections or {}

local getMobList = getgenv().getMobList or function() return {"Nenhum"} end
local getBossList = getgenv().getBossList or function() return {"Nenhum"} end
local getQuestsForIsland = getgenv().getQuestsForIsland or function() return {"Nenhum"} end
local getWeaponList = getgenv().getWeaponList or function() return {"Nenhum"} end
local unfreezeCharacter = getgenv().unfreezeCharacter or function() end
local SafeTeleport = getgenv().SafeTeleport or function() end

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
-- 🌟 CLASSE: GERENCIADOR DA INTERFACE (OOP)
-- =====================================================================
local Library = {}
Library.__index = Library

function Library.new(title)
    local self = setmetatable({}, Library)
    self.Tabs = {}
    self.CurrentTab = nil
    
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
    TitleBar.Text = "   " .. title
    TitleBar.Font = Enum.Font.GothamBold
    TitleBar.TextSize = 16
    TitleBar.TextXAlignment = Enum.TextXAlignment.Left
    TitleBar.Parent = self.MainFrame
    TitleBar.AutoButtonColor = false
    Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 8)
    
    -- Drag Logic
    local dragging, dragInput, dragStart, startPos
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; startPos = self.MainFrame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    TitleBar.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end)
    UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then local delta = input.Position - dragStart; self.MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)

    -- Container Setup
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

    -- Cleanup Logic
    local function doCleanup()
        if getgenv().SaveSettings then getgenv().SaveSettings() end  
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

    -- Close Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -40, 0.5, -15)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.TextColor3 = Theme.Red
    CloseBtn.Text = "✖"
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 16
    CloseBtn.Parent = TitleBar
    CloseBtn.MouseButton1Click:Connect(doCleanup)

    -- Toasts Frame
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

    return self
end

function Library:Notify(title, text, duration)
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
-- 🌟 COMPONENTES DE ABA
-- =====================================================================
function Library:CreateTab(name, icon)
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
    ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() 
        TabContent.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 10) 
    end)

    TabBtn.MouseEnter:Connect(function() if self.CurrentTab ~= TabContent then TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Sidebar}):Play() end end)
    TabBtn.MouseLeave:Connect(function() if self.CurrentTab ~= TabContent then TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Background}):Play() end end)

    TabBtn.MouseButton1Click:Connect(function()
        for _, tabInfo in pairs(self.Tabs) do 
            tabInfo.Content.Visible = false
            TweenService:Create(tabInfo.Button, TweenInfo.new(0.3), {BackgroundColor3 = Theme.Background, TextColor3 = Theme.TextDim}):Play()
        end
        TabContent.Visible = true
        self.CurrentTab = TabContent
        TweenService:Create(TabBtn, TweenInfo.new(0.3), {BackgroundColor3 = Theme.Component, TextColor3 = Theme.Accent}):Play()
    end)

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
        
        Btn.MouseEnter:Connect(function() TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(color.R*255 + 20, color.G*255 + 20, color.B*255 + 20)}):Play() end)
        Btn.MouseLeave:Connect(function() TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play() end)
        Btn.MouseButton1Click:Connect(function() callback() end)
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

        btn.MouseButton1Click:Connect(function()
            state = not state
            if state then
                TweenService:Create(indicator, TweenInfo.new(0.2), {Position = UDim2.new(1, -20, 0.5, -9), BackgroundColor3 = Theme.Green}):Play()
            else
                TweenService:Create(indicator, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -9), BackgroundColor3 = Theme.Red}):Play()
            end
            callback(state)
            if getgenv().SaveSettings then getgenv().SaveSettings() end
        end)
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
            if getgenv().SaveSettings then getgenv().SaveSettings() end
        end

        MainBtn.MouseButton1Click:Connect(function()
            isOpen = not isOpen
            local targetHeight = isOpen and math.min(ListLayout.AbsoluteContentSize.Y + 40, 160) or 40
            TweenService:Create(DropFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, -10, 0, targetHeight)}):Play()
            Arrow.Text = isOpen and "▲" or "▼"
            ListFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y)
        end)

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
                
                OptBtn.MouseEnter:Connect(function() TweenService:Create(OptBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Component, TextColor3 = Theme.Accent}):Play() end)
                OptBtn.MouseLeave:Connect(function() TweenService:Create(OptBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Sidebar, TextColor3 = Theme.TextDim}):Play() end)
                OptBtn.MouseButton1Click:Connect(function() updateSelection(opt) end)
            end
            
            local safeOpt = newOptions[1] or "Nenhum"
            MainBtn.Text = "  " .. title .. ": " .. tostring(safeOpt)
            callback(safeOpt)
        end
        refresh(options)
        MainBtn.Text = "  " .. title .. ": " .. tostring(defaultOption)
        callback(defaultOption)
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
        Label.Text = title
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
        
        TextBox.FocusLost:Connect(function() 
            local val = TextBox.Text
            if tonumber(val) then callback(tonumber(val)) else callback(val) end 
            if getgenv().SaveSettings then getgenv().SaveSettings() end
        end)
    end

    return Tab
end

-- =====================================================================
-- 🚀 MONTAGEM DA INTERFACE (Mapeado exatamente como seu código)
-- =====================================================================
local UI = Library.new("Comunidade Hub V22.2 (Moderno)")

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
            InfoBoss.Text = "Bônus Boss: Dano [" .. tostring(LP:GetAttribute("BossRush_Damage") or 0) .. "] | Crítico [" .. tostring(LP:GetAttribute("BossRush_CritDamage") or 0) .. "]"
            InfoPity.Text = "Bônus de Sorte: " .. tostring(LP:GetAttribute("RaceLuckBonus") or 0)
        end)
    end
end)

-- ABA 2: MISSÕES
local TabMissions = UI:CreateTab("Missões", "📜")
TabMissions:CreateLabel("⚡ MODO AUTO LEVEL MÁXIMO (1 AO MAX)")
TabMissions:CreateToggle("ATIVAR PILOTO AUTOMÁTICO", HubConfig.AutoFarmMaxLevel, function(v) HubConfig.AutoFarmMaxLevel = v; if v then HubConfig.AutoQuest = false end end)
TabMissions:CreateLabel("🎯 MODO MISSÃO MANUAL (FARM DE ITENS)")
TabMissions:CreateDropdown("Escolha a Ilha", HubConfig.QuestFilterOptions or {"Nenhum"}, HubConfig.SelectedQuestIsland, function(s) HubConfig.SelectedQuestIsland = s; local quests = getQuestsForIsland(s); if getgenv().QuestDropdownRef then getgenv().QuestDropdownRef.Refresh(quests) end end)
local initialQuests = getQuestsForIsland(HubConfig.SelectedQuestIsland)
getgenv().QuestDropdownRef = TabMissions:CreateDropdown("Escolha a Missão", initialQuests, HubConfig.SelectedQuest or initialQuests[1], function(s) HubConfig.SelectedQuest = s end)
TabMissions:CreateToggle("FARM MISSÃO SELECIONADA", HubConfig.AutoQuest, function(v) HubConfig.AutoQuest = v; if v then HubConfig.AutoFarmMaxLevel = false end end)

-- ABA 3: COMBATE
local TabCombat = UI:CreateTab("Combate", "⚔️")
TabCombat:CreateLabel("🔍 SISTEMA DE MAPA")
TabCombat:CreateButton("Varrer Ilha (Atualizar NPCs)", function() HubConfig.AvailableMobs = getMobList(HubConfig.SelectedFilter); if getgenv().MobDropdownRef then getgenv().MobDropdownRef.Refresh(HubConfig.AvailableMobs) end end)
TabCombat:CreateDropdown("Filtrar por Área", HubConfig.FilterOptions or {"Nenhum"}, HubConfig.SelectedFilter, function(s) HubConfig.SelectedFilter = s; HubConfig.AvailableMobs = getMobList(s); HubConfig.Bosses = getBossList(s); if getgenv().MobDropdownRef then getgenv().MobDropdownRef.Refresh(HubConfig.AvailableMobs) end; if getgenv().BossDropdownRef then getgenv().BossDropdownRef.Refresh(HubConfig.Bosses) end end)
getgenv().MobDropdownRef = TabCombat:CreateDropdown("Inimigo", HubConfig.AvailableMobs or {"Nenhum"}, HubConfig.SelectedMob, function(s) HubConfig.SelectedMob = s end)
TabCombat:CreateToggle("Auto Farm Mobs", HubConfig.AutoFarm, function(v) HubConfig.AutoFarm = v end)

TabCombat:CreateLabel("👑 FILA DE BOSSES")
local BossListLabel = TabCombat:CreateLabel("Fila: Nenhuma")
local function UpdateBossListLabel()
    if not HubConfig.SelectedBosses or #HubConfig.SelectedBosses == 0 then
        BossListLabel.Text = "Fila: Nenhuma"
    else
        BossListLabel.Text = "Fila: " .. table.concat(HubConfig.SelectedBosses, ", ")
    end
end
TabCombat:CreateTextBox("Buscar Boss (Enter)", "", function(text)
    local currentBosses = getBossList(HubConfig.SelectedFilter); local filtered = {}; text = tostring(text):lower()
    if text == "" then filtered = currentBosses else table.insert(filtered, "Nenhum"); for _, boss in ipairs(currentBosses) do if boss ~= "Nenhum" and boss:lower():find(text) then table.insert(filtered, boss) end end end
    if getgenv().BossDropdownRef then getgenv().BossDropdownRef.Refresh(filtered) end
end)
getgenv().BossDropdownRef = TabCombat:CreateDropdown("Selecionar Boss", HubConfig.Bosses or {"Nenhum"}, HubConfig.SelectedBoss, function(s) HubConfig.SelectedBoss = s end)

TabCombat:CreateButton("➕ Adicionar Boss à Fila", function()
    if HubConfig.SelectedBoss ~= "Nenhum" and not table.find(HubConfig.SelectedBosses, HubConfig.SelectedBoss) then
        table.insert(HubConfig.SelectedBosses, HubConfig.SelectedBoss)
        UpdateBossListLabel()
        if getgenv().SaveSettings then getgenv().SaveSettings() end
    end
end, Theme.Green)
TabCombat:CreateButton("➖ Remover Boss da Fila", function()
    local idx = table.find(HubConfig.SelectedBosses, HubConfig.SelectedBoss)
    if idx then table.remove(HubConfig.SelectedBosses, idx); UpdateBossListLabel(); if getgenv().SaveSettings then getgenv().SaveSettings() end end
end, Theme.Red)
TabCombat:CreateButton("🗑️ Limpar Fila", function()
    HubConfig.SelectedBosses = {}; UpdateBossListLabel(); if getgenv().SaveSettings then getgenv().SaveSettings() end
end)

TabCombat:CreateToggle("Auto Boss (Fila)", HubConfig.AutoBoss, function(v) HubConfig.AutoBoss = v end)
TabCombat:CreateToggle("Auto Training Dummy", HubConfig.AutoDummy, function(v) HubConfig.AutoDummy = v end)

TabCombat:CreateLabel("🔮 INVOCAÇÃO DE BOSS")
TabCombat:CreateDropdown("Boss para Invocar", {"Nenhum", "SaberBoss", "QinShiBoss", "IchigoBoss", "GilgameshBoss", "BlessedMaidenBoss", "SaberAlterBoss"}, HubConfig.SelectedSummonBoss or "Nenhum", function(s) HubConfig.SelectedSummonBoss = s end)
TabCombat:CreateToggle("Auto Invocar e Farmar", HubConfig.AutoSummon, function(v) HubConfig.AutoSummon = v end)

TabCombat:CreateLabel("⚙️ INTELIGÊNCIA DE COMBATE")
TabCombat:CreateTextBox("Velocidade do Voo", HubConfig.TweenSpeed or 150, function(v) HubConfig.TweenSpeed = tonumber(v) or 150 end)
TabCombat:CreateDropdown("Posição de Ataque", {"Atrás", "Acima", "Abaixo", "Orbital"}, HubConfig.AttackPosition or "Atrás", function(s) HubConfig.AttackPosition = s end)
TabCombat:CreateTextBox("Distância (Studs)", HubConfig.Distance or 5, function(v) HubConfig.Distance = tonumber(v) or 5 end)

-- ABA 4: ITENS
local TabCollect = UI:CreateTab("Itens", "🎒")
TabCollect:CreateToggle("Auto Group Reward", HubConfig.AutoGroupReward, function(v) HubConfig.AutoGroupReward = v end)
TabCollect:CreateToggle("Coletar Frutas do Chão", HubConfig.AutoCollect.Fruits, function(v) HubConfig.AutoCollect.Fruits = v end)
TabCollect:CreateToggle("Coletar Hogyokus", HubConfig.AutoCollect.Hogyoku, function(v) HubConfig.AutoCollect.Hogyoku = v end)
TabCollect:CreateToggle("Coletar Puzzles", HubConfig.AutoCollect.Puzzles, function(v) HubConfig.AutoCollect.Puzzles = v end)
TabCollect:CreateToggle("Coletar Baús", HubConfig.AutoCollect.Chests, function(v) HubConfig.AutoCollect.Chests = v end)

-- ABA 5: STATUS
local TabStats = UI:CreateTab("Status", "📈")
TabStats:CreateDropdown("Atributo Manual", HubConfig.StatsList or {"Melee"}, HubConfig.ManualStat, function(s) HubConfig.ManualStat = s end)
TabStats:CreateTextBox("Quantidade Manual", HubConfig.ManualAmount or 1, function(v) HubConfig.ManualAmount = tonumber(v) or 1 end)
TabStats:CreateButton("➕ Adicionar Pontos", function() if AllocateStatRemote then AllocateStatRemote:FireServer(HubConfig.ManualStat, HubConfig.ManualAmount) end end, Theme.Green)

TabStats:CreateLabel("AUTO DISTRIBUIÇÃO")
for _, stat in ipairs(HubConfig.StatsList or {}) do
    local isSelected = table.find(HubConfig.SelectedStats or {}, stat) ~= nil
    TabStats:CreateToggle("Auto Upar " .. stat, isSelected, function(v) 
        if not HubConfig.SelectedStats then HubConfig.SelectedStats = {} end
        if v then if not table.find(HubConfig.SelectedStats, stat) then table.insert(HubConfig.SelectedStats, stat) end else local idx = table.find(HubConfig.SelectedStats, stat); if idx then table.remove(HubConfig.SelectedStats, idx) end end 
    end)
end
TabStats:CreateToggle("Ativar Auto Distribuir", HubConfig.AutoStats, function(v) HubConfig.AutoStats = v end)

-- ABA 6: ROLETA
local TabRoleta = UI:CreateTab("Roleta", "🎲")
TabRoleta:CreateTextBox("Raça Sniper", HubConfig.AutoReroll.TargetRace, function(v) HubConfig.AutoReroll.TargetRace = tostring(v) end)
TabRoleta:CreateToggle("Iniciar Sniper Raça", HubConfig.AutoReroll.Race, function(v) HubConfig.AutoReroll.Race = v end)
TabRoleta:CreateTextBox("Qtd Baús (9999 = Máx)", HubConfig.ChestOpenAmount or 1, function(v) HubConfig.ChestOpenAmount = tonumber(v) or 1 end)
TabRoleta:CreateToggle("Abrir Baús Comuns", HubConfig.AutoOpenChests.Common, function(v) HubConfig.AutoOpenChests.Common = v end)
TabRoleta:CreateToggle("Abrir Baús Raros", HubConfig.AutoOpenChests.Rare, function(v) HubConfig.AutoOpenChests.Rare = v end)
TabRoleta:CreateToggle("Abrir Baús Épicos", HubConfig.AutoOpenChests.Epic, function(v) HubConfig.AutoOpenChests.Epic = v end)
TabRoleta:CreateToggle("Abrir Baús Lendários", HubConfig.AutoOpenChests.Legendary, function(v) HubConfig.AutoOpenChests.Legendary = v end)
TabRoleta:CreateToggle("Abrir Baús Míticos", HubConfig.AutoOpenChests.Mythical, function(v) HubConfig.AutoOpenChests.Mythical = v end)

-- ABA 7: MUNDO
local TabWorld = UI:CreateTab("Mundo", "🌍")
TabWorld:CreateDropdown("Viajar para Ilha", HubConfig.Islands or {"Starter"}, "Starter", function(s) if TeleportRemote then TeleportRemote:FireServer(s) end end)
TabWorld:CreateDropdown("Teleporte para NPC", HubConfig.NPCs or {"EnchantNPC"}, "EnchantNPC", function(s) local npc = Workspace:FindFirstChild("ServiceNPCs") and Workspace.ServiceNPCs:FindFirstChild(s); if npc and npc:FindFirstChild("HumanoidRootPart") then unfreezeCharacter(LP.Character); SafeTeleport(npc.HumanoidRootPart.Position + Vector3.new(0, 0, 5)) end end)

-- ABA 8: NATIVOS
local TabNativos = UI:CreateTab("Nativos", "🕵️‍♂️")
TabNativos:CreateToggle("Haki do Armamento", HubConfig.HacksNativos.HakiArmamento, function(v) HubConfig.HacksNativos.HakiArmamento = v; if getgenv().HakiArmamentoRemote then getgenv().HakiArmamentoRemote:FireServer("Toggle") end end)
TabNativos:CreateToggle("Haki da Observação", HubConfig.HacksNativos.HakiObservacao, function(v) HubConfig.HacksNativos.HakiObservacao = v; if getgenv().HakiObservacaoRemote then getgenv().HakiObservacaoRemote:FireServer("Toggle") end end)
TabNativos:CreateToggle("Pulos Extras", HubConfig.HacksNativos.PuloExtra, function(v) HubConfig.HacksNativos.PuloExtra = v; if not v then pcall(function() LP:SetAttribute("RaceExtraJumps", 0) end) end end)
TabNativos:CreateToggle("NoShake (Tremores)", HubConfig.HacksNativos.NoShake, function(v) HubConfig.HacksNativos.NoShake = v; pcall(function() LP:SetAttribute("DisableScreenShake", v) end) end)
TabNativos:CreateToggle("NoCutscene", HubConfig.HacksNativos.NoCutscene, function(v) HubConfig.HacksNativos.NoCutscene = v; pcall(function() LP:SetAttribute("DisableCutscene", v) end) end)

-- ABA 9 & 10: MISC
local TabSniper = UI:CreateTab("Fruit V2", "🍎")
TabSniper:CreateToggle("Sniper de Frutas (Imediato)", HubConfig.FruitSniper, function(v) HubConfig.FruitSniper = v end)

local TabMisc = UI:CreateTab("Misc", "⚙️")
TabMisc:CreateToggle("Super Velocidade", HubConfig.SuperSpeed, function(v) HubConfig.SuperSpeed = v end)
TabMisc:CreateToggle("Pulo Infinito", HubConfig.InfJump, function(v) HubConfig.InfJump = v end)

-- Finalizações e Exportações
UpdateBossListLabel()
getgenv().SendToast = function(titulo, texto, tempo) UI:Notify(titulo, texto, tempo) end
getgenv().SendToast("Hub Carregado", "Interface Premium sincronizada e injetada com sucesso!", 4)
