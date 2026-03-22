-- =====================================================================
-- 🖥️ UI: Interface.lua (Gerenciador Visual e Interação do Usuário)
-- =====================================================================

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LP = Players.LocalPlayer

local Interface = {}
Interface.__index = Interface

-- ==========================================
-- 🏗️ CONSTRUTOR DA INTERFACE
-- ==========================================

function Interface.new(Config, FSM, Constants)
    local self = setmetatable({}, Interface)
    
    self.Config = Config
    self.FSM = FSM
    self.Constants = Constants
    self.Tabs = {}
    self.CurrentTab = nil
    self._connections = {}
    
    local uiParent = pcall(function() return CoreGui.Name end) and CoreGui or LP:WaitForChild("PlayerGui")
    if uiParent:FindFirstChild("ComunidadeHubGUI") then 
        uiParent.ComunidadeHubGUI:Destroy() 
    end
    
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "ComunidadeHubGUI"
    self.ScreenGui.Parent = uiParent
    self.ScreenGui.ResetOnSpawn = false
    
    self.MainFrame = Instance.new("Frame")
    self.MainFrame.Size = UDim2.new(0, 540, 0, 460)
    self.MainFrame.Position = UDim2.new(0.5, -270, 0.5, -230)
    self.MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    self.MainFrame.ClipsDescendants = true
    self.MainFrame.Parent = self.ScreenGui
    Instance.new("UICorner", self.MainFrame).CornerRadius = UDim.new(0, 8)
    
    local TitleBar = Instance.new("TextButton")
    TitleBar.Size = UDim2.new(1, 0, 0, 40)
    TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    TitleBar.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleBar.Text = "   🌟 Comunidade Hub V3.0 (Modular)"
    TitleBar.Font = Enum.Font.GothamBold
    TitleBar.TextSize = 14
    TitleBar.TextXAlignment = Enum.TextXAlignment.Left
    TitleBar.Parent = self.MainFrame
    TitleBar.AutoButtonColor = false
    Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 8)
    
    self:MakeDraggable(TitleBar, self.MainFrame)

    self.TabSelector = Instance.new("ScrollingFrame")
    self.TabSelector.Size = UDim2.new(0, 150, 1, -40)
    self.TabSelector.Position = UDim2.new(0, 0, 0, 40)
    self.TabSelector.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    self.TabSelector.BorderSizePixel = 0
    self.TabSelector.ScrollBarThickness = 2
    self.TabSelector.Parent = self.MainFrame
    Instance.new("UIListLayout", self.TabSelector).Padding = UDim.new(0, 2)
    
    self.ContentContainer = Instance.new("Frame")
    self.ContentContainer.Size = UDim2.new(1, -150, 1, -40)
    self.ContentContainer.Position = UDim2.new(0, 150, 0, 40)
    self.ContentContainer.BackgroundTransparency = 1
    self.ContentContainer.Parent = self.MainFrame

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -35, 0.5, -15)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    CloseBtn.Text = "X"
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Parent = TitleBar
    CloseBtn.MouseButton1Click:Connect(function()
        if _G.ComunidadeHub_Cleanup then _G.ComunidadeHub_Cleanup() end
    end)

    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.new(0, 30, 0, 30)
    MinBtn.Position = UDim2.new(1, -65, 0.5, -15)
    MinBtn.BackgroundTransparency = 1
    MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinBtn.Text = "-"
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.Parent = TitleBar
    local isMinimized = false
    MinBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        MinBtn.Text = isMinimized and "+" or "-"
        self.MainFrame:TweenSize(isMinimized and UDim2.new(0, 540, 0, 40) or UDim2.new(0, 540, 0, 460), "Out", "Quart", 0.3, true)
        self.TabSelector.Visible = not isMinimized
        self.ContentContainer.Visible = not isMinimized
    end)

    self.NotifyFrame = Instance.new("Frame")
    self.NotifyFrame.Size = UDim2.new(0, 220, 1, -20)
    self.NotifyFrame.Position = UDim2.new(1, -240, 0, 10)
    self.NotifyFrame.BackgroundTransparency = 1
    self.NotifyFrame.Parent = self.ScreenGui
    local NotifyLayout = Instance.new("UIListLayout")
    NotifyLayout.Parent = self.NotifyFrame
    NotifyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    NotifyLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    NotifyLayout.Padding = UDim.new(0, 10)

    self:BuildTabs()
    self:Notify("Hub Inicializado", "Todas as abas carregadas com sucesso!", 4)

    return self
end

-- ==========================================
-- 🛠️ FUNÇÕES INTERNAS DE UI
-- ==========================================

function Interface:MakeDraggable(topbar, frame)
    local dragging, dragInput, dragStart, startPos
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = frame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    topbar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

function Interface:Notify(title, text, duration)
    duration = duration or 3 
    local Notif = Instance.new("Frame")
    Notif.Size = UDim2.new(1, 0, 0, 60)
    Notif.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    Notif.BackgroundTransparency = 1 
    Instance.new("UICorner", Notif).CornerRadius = UDim.new(0, 6)
    Notif.Parent = self.NotifyFrame
    
    local SideBar = Instance.new("Frame")
    SideBar.Size = UDim2.new(0, 4, 1, 0); SideBar.BackgroundColor3 = Color3.fromRGB(80, 150, 255)
    SideBar.BorderSizePixel = 0; SideBar.BackgroundTransparency = 1; SideBar.Parent = Notif
    Instance.new("UICorner", SideBar).CornerRadius = UDim.new(0, 6)
    
    local TitleLbl = Instance.new("TextLabel")
    TitleLbl.Size = UDim2.new(1, -20, 0, 20); TitleLbl.Position = UDim2.new(0, 15, 0, 5)
    TitleLbl.BackgroundTransparency = 1; TitleLbl.Text = title
    TitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255); TitleLbl.Font = Enum.Font.GothamBold; TitleLbl.TextSize = 13
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left; TitleLbl.Parent = Notif

    local DescLbl = Instance.new("TextLabel")
    DescLbl.Size = UDim2.new(1, -20, 0, 30); DescLbl.Position = UDim2.new(0, 15, 0, 25)
    DescLbl.BackgroundTransparency = 1; DescLbl.Text = text
    DescLbl.TextColor3 = Color3.fromRGB(180, 180, 180); DescLbl.Font = Enum.Font.Gotham; DescLbl.TextSize = 11
    DescLbl.TextXAlignment = Enum.TextXAlignment.Left; DescLbl.TextWrapped = true; DescLbl.Parent = Notif

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

function Interface:CreateTab(name, icon)
    local Tab = {}
    Tab.Window = self
    
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(1, 0, 0, 35); TabBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    TabBtn.BorderSizePixel = 0; TabBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
    TabBtn.Text = "  " .. (icon or "") .. " " .. name; TabBtn.Font = Enum.Font.GothamSemibold
    TabBtn.TextSize = 13; TabBtn.TextXAlignment = Enum.TextXAlignment.Left; TabBtn.Parent = self.TabSelector
    TabBtn.AutoButtonColor = false 
    
    local TabContent = Instance.new("ScrollingFrame")
    TabContent.Size = UDim2.new(1, -10, 1, -10); TabContent.Position = UDim2.new(0, 5, 0, 5)
    TabContent.BackgroundTransparency = 1; TabContent.ScrollBarThickness = 2; TabContent.Visible = false
    TabContent.Parent = self.ContentContainer
    
    local ContentLayout = Instance.new("UIListLayout")
    ContentLayout.Parent = TabContent; ContentLayout.Padding = UDim.new(0, 8) 
    ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() 
        TabContent.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 10) 
    end)

    TabBtn.MouseEnter:Connect(function()
        if self.CurrentTab ~= TabContent then TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(28, 28, 35)}):Play() end
    end)
    TabBtn.MouseLeave:Connect(function()
        if self.CurrentTab ~= TabContent then TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(20, 20, 25)}):Play() end
    end)

    TabBtn.MouseButton1Click:Connect(function()
        for _, tabInfo in pairs(self.Tabs) do 
            tabInfo.Content.Visible = false
            TweenService:Create(tabInfo.Button, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(20, 20, 25), TextColor3 = Color3.fromRGB(180, 180, 180)}):Play()
        end
        TabContent.Visible = true
        self.CurrentTab = TabContent
        TweenService:Create(TabBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(45, 100, 255), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
    end)

    if not self.CurrentTab then 
        TabContent.Visible = true; TabBtn.BackgroundColor3 = Color3.fromRGB(45, 100, 255); TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        self.CurrentTab = TabContent 
    end
    table.insert(self.Tabs, {Button = TabBtn, Content = TabContent})
    Tab.Container = TabContent

    function Tab:CreateLabel(text)
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, 0, 0, 20); Label.BackgroundTransparency = 1; Label.TextColor3 = Color3.fromRGB(150, 150, 180)
        Label.Text = text; Label.TextXAlignment = Enum.TextXAlignment.Left; Label.Font = Enum.Font.GothamBold; Label.TextSize = 12
        Label.Parent = self.Container
        return Label
    end

    function Tab:CreateButton(text, callback, color)
        local baseColor = color or Color3.fromRGB(45, 100, 255)
        local hoverColor = Color3.fromRGB(math.clamp(baseColor.R*255 + 20, 0, 255), math.clamp(baseColor.G*255 + 20, 0, 255), math.clamp(baseColor.B*255 + 20, 0, 255))
        
        local Btn = Instance.new("TextButton")
        Btn.Size = UDim2.new(1, -5, 0, 32); Btn.BackgroundColor3 = baseColor
        Btn.TextColor3 = Color3.fromRGB(255, 255, 255); Btn.Text = text; Btn.Font = Enum.Font.GothamSemibold
        Btn.TextSize = 13; Btn.Parent = self.Container; Btn.AutoButtonColor = false
        Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
        
        Btn.MouseEnter:Connect(function() TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor}):Play() end)
        Btn.MouseLeave:Connect(function() TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = baseColor}):Play() end)
        Btn.MouseButton1Click:Connect(function()
            TweenService:Create(Btn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {Size = UDim2.new(0.98, -5, 0, 30)}):Play()
            callback()
        end)
        return Btn
    end

    function Tab:CreateToggle(text, defaultState, callback)
        local state = defaultState
        local colorOn, colorOff = Color3.fromRGB(40, 180, 80), Color3.fromRGB(40, 40, 50)
        local ToggleBtn = Instance.new("TextButton")
        ToggleBtn.Size = UDim2.new(1, -5, 0, 32); ToggleBtn.BackgroundColor3 = state and colorOn or colorOff
        ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255); ToggleBtn.Text = text .. " [" .. (state and "ON" or "OFF") .. "]"
        ToggleBtn.Font = Enum.Font.GothamSemibold; ToggleBtn.TextSize = 13; ToggleBtn.Parent = self.Container; ToggleBtn.AutoButtonColor = false
        Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 4)
        
        ToggleBtn.MouseEnter:Connect(function()
            local targetColor = state and Color3.fromRGB(50, 200, 90) or Color3.fromRGB(50, 50, 60)
            TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
        end)
        ToggleBtn.MouseLeave:Connect(function()
            TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = state and colorOn or colorOff}):Play()
        end)
        ToggleBtn.MouseButton1Click:Connect(function()
            state = not state
            TweenService:Create(ToggleBtn, TweenInfo.new(0.3), {BackgroundColor3 = state and colorOn or colorOff}):Play()
            ToggleBtn.Text = text .. " [" .. (state and "ON" or "OFF") .. "]"
            callback(state)
        end)
    end

    function Tab:CreateDropdown(title, options, defaultOption, callback)
        local DropFrame = Instance.new("Frame")
        DropFrame.Size = UDim2.new(1, -5, 0, 32); DropFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        DropFrame.ClipsDescendants = true; DropFrame.Parent = self.Container
        Instance.new("UICorner", DropFrame).CornerRadius = UDim.new(0, 4)
        
        local MainBtn = Instance.new("TextButton")
        MainBtn.Size = UDim2.new(1, 0, 0, 32); MainBtn.BackgroundTransparency = 1; MainBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        MainBtn.Text = "  " .. title .. ": " .. tostring(defaultOption); MainBtn.Font = Enum.Font.GothamSemibold
        MainBtn.TextSize = 12; MainBtn.TextXAlignment = Enum.TextXAlignment.Left; MainBtn.Parent = DropFrame; MainBtn.AutoButtonColor = false
        
        local Arrow = Instance.new("TextLabel"); Arrow.Size = UDim2.new(0, 30, 1, 0); Arrow.Position = UDim2.new(1, -30, 0, 0); Arrow.BackgroundTransparency = 1; Arrow.Text = "▼"; Arrow.TextColor3 = Color3.fromRGB(200, 200, 200); Arrow.Font = Enum.Font.GothamBold; Arrow.Parent = MainBtn

        local ListFrame = Instance.new("ScrollingFrame")
        ListFrame.Size = UDim2.new(1, 0, 1, -32); ListFrame.Position = UDim2.new(0, 0, 0, 32)
        ListFrame.BackgroundTransparency = 1; ListFrame.ScrollBarThickness = 2; ListFrame.Parent = DropFrame
        local ListLayout = Instance.new("UIListLayout"); ListLayout.Parent = ListFrame
        
        local isOpen = false
        MainBtn.MouseButton1Click:Connect(function()
            isOpen = not isOpen
            local targetHeight = isOpen and math.min(ListLayout.AbsoluteContentSize.Y + 32, 140) or 32
            TweenService:Create(DropFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, -5, 0, targetHeight)}):Play()
            TweenService:Create(Arrow, TweenInfo.new(0.3), {Rotation = isOpen and 180 or 0}):Play()
            ListFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y)
        end)

        local function refresh(newOptions)
            for _, b in pairs(ListFrame:GetChildren()) do if b:IsA("TextButton") then b:Destroy() end end
            for _, opt in ipairs(newOptions) do
                local OptBtn = Instance.new("TextButton")
                OptBtn.Size = UDim2.new(1, 0, 0, 28); OptBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
                OptBtn.TextColor3 = Color3.fromRGB(180, 180, 180); OptBtn.Text = "  " .. tostring(opt)
                OptBtn.Font = Enum.Font.Gotham; OptBtn.TextSize = 12; OptBtn.TextXAlignment = Enum.TextXAlignment.Left; OptBtn.Parent = ListFrame; OptBtn.AutoButtonColor = false
                
                OptBtn.MouseEnter:Connect(function() TweenService:Create(OptBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 100, 255), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play() end)
                OptBtn.MouseLeave:Connect(function() TweenService:Create(OptBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 35, 45), TextColor3 = Color3.fromRGB(180, 180, 180)}):Play() end)
                OptBtn.MouseButton1Click:Connect(function()
                    MainBtn.Text = "  " .. title .. ": " .. tostring(opt)
                    callback(opt)
                    isOpen = false
                    TweenService:Create(DropFrame, TweenInfo.new(0.3), {Size = UDim2.new(1, -5, 0, 32)}):Play()
                    TweenService:Create(Arrow, TweenInfo.new(0.3), {Rotation = 0}):Play()
                end)
            end
        end
        refresh(options)
        return { Refresh = refresh }
    end

    function Tab:CreateTextBox(title, defaultText, callback)
        local Container = Instance.new("Frame"); Container.Size = UDim2.new(1, -5, 0, 32); Container.BackgroundColor3 = Color3.fromRGB(30, 30, 40); Container.Parent = self.Container
        Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 4)
        local Label = Instance.new("TextLabel"); Label.Size = UDim2.new(0.6, 0, 1, 0); Label.BackgroundTransparency = 1; Label.TextColor3 = Color3.fromRGB(200, 200, 200); Label.Text = "  " .. title; Label.Font = Enum.Font.GothamSemibold; Label.TextSize = 12; Label.TextXAlignment = Enum.TextXAlignment.Left; Label.Parent = Container
        local TextBox = Instance.new("TextBox"); TextBox.Size = UDim2.new(0.35, -5, 0.8, 0); TextBox.Position = UDim2.new(0.65, 0, 0.1, 0); TextBox.BackgroundColor3 = Color3.fromRGB(20, 20, 25); TextBox.TextColor3 = Color3.fromRGB(255, 255, 255); TextBox.Text = tostring(defaultText); TextBox.Font = Enum.Font.Gotham; TextBox.TextSize = 12; TextBox.Parent = Container
        Instance.new("UICorner", TextBox).CornerRadius = UDim.new(0, 4)
        
        TextBox.Focused:Connect(function() TweenService:Create(TextBox, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}):Play() end)
        TextBox.FocusLost:Connect(function() 
            TweenService:Create(TextBox, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(20, 20, 25)}):Play()
            local val = TextBox.Text; if tonumber(val) then callback(tonumber(val)) else callback(val) end 
        end)
    end

    return Tab
end

-- ==========================================
-- 📝 CONSTRUÇÃO DE TODAS AS ABAS
-- ==========================================

function Interface:BuildTabs()
    local c = self.Config
    local const = self.Constants
    
    -- ==========================================
    -- 📊 ABA 1: DASHBOARD
    -- ==========================================
    local TabDash = self:CreateTab("Dashboard", "📊")
    TabDash:CreateLabel("INFORMAÇÕES DO JOGADOR")
    local InfoRace = TabDash:CreateLabel("Raça: Carregando...")
    local InfoClan = TabDash:CreateLabel("Clã: Carregando...")
    local InfoDamage = TabDash:CreateLabel("Bônus Melee/Sword: Carregando...")
    local InfoBoss = TabDash:CreateLabel("Bônus Boss/Crit: Carregando...")
    local InfoPity = TabDash:CreateLabel("Sorte: Carregando...")

    -- Atualizador Visual do Dashboard (Seguro, pois só lê atributos)
    task.spawn(function()
        while task.wait(1) do
            if not c.IsRunning then break end
            pcall(function()
                InfoRace.Text = "Raça Atual: " .. tostring(LP:GetAttribute("CurrentRace") or "Humano") .. " (+ " .. tostring(LP:GetAttribute("RaceExtraJumps") or 0) .. " Pulos)"
                InfoClan.Text = "Clã Atual: " .. tostring(LP:GetAttribute("CurrentClan") or "Nenhum")
                InfoDamage.Text = "Multiplicadores: Melee [" .. tostring(LP:GetAttribute("RaceMeleeDamage") or 0) .. "] | Sword [" .. tostring(LP:GetAttribute("RaceSwordDamage") or 0) .. "]"
                InfoBoss.Text = "Bônus em Bosses: Dano [" .. tostring(LP:GetAttribute("BossRush_Damage") or 0) .. "] | Crítico [" .. tostring(LP:GetAttribute("BossRush_CritDamage") or 0) .. "]"
                InfoPity.Text = "Bônus de Sorte: " .. tostring(LP:GetAttribute("RaceLuckBonus") or 0)
            end)
        end
    end)

    -- ==========================================
    -- 📜 ABA 2: MISSÕES
    -- ==========================================
    local TabMissions = self:CreateTab("Missões", "📜")
    TabMissions:CreateLabel("⚡ MODO AUTO LEVEL MÁXIMO (1 AO MAX)")
    TabMissions:CreateToggle("ATIVAR PILOTO AUTOMÁTICO", c.AutoFarmMaxLevel, function(v) 
        c.AutoFarmMaxLevel = v
        if v then c.AutoQuest = false end
        c:Save()
    end)
    TabMissions:CreateLabel("--------------------------------------------------------")
    TabMissions:CreateLabel("🎯 MODO MISSÃO MANUAL (FARM DE ITENS)")
    
    local QuestDrop -- Declarado antes para ser referenciado
    TabMissions:CreateDropdown("Escolha a Ilha", const.QuestFilterOptions, c.SelectedQuestIsland, function(s) 
        c.SelectedQuestIsland = s
        local questsDisp = {}
        if const.QuestDataMap[s] then
            for _, q in ipairs(const.QuestDataMap[s]) do table.insert(questsDisp, q.Name) end
        end
        if #questsDisp == 0 then table.insert(questsDisp, "Nenhuma Quest") end
        if QuestDrop then QuestDrop.Refresh(questsDisp) end
        c:Save()
    end)
    
    local initialQuests = {"Nenhuma Quest"}
    if const.QuestDataMap[c.SelectedQuestIsland] then
        initialQuests = {}
        for _, q in ipairs(const.QuestDataMap[c.SelectedQuestIsland]) do table.insert(initialQuests, q.Name) end
    end
    
    QuestDrop = TabMissions:CreateDropdown("Escolha a Missão", initialQuests, c.SelectedQuest or initialQuests[1], function(s) 
        c.SelectedQuest = s
        c:Save()
    end)
    
    TabMissions:CreateToggle("FARM MISSÃO SELECIONADA", c.AutoQuest, function(v) 
        c.AutoQuest = v
        if v then c.AutoFarmMaxLevel = false end
        c:Save()
    end)

    -- ==========================================
    -- ⚔️ ABA 3: COMBATE
    -- ==========================================
    local TabCombat = self:CreateTab("Combate", "⚔️")
    TabCombat:CreateLabel("🔍 SISTEMA DE MAPA")
    
    local MobDrop
    TabCombat:CreateDropdown("Filtrar por Área", const.FilterOptions, "Todas", function(ilhaName)
        local mobsDisp = {"Nenhum"}
        if ilhaName == "Todas" then
            table.insert(mobsDisp, "Todos")
        elseif const.IslandDataMap[ilhaName] then
            for _, m in ipairs(const.IslandDataMap[ilhaName].Mobs) do table.insert(mobsDisp, m) end
        end
        if MobDrop then MobDrop.Refresh(mobsDisp) end
    end)
    
    MobDrop = TabCombat:CreateDropdown("Inimigo", {"Nenhum", "Todos"}, c.SelectedMob, function(s) 
        c.SelectedMob = s; c:Save() 
    end)
    
    TabCombat:CreateToggle("Auto Farm Mobs", c.AutoFarm, function(v) 
        c.AutoFarm = v; c:Save() 
    end)

    TabCombat:CreateLabel("--------------------------------------------------------")
    TabCombat:CreateLabel("👑 FILA DE BOSSES")
    local BossListLabel = TabCombat:CreateLabel("Fila: Nenhuma")

    local function UpdateBossListLabel()
        if #c.SelectedBosses == 0 then
            BossListLabel.Text = "Fila: Nenhuma"
        else
            BossListLabel.Text = "Fila: " .. table.concat(c.SelectedBosses, ", ")
        end
    end
    
    local BossDrop
    TabCombat:CreateDropdown("Selecionar Boss", const.SummonBossList, c.SelectedBoss, function(s) 
        c.SelectedBoss = s; c:Save() 
    end)

    TabCombat:CreateButton("➕ Adicionar Boss à Fila", function()
        if c.SelectedBoss ~= "Nenhum" and not table.find(c.SelectedBosses, c.SelectedBoss) then
            table.insert(c.SelectedBosses, c.SelectedBoss)
            UpdateBossListLabel()
            c:Save()
        end
    end, Color3.fromRGB(40, 150, 80))

    TabCombat:CreateButton("➖ Remover Boss da Fila", function()
        local idx = table.find(c.SelectedBosses, c.SelectedBoss)
        if idx then
            table.remove(c.SelectedBosses, idx)
            UpdateBossListLabel()
            c:Save()
        end
    end, Color3.fromRGB(200, 60, 60))

    TabCombat:CreateButton("🗑️ Limpar Fila", function()
        c.SelectedBosses = {}
        UpdateBossListLabel()
        c:Save()
    end, Color3.fromRGB(200, 100, 60))

    TabCombat:CreateToggle("Auto Boss (Fila)", c.AutoBoss, function(v) c.AutoBoss = v; c:Save() end)
    TabCombat:CreateToggle("Auto Training Dummy", c.AutoDummy, function(v) c.AutoDummy = v; c:Save() end)

    TabCombat:CreateLabel("--------------------------------------------------------")
    TabCombat:CreateLabel("🔮 INVOCAÇÃO DE BOSS (SUMMON)")
    TabCombat:CreateDropdown("Boss para Invocar", const.SummonBossList, c.SelectedSummonBoss or "Nenhum", function(s) 
        c.SelectedSummonBoss = s; c:Save() 
    end)
    TabCombat:CreateToggle("Auto Invocar e Farmar", c.AutoSummon, function(v) c.AutoSummon = v; c:Save() end)

    TabCombat:CreateLabel("--------------------------------------------------------")
    TabCombat:CreateLabel("⚙️ INTELIGÊNCIA DE COMBATE E MOVIMENTO")
    TabCombat:CreateTextBox("Velocidade do Voo", c.TweenSpeed, function(v) c.TweenSpeed = tonumber(v) or 150; c:Save() end)
    TabCombat:CreateDropdown("Posição de Ataque", {"Atrás", "Acima", "Abaixo", "Orbital"}, c.AttackPosition, function(s) c.AttackPosition = s; c:Save() end)
    TabCombat:CreateTextBox("Distância do Alvo (Studs)", c.Distance, function(v) c.Distance = tonumber(v) or 5; c:Save() end)

    UpdateBossListLabel() -- Carrega visual inicial

    -- ==========================================
    -- 🎒 ABA 4: ITENS
    -- ==========================================
    local TabCollect = self:CreateTab("Itens", "🎒")
    TabCollect:CreateToggle("Auto Group Reward", c.AutoGroupReward, function(v) c.AutoGroupReward = v; c:Save() end)
    TabCollect:CreateToggle("Coletar Frutas (Map Scan Otimizado)", c.AutoCollect.Fruits, function(v) c.AutoCollect.Fruits = v; c:Save() end)
    TabCollect:CreateToggle("Coletar Hogyoku", c.AutoCollect.Hogyoku, function(v) c.AutoCollect.Hogyoku = v; c:Save() end)
    TabCollect:CreateToggle("Coletar Puzzles", c.AutoCollect.Puzzles, function(v) c.AutoCollect.Puzzles = v; c:Save() end)
    TabCollect:CreateToggle("Coletar Baús do Chão", c.AutoCollect.Chests, function(v) c.AutoCollect.Chests = v; c:Save() end)

    -- ==========================================
    -- 📈 ABA 5: STATUS
    -- ==========================================
    local TabStats = self:CreateTab("Status", "📈")
    local InfoPoints = TabStats:CreateLabel("Pontos Disponíveis: Carregando...")
    TabStats:CreateLabel("--------------------------------------------------------")
    TabStats:CreateLabel("DISTRIBUIÇÃO MANUAL")
    TabStats:CreateDropdown("Atributo", const.StatsList, c.ManualStat, function(s) c.ManualStat = s; c:Save() end)
    TabStats:CreateTextBox("Quantidade", c.ManualAmount, function(v) c.ManualAmount = tonumber(v) or 1; c:Save() end)
    TabStats:CreateButton("➕ Adicionar Pontos", function() 
        local AllocateStatRemote = ReplicatedStorage:FindFirstChild("AllocateStat", true)
        if AllocateStatRemote then AllocateStatRemote:FireServer(c.ManualStat, c.ManualAmount) end 
    end, Color3.fromRGB(40, 150, 80))
    
    TabStats:CreateLabel("--------------------------------------------------------")
    TabStats:CreateLabel("DISTRIBUIÇÃO AUTOMÁTICA (DIVISÃO)")
    for _, stat in ipairs(const.StatsList) do
        local isSelected = table.find(c.SelectedStats, stat) ~= nil
        TabStats:CreateToggle("Auto Upar " .. stat, isSelected, function(v) 
            if v then 
                if not table.find(c.SelectedStats, stat) then table.insert(c.SelectedStats, stat) end 
            else 
                local idx = table.find(c.SelectedStats, stat)
                if idx then table.remove(c.SelectedStats, idx) end 
            end 
            c:Save()
        end)
    end
    TabStats:CreateToggle("Ativar Auto Distribuir", c.AutoStats, function(v) c.AutoStats = v; c:Save() end)
    TabStats:CreateButton("🔄 Reset Status", function() 
        local ResetStatsRemote = ReplicatedStorage:FindFirstChild("ResetStats", true)
        if ResetStatsRemote then ResetStatsRemote:FireServer() end 
    end, Color3.fromRGB(200, 60, 60))

    task.spawn(function()
        while task.wait(1) do
            if not c.IsRunning then break end
            pcall(function() 
                local data = LP:FindFirstChild("Data")
                if data and data:FindFirstChild("StatPoints") then 
                    InfoPoints.Text = "Pontos Disponíveis: " .. tostring(data.StatPoints.Value) 
                else 
                    InfoPoints.Text = "Pontos Disponíveis: 0" 
                end 
            end)
        end
    end)

    -- ==========================================
    -- 🎲 ABA 6: ROLETA
    -- ==========================================
    local TabRoleta = self:CreateTab("Roleta", "🎲")
    TabRoleta:CreateTextBox("Raça Sniper", c.AutoReroll.TargetRace, function(v) c.AutoReroll.TargetRace = tostring(v); c:Save() end)
    TabRoleta:CreateToggle("Iniciar Sniper Raça", c.AutoReroll.Race, function(v) c.AutoReroll.Race = v; c:Save() end)
    TabRoleta:CreateLabel("--------------------------------------------------------")
    TabRoleta:CreateLabel("📦 ABERTURA DE BAÚS")
    TabRoleta:CreateTextBox("Quantidade (9999 = Máximo)", c.ChestOpenAmount or 1, function(v) c.ChestOpenAmount = tonumber(v) or 1; c:Save() end)
    TabRoleta:CreateToggle("Abrir Baús Comuns", c.AutoOpenChests.Common, function(v) c.AutoOpenChests.Common = v; c:Save() end)
    TabRoleta:CreateToggle("Abrir Baús Raros", c.AutoOpenChests.Rare, function(v) c.AutoOpenChests.Rare = v; c:Save() end)
    TabRoleta:CreateToggle("Abrir Baús Épicos", c.AutoOpenChests.Epic, function(v) c.AutoOpenChests.Epic = v; c:Save() end)
    TabRoleta:CreateToggle("Abrir Baús Lendários", c.AutoOpenChests.Legendary, function(v) c.AutoOpenChests.Legendary = v; c:Save() end)
    TabRoleta:CreateToggle("Abrir Baús Míticos", c.AutoOpenChests.Mythical, function(v) c.AutoOpenChests.Mythical = v; c:Save() end)

    -- ==========================================
    -- 🌍 ABA 7: MUNDO
    -- ==========================================
    local TabWorld = self:CreateTab("Mundo", "🌍")
    TabWorld:CreateLabel("PORTAIS INSTANTÂNEOS")
    TabWorld:CreateDropdown("Viajar para Ilha", const.Islands, "Starter", function(ilhaDestino)
        local targetStr = const.TeleportMap[ilhaDestino]
        if targetStr then
            local TeleportRemote = ReplicatedStorage:FindFirstChild("TeleportToPortal", true)
            if TeleportRemote then TeleportRemote:FireServer(targetStr) end
            self:Notify("Teleporte", "Viajando para " .. ilhaDestino, 3)
        end
    end)
    TabWorld:CreateLabel("IR ATÉ NPC (VOANDO)")
    TabWorld:CreateDropdown("Selecione o NPC", const.NPCs, "EnchantNPC", function(npcName)
        local npc = Workspace:FindFirstChild("ServiceNPCs") and Workspace.ServiceNPCs:FindFirstChild(npcName)
        if npc then
            self.FSM.TargetManager:SetInteractionTarget(npc)
            self.FSM.State = "NAVIGATING"
        else
            self:Notify("Erro", "NPC não encontrado na ilha atual.", 3)
        end
    end)

    -- ==========================================
    -- 🕵️‍♂️ ABA 8: NATIVOS
    -- ==========================================
    local TabNativos = self:CreateTab("Nativos", "🕵️‍♂️")
    TabNativos:CreateLabel("HACKS NATIVOS (Controle de Remotes)")
    TabNativos:CreateToggle("Haki do Armamento", c.HacksNativos.HakiArmamento, function(v) 
        c.HacksNativos.HakiArmamento = v; c:Save()
        local HakiRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("HakiRemote")
        if HakiRemote then HakiRemote:FireServer("Toggle") end
    end)
    TabNativos:CreateToggle("Haki da Observação", c.HacksNativos.HakiObservacao, function(v) 
        c.HacksNativos.HakiObservacao = v; c:Save()
        local ObsRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ObservationHakiRemote")
        if ObsRemote then ObsRemote:FireServer("Toggle") end
    end)
    TabNativos:CreateToggle("Hack de Pulos Extras", c.HacksNativos.PuloExtra, function(v) 
        c.HacksNativos.PuloExtra = v; c:Save()
        if not v then pcall(function() LP:SetAttribute("RaceExtraJumps", 0) end) end 
    end)
    
    TabNativos:CreateLabel("QUALIDADE DE VIDA")
    TabNativos:CreateToggle("Remover Tremores (NoShake)", c.HacksNativos.NoShake, function(v) 
        c.HacksNativos.NoShake = v; c:Save(); pcall(function() LP:SetAttribute("DisableScreenShake", v) end) 
    end)
    TabNativos:CreateToggle("Pular Animações (NoCutscene)", c.HacksNativos.NoCutscene, function(v) 
        c.HacksNativos.NoCutscene = v; c:Save(); pcall(function() LP:SetAttribute("DisableCutscene", v) end) 
    end)
    TabNativos:CreateToggle("Modo Proteção PvP", c.HacksNativos.DisablePvP, function(v) 
        c.HacksNativos.DisablePvP = v; c:Save(); pcall(function() LP:SetAttribute("DisablePvP", v) end) 
    end)

    -- ==========================================
    -- 🍎 ABA 9: FRUIT SNIPER
    -- ==========================================
    local TabSniper = self:CreateTab("Fruit V2", "🍎")
    TabSniper:CreateLabel("FRUIT SNIPER NATIVO (REAL-TIME)")
    TabSniper:CreateToggle("Sniper de Frutas Instantâneo", c.FruitSniper, function(v) 
        c.FruitSniper = v; c:Save() 
    end)

    -- ==========================================
    -- ⚙️ ABA 10: MISC
    -- ==========================================
    local TabMisc = self:CreateTab("Misc", "⚙️")
    TabMisc:CreateToggle("Super Velocidade", c.SuperSpeed, function(v) c.SuperSpeed = v; c:Save() end)
    TabMisc:CreateToggle("Pulo Infinito", c.InfJump, function(v) c.InfJump = v; c:Save() end)

end

function Interface:Destroy()
    if self.ScreenGui then self.ScreenGui:Destroy() end
    for _, conn in ipairs(self._connections) do
        if conn then conn:Disconnect() end
    end
end

return Interface
