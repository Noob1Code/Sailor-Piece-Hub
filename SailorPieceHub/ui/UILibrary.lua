-- =========================================================================
-- 🎨 UILibrary (Motor Gráfico)
-- Extraído do antigo 4_Interface.lua. Apenas desenha botões, sem lógica.
-- =========================================================================

local GameServices = Import("core/GameServices")
local LP = GameServices.LocalPlayer
local CoreGui = GameServices.CoreGui
local UserInputService = GameServices.UserInputService
local TweenService = GameServices.TweenService

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

    self.TabSelector = Instance.new("ScrollingFrame"); self.TabSelector.Size = UDim2.new(0, 150, 1, -40); self.TabSelector.Position = UDim2.new(0, 0, 40, 0); self.TabSelector.BackgroundColor3 = Color3.fromRGB(20, 20, 25); self.TabSelector.BorderSizePixel = 0; self.TabSelector.ScrollBarThickness = 2; self.TabSelector.Parent = self.MainFrame
    Instance.new("UIListLayout", self.TabSelector).Padding = UDim.new(0, 2)
    self.ContentContainer = Instance.new("Frame"); self.ContentContainer.Size = UDim2.new(1, -150, 1, -40); self.ContentContainer.Position = UDim2.new(0, 150, 0, 40); self.ContentContainer.BackgroundTransparency = 1; self.ContentContainer.Parent = self.MainFrame

    local function doCleanup()
        if _G.ComunidadeHub_App then _G.ComunidadeHub_App:Destroy() end
    end

    local CloseBtn = Instance.new("TextButton"); CloseBtn.Size = UDim2.new(0, 30, 0, 30); CloseBtn.Position = UDim2.new(1, -35, 0.5, -15); CloseBtn.BackgroundTransparency = 1; CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80); CloseBtn.Text = "X"; CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.Parent = TitleBar
    CloseBtn.MouseButton1Click:Connect(doCleanup)

    local MinBtn = Instance.new("TextButton"); MinBtn.Size = UDim2.new(0, 30, 0, 30); MinBtn.Position = UDim2.new(1, -65, 0.5, -15); MinBtn.BackgroundTransparency = 1; MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255); MinBtn.Text = "-"; MinBtn.Font = Enum.Font.GothamBold; MinBtn.Parent = TitleBar
    local isMinimized = false
    MinBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized; MinBtn.Text = isMinimized and "+" or "-"
        self.MainFrame:TweenSize(isMinimized and UDim2.new(0, 540, 0, 40) or UDim2.new(0, 540, 0, 460), "Out", "Quart", 0.3, true)
        self.TabSelector.Visible = not isMinimized; self.ContentContainer.Visible = not isMinimized
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

    return self
end

function Library:Notify(title, text, duration)
    duration = duration or 3 
    local Notif = Instance.new("Frame")
    Notif.Size = UDim2.new(1, 0, 0, 60)
    Notif.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    Notif.BackgroundTransparency = 1 
    Instance.new("UICorner", Notif).CornerRadius = UDim.new(0, 6)
    
    local SideBar = Instance.new("Frame")
    SideBar.Size = UDim2.new(0, 4, 1, 0)
    SideBar.BackgroundColor3 = Color3.fromRGB(80, 150, 255)
    SideBar.BorderSizePixel = 0
    SideBar.BackgroundTransparency = 1
    SideBar.Parent = Notif
    Instance.new("UICorner", SideBar).CornerRadius = UDim.new(0, 6)
    
    local TitleLbl = Instance.new("TextLabel")
    TitleLbl.Size = UDim2.new(1, -20, 0, 20)
    TitleLbl.Position = UDim2.new(0, 15, 0, 5)
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.Text = title
    TitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLbl.TextTransparency = 1
    TitleLbl.Font = Enum.Font.GothamBold
    TitleLbl.TextSize = 13
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    TitleLbl.Parent = Notif

    local DescLbl = Instance.new("TextLabel")
    DescLbl.Size = UDim2.new(1, -20, 0, 30)
    DescLbl.Position = UDim2.new(0, 15, 0, 25)
    DescLbl.BackgroundTransparency = 1
    DescLbl.Text = text
    DescLbl.TextColor3 = Color3.fromRGB(180, 180, 180)
    DescLbl.TextTransparency = 1
    DescLbl.Font = Enum.Font.Gotham
    DescLbl.TextSize = 11
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

function Library:CreateTab(name, icon)
    local Tab = {}
    Tab.Window = self
    
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(1, 0, 0, 35)
    TabBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    TabBtn.BorderSizePixel = 0
    TabBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
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
    ContentLayout.Padding = UDim.new(0, 8) 
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
        TabContent.Visible = true
        TabBtn.BackgroundColor3 = Color3.fromRGB(45, 100, 255)
        TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        self.CurrentTab = TabContent 
    end
    table.insert(self.Tabs, {Button = TabBtn, Content = TabContent})
    Tab.Container = TabContent

    function Tab:CreateLabel(text)
        local Label = Instance.new("TextLabel"); Label.Size = UDim2.new(1, 0, 0, 20); Label.BackgroundTransparency = 1; Label.TextColor3 = Color3.fromRGB(150, 150, 180); Label.Text = text; Label.TextXAlignment = Enum.TextXAlignment.Left; Label.Font = Enum.Font.GothamBold; Label.TextSize = 12; Label.Parent = self.Container
        return Label
    end

    function Tab:CreateButton(text, callback, color)
        local baseColor = color or Color3.fromRGB(45, 100, 255)
        local hoverColor = Color3.fromRGB(math.clamp(baseColor.R*255 + 20, 0, 255), math.clamp(baseColor.G*255 + 20, 0, 255), math.clamp(baseColor.B*255 + 20, 0, 255))
        local Btn = Instance.new("TextButton"); Btn.Size = UDim2.new(1, -5, 0, 32); Btn.BackgroundColor3 = baseColor; Btn.TextColor3 = Color3.fromRGB(255, 255, 255); Btn.Text = text; Btn.Font = Enum.Font.GothamSemibold; Btn.TextSize = 13; Btn.Parent = self.Container; Btn.AutoButtonColor = false
        Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
        Btn.MouseEnter:Connect(function() TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor}):Play() end)
        Btn.MouseLeave:Connect(function() TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = baseColor}):Play() end)
        Btn.MouseButton1Click:Connect(function() TweenService:Create(Btn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {Size = UDim2.new(0.98, -5, 0, 30)}):Play(); callback() end)
        return Btn
    end

    function Tab:CreateToggle(text, defaultState, callback)
        local state = defaultState
        local colorOn, colorOff = Color3.fromRGB(40, 180, 80), Color3.fromRGB(40, 40, 50)
        local ToggleBtn = Instance.new("TextButton"); ToggleBtn.Size = UDim2.new(1, -5, 0, 32); ToggleBtn.BackgroundColor3 = state and colorOn or colorOff; ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255); ToggleBtn.Text = text .. " [" .. (state and "ON" or "OFF") .. "]"; ToggleBtn.Font = Enum.Font.GothamSemibold; ToggleBtn.TextSize = 13; ToggleBtn.Parent = self.Container; ToggleBtn.AutoButtonColor = false
        Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 4)
        ToggleBtn.MouseEnter:Connect(function() TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = state and Color3.fromRGB(50, 200, 90) or Color3.fromRGB(50, 50, 60)}):Play() end)
        ToggleBtn.MouseLeave:Connect(function() TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = state and colorOn or colorOff}):Play() end)
        ToggleBtn.MouseButton1Click:Connect(function() state = not state; TweenService:Create(ToggleBtn, TweenInfo.new(0.3), {BackgroundColor3 = state and colorOn or colorOff}):Play(); ToggleBtn.Text = text .. " [" .. (state and "ON" or "OFF") .. "]"; callback(state) end)
    end

    function Tab:CreateDropdown(title, options, defaultOption, callback)
        local DropFrame = Instance.new("Frame"); DropFrame.Size = UDim2.new(1, -5, 0, 32); DropFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40); DropFrame.ClipsDescendants = true; DropFrame.Parent = self.Container
        Instance.new("UICorner", DropFrame).CornerRadius = UDim.new(0, 4)
        local MainBtn = Instance.new("TextButton"); MainBtn.Size = UDim2.new(1, 0, 0, 32); MainBtn.BackgroundTransparency = 1; MainBtn.TextColor3 = Color3.fromRGB(200, 200, 200); MainBtn.Text = "  " .. title .. ": " .. defaultOption; MainBtn.Font = Enum.Font.GothamSemibold; MainBtn.TextSize = 12; MainBtn.TextXAlignment = Enum.TextXAlignment.Left; MainBtn.Parent = DropFrame; MainBtn.AutoButtonColor = false
        local Arrow = Instance.new("TextLabel"); Arrow.Size = UDim2.new(0, 30, 1, 0); Arrow.Position = UDim2.new(1, -30, 0, 0); Arrow.BackgroundTransparency = 1; Arrow.Text = "▼"; Arrow.TextColor3 = Color3.fromRGB(200, 200, 200); Arrow.Font = Enum.Font.GothamBold; Arrow.Parent = MainBtn
        local ListFrame = Instance.new("ScrollingFrame"); ListFrame.Size = UDim2.new(1, 0, 1, -32); ListFrame.Position = UDim2.new(0, 0, 0, 32); ListFrame.BackgroundTransparency = 1; ListFrame.ScrollBarThickness = 2; ListFrame.Parent = DropFrame
        local ListLayout = Instance.new("UIListLayout"); ListLayout.Parent = ListFrame
        local isOpen = false

        local function updateSelection(opt)
            MainBtn.Text = "  " .. title .. ": " .. opt; callback(opt); isOpen = false
            TweenService:Create(DropFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, -5, 0, 32)}):Play()
            TweenService:Create(Arrow, TweenInfo.new(0.3), {Rotation = 0}):Play()
        end

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
                local OptBtn = Instance.new("TextButton"); OptBtn.Size = UDim2.new(1, 0, 0, 28); OptBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45); OptBtn.TextColor3 = Color3.fromRGB(180, 180, 180); OptBtn.Text = "  " .. opt; OptBtn.Font = Enum.Font.Gotham; OptBtn.TextSize = 12; OptBtn.TextXAlignment = Enum.TextXAlignment.Left; OptBtn.Parent = ListFrame; OptBtn.AutoButtonColor = false
                OptBtn.MouseEnter:Connect(function() TweenService:Create(OptBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 100, 255), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play() end)
                OptBtn.MouseLeave:Connect(function() TweenService:Create(OptBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 35, 45), TextColor3 = Color3.fromRGB(180, 180, 180)}):Play() end)
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
        TextBox.Focused:Connect(function() TweenService:Create(TextBox, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}):Play() end)
        TextBox.FocusLost:Connect(function() TweenService:Create(TextBox, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(20, 20, 25)}):Play()
            local val = TextBox.Text; if tonumber(val) then callback(tonumber(val)) else callback(val) end 
        end)
    end

    return Tab
end

return Library
