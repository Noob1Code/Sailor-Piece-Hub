-- =====================================================================
-- 🎨 UI/Interface.lua
-- Responsabilidade: Montar UI e ligar callbacks ao Config/CombatService.
-- =====================================================================
local Interface = {}
Interface.__index = Interface

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

local Theme = {
    Background = Color3.fromRGB(15, 15, 20), Sidebar = Color3.fromRGB(20, 20, 25), Component = Color3.fromRGB(30, 30, 40),
    Accent = Color3.fromRGB(45, 100, 255), Text = Color3.fromRGB(255, 255, 255), TextDim = Color3.fromRGB(180, 180, 180),
    Green = Color3.fromRGB(40, 180, 80), Red = Color3.fromRGB(220, 60, 60)
}

function Interface.new(Config, FSM, Constants, CombatService)
    local self = setmetatable({}, Interface)
    self.Config = Config; self.FSM = FSM; self.Constants = Constants; self.CombatService = CombatService
    self.Connections = {}; self.Tabs = {}; self.CurrentTab = nil
    self:BuildUI()
    return self
end

function Interface:Destroy()
    if self.ScreenGui then self.ScreenGui:Destroy() end
    for _, conn in ipairs(self.Connections) do if conn then conn:Disconnect() end end
    self.Connections = {}
end

function Interface:Notify(title, text, duration)
    duration = duration or 3 
    local Notif = Instance.new("Frame"); Notif.Size = UDim2.new(1, 0, 0, 60); Notif.BackgroundColor3 = Theme.Component; Notif.BackgroundTransparency = 1 
    Instance.new("UICorner", Notif).CornerRadius = UDim.new(0, 6)
    
    local SideBar = Instance.new("Frame"); SideBar.Size = UDim2.new(0, 4, 1, 0); SideBar.BackgroundColor3 = Theme.Accent; SideBar.BorderSizePixel = 0
    SideBar.BackgroundTransparency = 1; SideBar.Parent = Notif; Instance.new("UICorner", SideBar).CornerRadius = UDim.new(0, 6)
    
    local TitleLbl = Instance.new("TextLabel"); TitleLbl.Size = UDim2.new(1, -20, 0, 20); TitleLbl.Position = UDim2.new(0, 15, 0, 5)
    TitleLbl.BackgroundTransparency = 1; TitleLbl.Text = title; TitleLbl.TextColor3 = Theme.Text; TitleLbl.TextTransparency = 1; TitleLbl.Font = Enum.Font.GothamBold; TitleLbl.TextSize = 13; TitleLbl.TextXAlignment = Enum.TextXAlignment.Left; TitleLbl.Parent = Notif

    local DescLbl = Instance.new("TextLabel"); DescLbl.Size = UDim2.new(1, -20, 0, 30); DescLbl.Position = UDim2.new(0, 15, 0, 25)
    DescLbl.BackgroundTransparency = 1; DescLbl.Text = text; DescLbl.TextColor3 = Theme.TextDim; DescLbl.TextTransparency = 1; DescLbl.Font = Enum.Font.Gotham; DescLbl.TextSize = 11; DescLbl.TextWrapped = true; DescLbl.TextXAlignment = Enum.TextXAlignment.Left; DescLbl.Parent = Notif

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
        fadeOut:Play(); fadeOut.Completed:Wait(); Notif:Destroy()
    end)
end

function Interface:CreateTab(name, icon)
    local Tab = { Window = self }
    
    local TabBtn = Instance.new("TextButton"); TabBtn.Size = UDim2.new(1, 0, 0, 35); TabBtn.BackgroundColor3 = Theme.Sidebar; TabBtn.BorderSizePixel = 0
    TabBtn.TextColor3 = Theme.TextDim; TabBtn.Text = "  " .. (icon or "") .. " " .. name; TabBtn.Font = Enum.Font.GothamSemibold; TabBtn.TextSize = 13; TabBtn.TextXAlignment = Enum.TextXAlignment.Left
    TabBtn.Parent = self.TabSelector; TabBtn.AutoButtonColor = false 
    
    local TabContent = Instance.new("ScrollingFrame"); TabContent.Size = UDim2.new(1, -10, 1, -10); TabContent.Position = UDim2.new(0, 5, 0, 5)
    TabContent.BackgroundTransparency = 1; TabContent.ScrollBarThickness = 2; TabContent.Visible = false; TabContent.Parent = self.ContentContainer
    
    local ContentLayout = Instance.new("UIListLayout"); ContentLayout.Parent = TabContent; ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder; ContentLayout.Padding = UDim.new(0, 8) 
    table.insert(self.Connections, ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() TabContent.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 10) end))

    table.insert(self.Connections, TabBtn.MouseEnter:Connect(function() if self.CurrentTab ~= TabContent then TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(28, 28, 35)}):Play() end end))
    table.insert(self.Connections, TabBtn.MouseLeave:Connect(function() if self.CurrentTab ~= TabContent then TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Sidebar}):Play() end end))
    table.insert(self.Connections, TabBtn.MouseButton1Click:Connect(function()
        for _, tabInfo in pairs(self.Tabs) do tabInfo.Content.Visible = false; TweenService:Create(tabInfo.Button, TweenInfo.new(0.3), {BackgroundColor3 = Theme.Sidebar, TextColor3 = Theme.TextDim}):Play() end
        TabContent.Visible = true; self.CurrentTab = TabContent; TweenService:Create(TabBtn, TweenInfo.new(0.3), {BackgroundColor3 = Theme.Accent, TextColor3 = Theme.Text}):Play()
    end))

    if not self.CurrentTab then TabContent.Visible = true; TabBtn.BackgroundColor3 = Theme.Accent; TabBtn.TextColor3 = Theme.Text; self.CurrentTab = TabContent end
    table.insert(self.Tabs, {Button = TabBtn, Content = TabContent}); Tab.Container = TabContent

    function Tab:CreateLabel(text)
        local Label = Instance.new("TextLabel"); Label.Size = UDim2.new(1, 0, 0, 20); Label.BackgroundTransparency = 1; Label.TextColor3 = Color3.fromRGB(150, 150, 180); Label.Text = text; Label.TextXAlignment = Enum.TextXAlignment.Left; Label.Font = Enum.Font.GothamBold; Label.TextSize = 12; Label.Parent = self.Container
        return Label
    end

    function Tab:CreateButton(text, callback, customColor)
        local color = customColor or Theme.Accent; local Btn = Instance.new("TextButton")
        Btn.Size = UDim2.new(1, -5, 0, 32); Btn.BackgroundColor3 = color; Btn.TextColor3 = Theme.Text; Btn.Text = text
        Btn.Font = Enum.Font.GothamSemibold; Btn.TextSize = 13; Btn.Parent = self.Container; Btn.AutoButtonColor = false
        Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
        table.insert(Tab.Window.Connections, Btn.MouseEnter:Connect(function() TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(math.clamp(color.R*255+20, 0, 255), math.clamp(color.G*255+20, 0, 255), math.clamp(color.B*255+20, 0, 255))}):Play() end))
        table.insert(Tab.Window.Connections, Btn.MouseLeave:Connect(function() TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play() end))
        table.insert(Tab.Window.Connections, Btn.MouseButton1Click:Connect(function() callback() end))
        return Btn
    end

    function Tab:CreateToggle(text, defaultState, callback)
        local state = defaultState; local colorOn = Theme.Green; local colorOff = Color3.fromRGB(40, 40, 50)
        local ToggleBtn = Instance.new("TextButton"); ToggleBtn.Size = UDim2.new(1, -5, 0, 32); ToggleBtn.BackgroundColor3 = state and colorOn or colorOff; ToggleBtn.TextColor3 = Theme.Text; ToggleBtn.Text = text .. " [" .. (state and "ON" or "OFF") .. "]"; ToggleBtn.Font = Enum.Font.GothamSemibold; ToggleBtn.TextSize = 13; ToggleBtn.Parent = self.Container; ToggleBtn.AutoButtonColor = false
        Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 4)
        table.insert(Tab.Window.Connections, ToggleBtn.MouseEnter:Connect(function() TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = state and Color3.fromRGB(50, 200, 90) or Color3.fromRGB(50, 50, 60)}):Play() end))
        table.insert(Tab.Window.Connections, ToggleBtn.MouseLeave:Connect(function() TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = state and colorOn or colorOff}):Play() end))
        table.insert(Tab.Window.Connections, ToggleBtn.MouseButton1Click:Connect(function()
            state = not state; TweenService:Create(ToggleBtn, TweenInfo.new(0.3), {BackgroundColor3 = state and colorOn or colorOff}):Play()
            ToggleBtn.Text = text .. " [" .. (state and "ON" or "OFF") .. "]"
            callback(state); if Tab.Window.Config.Save then Tab.Window.Config:Save() end
        end))
    end

    function Tab:CreateDropdown(title, options, defaultOption, callback)
        options = options or {"Nenhum"}; defaultOption = defaultOption or options[1] or "Nenhum"
        local DropFrame = Instance.new("Frame"); DropFrame.Size = UDim2.new(1, -5, 0, 32); DropFrame.BackgroundColor3 = Theme.Component; DropFrame.ClipsDescendants = true; DropFrame.Parent = self.Container; Instance.new("UICorner", DropFrame).CornerRadius = UDim.new(0, 4)
        local MainBtn = Instance.new("TextButton"); MainBtn.Size = UDim2.new(1, 0, 0, 32); MainBtn.BackgroundTransparency = 1; MainBtn.TextColor3 = Theme.Text; MainBtn.Text = "  " .. title .. ": " .. tostring(defaultOption); MainBtn.Font = Enum.Font.GothamSemibold; MainBtn.TextSize = 12; MainBtn.TextXAlignment = Enum.TextXAlignment.Left; MainBtn.Parent = DropFrame
        local Arrow = Instance.new("TextLabel"); Arrow.Size = UDim2.new(0, 30, 1, 0); Arrow.Position = UDim2.new(1, -30, 0, 0); Arrow.BackgroundTransparency = 1; Arrow.Text = "▼"; Arrow.TextColor3 = Theme.TextDim; Arrow.Font = Enum.Font.GothamBold; Arrow.Parent = MainBtn
        local ListFrame = Instance.new("ScrollingFrame"); ListFrame.Size = UDim2.new(1, 0, 1, -32); ListFrame.Position = UDim2.new(0, 0, 0, 32); ListFrame.BackgroundTransparency = 1; ListFrame.ScrollBarThickness = 2; ListFrame.Parent = DropFrame
        local ListLayout = Instance.new("UIListLayout"); ListLayout.Parent = ListFrame; local isOpen = false

        local function updateSelection(opt)
            MainBtn.Text = "  " .. title .. ": " .. tostring(opt); callback(opt); isOpen = false
            TweenService:Create(DropFrame, TweenInfo.new(0.3), {Size = UDim2.new(1, -5, 0, 32)}):Play(); Arrow.Text = "▼"
            if Tab.Window.Config.Save then Tab.Window.Config:Save() end
        end

        table.insert(Tab.Window.Connections, MainBtn.MouseButton1Click:Connect(function()
            isOpen = not isOpen; local targetHeight = isOpen and math.min(ListLayout.AbsoluteContentSize.Y + 32, 140) or 32
            TweenService:Create(DropFrame, TweenInfo.new(0.3), {Size = UDim2.new(1, -5, 0, targetHeight)}):Play(); Arrow.Text = isOpen and "▲" or "▼"
            ListFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y)
        end))

        local function refresh(newOptions)
            newOptions = newOptions or {"Nenhum"}; if #newOptions == 0 then newOptions = {"Nenhum"} end
            for _, b in pairs(ListFrame:GetChildren()) do if b:IsA("TextButton") then b:Destroy() end end
            for _, opt in ipairs(newOptions) do
                local OptBtn = Instance.new("TextButton"); OptBtn.Size = UDim2.new(1, 0, 0, 28); OptBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45); OptBtn.TextColor3 = Theme.TextDim; OptBtn.Text = "  " .. tostring(opt); OptBtn.Font = Enum.Font.Gotham; OptBtn.TextSize = 12; OptBtn.TextXAlignment = Enum.TextXAlignment.Left; OptBtn.Parent = ListFrame; OptBtn.AutoButtonColor = false
                table.insert(Tab.Window.Connections, OptBtn.MouseEnter:Connect(function() TweenService:Create(OptBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Accent, TextColor3 = Theme.Text}):Play() end))
                table.insert(Tab.Window.Connections, OptBtn.MouseLeave:Connect(function() TweenService:Create(OptBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 35, 45), TextColor3 = Theme.TextDim}):Play() end))
                table.insert(Tab.Window.Connections, OptBtn.MouseButton1Click:Connect(function() updateSelection(opt) end))
            end
            local safeOpt = newOptions[1] or "Nenhum"; MainBtn.Text = "  " .. title .. ": " .. tostring(safeOpt); callback(safeOpt)
        end
        refresh(options); MainBtn.Text = "  " .. title .. ": " .. tostring(defaultOption)
        return { Refresh = refresh }
    end

    function Tab:CreateTextBox(title, defaultText, callback)
        local Container = Instance.new("Frame"); Container.Size = UDim2.new(1, -5, 0, 32); Container.BackgroundColor3 = Theme.Component; Container.Parent = self.Container; Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 4)
        local Label = Instance.new("TextLabel"); Label.Size = UDim2.new(0.6, 0, 1, 0); Label.BackgroundTransparency = 1; Label.TextColor3 = Theme.TextDim; Label.Text = "  " .. title; Label.Font = Enum.Font.GothamSemibold; Label.TextSize = 12; Label.TextXAlignment = Enum.TextXAlignment.Left; Label.Parent = Container
        local TextBox = Instance.new("TextBox"); TextBox.Size = UDim2.new(0.35, -5, 0.8, 0); TextBox.Position = UDim2.new(0.65, 0, 0.1, 0); TextBox.BackgroundColor3 = Theme.Sidebar; TextBox.TextColor3 = Theme.Text; TextBox.Text = tostring(defaultText); TextBox.Font = Enum.Font.Gotham; TextBox.TextSize = 12; TextBox.Parent = Container; Instance.new("UICorner", TextBox).CornerRadius = UDim.new(0, 4)
        table.insert(Tab.Window.Connections, TextBox.FocusLost:Connect(function() 
            local val = TextBox.Text; if tonumber(val) then callback(tonumber(val)) else callback(val) end; if Tab.Window.Config.Save then Tab.Window.Config:Save() end
        end))
    end
    return Tab
end

function Interface:BuildUI()
    local uiParent = pcall(function() return CoreGui.Name end) and CoreGui or LP:WaitForChild("PlayerGui")
    if uiParent:FindFirstChild("ComunidadeHubGUI") then uiParent.ComunidadeHubGUI:Destroy() end
    
    self.ScreenGui = Instance.new("ScreenGui"); self.ScreenGui.Name = "ComunidadeHubGUI"; self.ScreenGui.Parent = uiParent; self.ScreenGui.ResetOnSpawn = false
    self.MainFrame = Instance.new("Frame"); self.MainFrame.Size = UDim2.new(0, 540, 0, 460); self.MainFrame.Position = UDim2.new(0.5, -270, 0.5, -230); self.MainFrame.BackgroundColor3 = Theme.Background; self.MainFrame.ClipsDescendants = true; self.MainFrame.Parent = self.ScreenGui; Instance.new("UICorner", self.MainFrame).CornerRadius = UDim.new(0, 8)
    
    local TitleBar = Instance.new("TextButton"); TitleBar.Size = UDim2.new(1, 0, 0, 40); TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 30); TitleBar.TextColor3 = Theme.Text; TitleBar.Text = "   🌟 Sailor Piece Hub V2 (Modular OOP)"; TitleBar.Font = Enum.Font.GothamBold; TitleBar.TextSize = 14; TitleBar.TextXAlignment = Enum.TextXAlignment.Left; TitleBar.Parent = self.MainFrame; TitleBar.AutoButtonColor = false; Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 8)
    
    local dragging, dragInput, dragStart, startPos
    table.insert(self.Connections, TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; dragStart = input.Position; startPos = self.MainFrame.Position; input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end) end
    end))
    table.insert(self.Connections, TitleBar.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end))
    table.insert(self.Connections, UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then local delta = input.Position - dragStart; self.MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end))

    self.TabSelector = Instance.new("ScrollingFrame"); self.TabSelector.Size = UDim2.new(0, 150, 1, -40); self.TabSelector.Position = UDim2.new(0, 0, 0, 40); self.TabSelector.BackgroundColor3 = Theme.Sidebar; self.TabSelector.BorderSizePixel = 0; self.TabSelector.ScrollBarThickness = 2; self.TabSelector.Parent = self.MainFrame; Instance.new("UIListLayout", self.TabSelector).Padding = UDim.new(0, 2)
    self.ContentContainer = Instance.new("Frame"); self.ContentContainer.Size = UDim2.new(1, -150, 1, -40); self.ContentContainer.Position = UDim2.new(0, 150, 0, 40); self.ContentContainer.BackgroundTransparency = 1; self.ContentContainer.Parent = self.MainFrame

    local CloseBtn = Instance.new("TextButton"); CloseBtn.Size = UDim2.new(0, 30, 0, 30); CloseBtn.Position = UDim2.new(1, -35, 0.5, -15); CloseBtn.BackgroundTransparency = 1; CloseBtn.TextColor3 = Theme.Red; CloseBtn.Text = "X"; CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.Parent = TitleBar
    table.insert(self.Connections, CloseBtn.MouseButton1Click:Connect(function() if _G.ComunidadeHub_Cleanup then _G.ComunidadeHub_Cleanup() end end))

    local MinBtn = Instance.new("TextButton"); MinBtn.Size = UDim2.new(0, 30, 0, 30); MinBtn.Position = UDim2.new(1, -65, 0.5, -15); MinBtn.BackgroundTransparency = 1; MinBtn.TextColor3 = Theme.Text; MinBtn.Text = "-"; MinBtn.Font = Enum.Font.GothamBold; MinBtn.Parent = TitleBar
    local isMinimized = false
    table.insert(self.Connections, MinBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized; MinBtn.Text = isMinimized and "+" or "-"
        self.MainFrame:TweenSize(isMinimized and UDim2.new(0, 540, 0, 40) or UDim2.new(0, 540, 0, 460), "Out", "Quart", 0.3, true)
        self.TabSelector.Visible = not isMinimized; self.ContentContainer.Visible = not isMinimized
    end))

    self.NotifyFrame = Instance.new("Frame"); self.NotifyFrame.Size = UDim2.new(0, 220, 1, -20); self.NotifyFrame.Position = UDim2.new(1, -240, 0, 10); self.NotifyFrame.BackgroundTransparency = 1; self.NotifyFrame.Parent = self.ScreenGui
    local NotifyLayout = Instance.new("UIListLayout"); NotifyLayout.Parent = self.NotifyFrame; NotifyLayout.SortOrder = Enum.SortOrder.LayoutOrder; NotifyLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom; NotifyLayout.Padding = UDim.new(0, 10)

    -- Exportar Notificações para o Escopo Global (Para o FSM usar)
    _G.SendToast = function(title, text, time) self:Notify(title, text, time) end

    -- ==========================================
    -- 🧩 MONTAGEM DAS ABAS E CONEXÕES
    -- ==========================================
    local function GetMobs(island)
        local l = {"Nenhum", "Todos"}
        if island == "Todas" then for _, d in pairs(self.Constants.IslandDataMap) do if d.Mobs then for _, m in ipairs(d.Mobs) do table.insert(l, m) end end end
        else if self.Constants.IslandDataMap[island] and self.Constants.IslandDataMap[island].Mobs then for _, m in ipairs(self.Constants.IslandDataMap[island].Mobs) do table.insert(l, m) end end end
        return l
    end
    local function GetBosses(island)
        local l = {"Nenhum"}
        if island == "Todas" then for _, d in pairs(self.Constants.IslandDataMap) do if d.Bosses then for _, b in ipairs(d.Bosses) do table.insert(l, b) end end end
        else if self.Constants.IslandDataMap[island] and self.Constants.IslandDataMap[island].Bosses then for _, b in ipairs(self.Constants.IslandDataMap[island].Bosses) do table.insert(l, b) end end end
        return l
    end
    local function GetQuests(island)
        local l = {"Nenhum"}
        if self.Constants.QuestDataMap[island] then for _, q in ipairs(self.Constants.QuestDataMap[island]) do table.insert(l, q.Name) end end
        return l
    end
    local function GetWeapons()
        local w = {"Nenhuma"}; local char = LP.Character; local bp = LP:FindFirstChild("Backpack")
        if bp then for _, t in pairs(bp:GetChildren()) do if t:IsA("Tool") and not table.find(w, t.Name) then table.insert(w, t.Name) end end end
        if char then for _, t in pairs(char:GetChildren()) do if t:IsA("Tool") and not table.find(w, t.Name) then table.insert(w, t.Name) end end end
        return w
    end

    -- DASHBOARD
    local TabDash = self:CreateTab("Dashboard", "📊")
    TabDash:CreateLabel("INFORMAÇÕES DO JOGADOR")
    local InfoRace = TabDash:CreateLabel("Raça: Carregando..."); local InfoClan = TabDash:CreateLabel("Clã: Carregando...")
    local InfoDamage = TabDash:CreateLabel("Bônus: Carregando..."); local InfoPity = TabDash:CreateLabel("Sorte: Carregando...")
    task.spawn(function()
        while self.Config.IsRunning and task.wait(1) do pcall(function()
            InfoRace.Text = "Raça: " .. tostring(LP:GetAttribute("CurrentRace") or "Humano") .. " (+" .. tostring(LP:GetAttribute("RaceExtraJumps") or 0) .. " Pulos)"
            InfoClan.Text = "Clã: " .. tostring(LP:GetAttribute("CurrentClan") or "Nenhum")
            InfoDamage.Text = "Melee [" .. tostring(LP:GetAttribute("RaceMeleeDamage") or 0) .. "] | Sword [" .. tostring(LP:GetAttribute("RaceSwordDamage") or 0) .. "]"
            InfoPity.Text = "Sorte: " .. tostring(LP:GetAttribute("RaceLuckBonus") or 0)
        end) end
    end)

    -- MISSÕES
    local TabMissions = self:CreateTab("Missões", "📜")
    TabMissions:CreateLabel("⚡ MODO AUTO LEVEL MÁXIMO")
    TabMissions:CreateToggle("Auto Farm (Progressão Automática)", self.Config.AutoFarmMaxLevel, function(v) self.Config.AutoFarmMaxLevel = v; if v then self.Config.AutoQuest = false end end)
    TabMissions:CreateLabel("🎯 MODO MISSÃO MANUAL")
    local questRef
    TabMissions:CreateDropdown("Ilha", self.Constants.QuestFilterOptions, self.Config.SelectedQuestIsland, function(s) self.Config.SelectedQuestIsland = s; if questRef then questRef.Refresh(GetQuests(s)) end end)
    questRef = TabMissions:CreateDropdown("Missão", GetQuests(self.Config.SelectedQuestIsland), self.Config.SelectedQuest, function(s) self.Config.SelectedQuest = s end)
    TabMissions:CreateToggle("Auto Quest (Manual)", self.Config.AutoQuest, function(v) self.Config.AutoQuest = v; if v then self.Config.AutoFarmMaxLevel = false end end)

    -- COMBATE
    local TabCombat = self:CreateTab("Combate", "⚔️")
    TabCombat:CreateLabel("🔍 SISTEMA DE MAPA")
    local mobRef, bossRef
    TabCombat:CreateDropdown("Filtro de Ilha", self.Constants.FilterOptions, self.Config.SelectedIslandFilter, function(s) self.Config.SelectedIslandFilter = s; if mobRef then mobRef.Refresh(GetMobs(s)) end; if bossRef then bossRef.Refresh(GetBosses(s)) end end)
    mobRef = TabCombat:CreateDropdown("Alvo (Mob)", GetMobs(self.Config.SelectedIslandFilter), self.Config.SelectedMob, function(s) self.Config.SelectedMob = s end)
    TabCombat:CreateToggle("Auto Farm Mobs", self.Config.AutoFarm, function(v) self.Config.AutoFarm = v end)

    TabCombat:CreateLabel("👑 FILA DE BOSSES")
    bossRef = TabCombat:CreateDropdown("Alvo (Boss)", GetBosses(self.Config.SelectedIslandFilter), self.Config.SelectedBoss, function(s) self.Config.SelectedBoss = s end)
    local BossListLbl = TabCombat:CreateLabel("Fila: " .. (#self.Config.SelectedBosses > 0 and table.concat(self.Config.SelectedBosses, ", ") or "Nenhuma"))
    TabCombat:CreateButton("➕ Adicionar", function() if self.Config.SelectedBoss ~= "Nenhum" and not table.find(self.Config.SelectedBosses, self.Config.SelectedBoss) then table.insert(self.Config.SelectedBosses, self.Config.SelectedBoss); BossListLbl.Text = "Fila: " .. table.concat(self.Config.SelectedBosses, ", "); self.Config:Save() end end, Theme.Green)
    TabCombat:CreateButton("🗑️ Limpar", function() self.Config.SelectedBosses = {}; BossListLbl.Text = "Fila: Nenhuma"; self.Config:Save() end, Theme.Red)
    TabCombat:CreateToggle("Auto Boss (Fila)", self.Config.AutoBoss, function(v) self.Config.AutoBoss = v end)
    
    TabCombat:CreateLabel("🔮 INVOCAÇÃO (SUMMON)")
    TabCombat:CreateDropdown("Boss para Invocar", self.Constants.SummonBossList, self.Config.SelectedSummonBoss, function(s) self.Config.SelectedSummonBoss = s end)
    TabCombat:CreateToggle("Auto Invocar e Farmar", self.Config.AutoSummon, function(v) self.Config.AutoSummon = v end)

    TabCombat:CreateLabel("⚙️ INTELIGÊNCIA DE ATAQUE")
    TabCombat:CreateDropdown("Posição", {"Atrás", "Acima", "Abaixo", "Orbital"}, self.Config.AttackPosition, function(s) self.Config.AttackPosition = s end)
    TabCombat:CreateTextBox("Velocidade (Tween)", self.Config.TweenSpeed, function(v) self.Config.TweenSpeed = v end)
    TabCombat:CreateTextBox("Distância", self.Config.Distance, function(v) self.Config.Distance = v end)

    local wpnRef = TabCombat:CreateDropdown("Arma", GetWeapons(), self.Config.SelectedWeapon, function(s) self.Config.SelectedWeapon = s end)
    TabCombat:CreateButton("Atualizar Armas", function() if wpnRef then wpnRef.Refresh(GetWeapons()) end end)

    -- ITENS
    local TabCollect = self:CreateTab("Itens", "🎒")
    TabCollect:CreateToggle("Auto Group Reward", self.Config.AutoGroupReward, function(v) self.Config.AutoGroupReward = v end)
    TabCollect:CreateToggle("Fruit Sniper Instantâneo", self.Config.FruitSniper, function(v) self.Config.FruitSniper = v end)
    TabCollect:CreateToggle("Coletar Frutas (Chão)", self.Config.AutoCollect.Fruits, function(v) self.Config.AutoCollect.Fruits = v end)
    TabCollect:CreateToggle("Coletar Hogyoku", self.Config.AutoCollect.Hogyoku, function(v) self.Config.AutoCollect.Hogyoku = v end)
    TabCollect:CreateToggle("Coletar Puzzles", self.Config.AutoCollect.Puzzles, function(v) self.Config.AutoCollect.Puzzles = v end)
    TabCollect:CreateToggle("Coletar Baús", self.Config.AutoCollect.Chests, function(v) self.Config.AutoCollect.Chests = v end)

    -- STATUS & ROLETAS
    local TabStats = self:CreateTab("Status", "📈")
    for _, stat in ipairs(self.Constants.StatsList) do
        local isSelected = table.find(self.Config.SelectedStats, stat) ~= nil
        TabStats:CreateToggle("Focar em " .. stat, isSelected, function(v) 
            if v then if not table.find(self.Config.SelectedStats, stat) then table.insert(self.Config.SelectedStats, stat) end else local idx = table.find(self.Config.SelectedStats, stat); if idx then table.remove(self.Config.SelectedStats, idx) end end 
        end)
    end
    TabStats:CreateToggle("Auto Distribuir", self.Config.AutoStats, function(v) self.Config.AutoStats = v end)

    TabStats:CreateLabel("ROLETAS E BAÚS")
    TabStats:CreateDropdown("Raça Alvo", {"Kitsune", "Mink", "Fishman", "Human", "Skypiean"}, self.Config.AutoReroll.TargetRace, function(s) self.Config.AutoReroll.TargetRace = s end)
    TabStats:CreateToggle("Auto Reroll Raça", self.Config.AutoReroll.Race, function(v) self.Config.AutoReroll.Race = v end)
    TabStats:CreateToggle("Abrir Baús Lendários", self.Config.AutoOpenChests.Legendary, function(v) self.Config.AutoOpenChests.Legendary = v end)
    TabStats:CreateToggle("Abrir Baús Míticos", self.Config.AutoOpenChests.Mythical, function(v) self.Config.AutoOpenChests.Mythical = v end)

    -- NATIVOS
    local TabNativos = self:CreateTab("Nativos", "🕵️‍♂️")
    TabNativos:CreateToggle("Haki do Armamento", self.Config.HacksNativos.HakiArmamento, function(v) self.Config.HacksNativos.HakiArmamento = v; self.CombatService:ToggleHaki("Armamento") end)
    TabNativos:CreateToggle("Haki da Observação", self.Config.HacksNativos.HakiObservacao, function(v) self.Config.HacksNativos.HakiObservacao = v; self.CombatService:ToggleHaki("Observacao") end)
    TabNativos:CreateToggle("Hack de Pulos Extras", self.Config.HacksNativos.PuloExtra, function(v) self.Config.HacksNativos.PuloExtra = v; if not v then pcall(function() LP:SetAttribute("RaceExtraJumps", 0) end) end end)
    TabNativos:CreateToggle("Remover Tremores", self.Config.HacksNativos.NoShake, function(v) self.Config.HacksNativos.NoShake = v; pcall(function() LP:SetAttribute("DisableScreenShake", v) end) end)
    TabNativos:CreateToggle("Pular Cutscenes", self.Config.HacksNativos.NoCutscene, function(v) self.Config.HacksNativos.NoCutscene = v; pcall(function() LP:SetAttribute("DisableCutscene", v) end) end)
    TabNativos:CreateToggle("Proteção PvP", self.Config.HacksNativos.DisablePvP, function(v) self.Config.HacksNativos.DisablePvP = v; pcall(function() LP:SetAttribute("DisablePvP", v) end) end)

    -- MUNDO
    local TabWorld = self:CreateTab("Mundo", "🌍")
    TabWorld:CreateDropdown("Viajar Instanteamente", self.Constants.Islands, "Starter", function(s) self.CombatService.Remotes.Teleport:FireServer(self.Constants.TeleportMap[s] or s) end)

    self:Notify("Hub Injetado", "Arquitetura OOP Premium construída com sucesso!", 4)
end

return Interface
