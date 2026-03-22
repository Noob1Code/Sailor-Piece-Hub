-- =====================================================================
-- 🖥️ UI: Interface.lua (REMASTERIZADA PRO UI/UX V2)
-- =====================================================================
-- [[ Design Principles: Minimalist Dark, Dynamic Layout, Intuitive UX ]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

local Interface = {}
Interface.__index = Interface

-- ==========================================
-- 🎨 PALETA DE CORES E ESTILOS
-- ==========================================
local Theme = {
    Bg = Color3.fromRGB(15, 15, 15),
    Sidebar = Color3.fromRGB(10, 10, 10),
    Accent = Color3.fromRGB(30, 160, 255), -- Azul Sailor
    Element = Color3.fromRGB(25, 25, 25),
    ElementHover = Color3.fromRGB(35, 35, 35),
    Text = Color3.fromRGB(240, 240, 240),
    TextDim = Color3.fromRGB(160, 160, 160),
    Corner = UDim.new(0, 6)
}

-- ==========================================
-- 🛠️ INICIALIZAÇÃO
-- ==========================================
function Interface.new(Constants, Config)
    local self = setmetatable({}, Interface)
    self.Constants = Constants
    self.Config = Config
    self.ActiveTab = "Dashboard"
    self.TabFrames = {}
    self.TabButtons = {}
    self._Connections = {}
    
    -- Inicializa a ScreenGui
    self:BuildMainFramework()
    
    -- Constrói as abas organizadas por UX
    self:BuildDashboardTab()
    self:BuildCombatTab()
    self:BuildAutomationTab()
    self:BuildWorldTab()
    self:BuildCharacterTab()
    self:BuildGachaTab()
    self:BuildSettingsTab()
    
    -- Seleciona a aba inicial
    self:SelectTab("Dashboard")
    self:HandleInput()
    
    print("✅ Interface Sailor Piece Hub (UX V2) carregada!")
    return self
end

-- ==========================================
-- 🏗️ ESTRUTURA PRINCIPAL (FRAMEWORK)
-- ==========================================
function Interface:BuildMainFramework()
    -- Proteção contra múltiplas instâncias
    local old = CoreGui:FindFirstChild("SailorPieceHub_V2")
    if old then old:Destroy() end

    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "SailorPieceHub_V2"
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.DisplayOrder = 100
    pcall(function() self.ScreenGui.Parent = CoreGui end)
    if not self.ScreenGui.Parent then self.ScreenGui.Parent = LP:WaitForChild("PlayerGui") end

    -- Frame Principal (Centralizado)
    self.MainFrame = Instance.new("Frame")
    self.MainFrame.Name = "MainFrame"
    self.MainFrame.Size = UDim2.new(0, 620, 0, 420)
    self.MainFrame.Position = UDim2.new(0.5, -310, 0.5, -210)
    self.MainFrame.BackgroundColor3 = Theme.Bg
    self.MainFrame.BorderSizePixel = 0
    self.MainFrame.ClipsDescendants = true
    self.MainFrame.Parent = self.ScreenGui
    Instance.new("UICorner", self.MainFrame).CornerRadius = Theme.Corner
    Instance.new("UIStroke", self.MainFrame).Color = Color3.fromRGB(35, 35, 35)

    -- Barra Lateral (Navegação)
    self.Sidebar = Instance.new("Frame")
    self.Sidebar.Name = "Sidebar"
    self.Sidebar.Size = UDim2.new(0, 160, 1, 0)
    self.Sidebar.BackgroundColor3 = Theme.Sidebar
    self.Sidebar.BorderSizePixel = 0
    self.Sidebar.Parent = self.MainFrame
    Instance.new("UICorner", self.Sidebar).CornerRadius = Theme.Corner

    local sideLayout = Instance.new("UIListLayout", self.Sidebar)
    sideLayout.Padding = UDim.new(0, 2)
    sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local sidePadding = Instance.new("UIPadding", self.Sidebar)
    sidePadding.PaddingTop = UDim.new(0, 10)
    sidePadding.PaddingBottom = UDim.new(0, 10)

    -- Título no Sidebar
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.9, 0, 0, 30)
    title.BackgroundTransparency = 1
    title.Text = "Sailor Hub"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextColor3 = Theme.Accent
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = self.Sidebar
    Instance.new("UIPadding", title).PaddingLeft = UDim.new(0, 10)

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(0.9, 0, 0, 15)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Piece Edition v2.1"
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 11
    subtitle.TextColor3 = Theme.TextDim
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = self.Sidebar
    Instance.new("UIPadding", subtitle).PaddingLeft = UDim.new(0, 10)

    local sep = Instance.new("Frame")
    sep.Size = UDim2.new(0.9, 0, 0, 1)
    sep.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    sep.BorderSizePixel = 0
    sep.Parent = self.Sidebar
    
    local gap = Instance.new("Frame"); gap.Size = UDim2.new(1,0,0,10); gap.BackgroundTransparency=1; gap.Parent=self.Sidebar

    -- Conteúdo Principal (Onde as abas ficam)
    self.ContentFrame = Instance.new("Frame")
    self.ContentFrame.Name = "ContentFrame"
    self.ContentFrame.Size = UDim2.new(1, -170, 1, -10)
    self.ContentFrame.Position = UDim2.new(0, 165, 0, 5)
    self.ContentFrame.BackgroundTransparency = 1
    self.ContentFrame.Parent = self.MainFrame

    self:MakeDraggable(self.MainFrame)
end

-- ==========================================
-- 🛠️ AUXILIARES DE CONSTRUÇÃO DE UI (BIBLIOTECA INTERNA)
-- ==========================================
function Interface:MakeDraggable(frame)
    local dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragInput = nil end end)
        end
    end)
    frame.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
    UserInputService.InputChanged:Connect(function(input) if input == dragInput then update(input) end end)
end

function Interface:CreateTabButton(name, iconId)
    local btn = Instance.new("TextButton")
    btn.Name = name .. "TabBtn"
    btn.Size = UDim2.new(0.9, 0, 0, 32)
    btn.BackgroundColor3 = Theme.Sidebar
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0
    btn.Text = "" -- Usamos Label/Icon
    btn.AutoButtonColor = false
    btn.Parent = self.Sidebar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 18, 0, 18)
    icon.Position = UDim2.new(0, 8, 0.5, -9)
    icon.BackgroundTransparency = 1
    icon.Image = iconId or "rbxassetid://10723415903" -- Ícone padrão
    icon.ImageColor3 = Theme.TextDim
    icon.Parent = btn

    local lbl = Instance.new("TextLabel")
    lbl.Name = "Title"
    lbl.Size = UDim2.new(1, -35, 1, 0)
    lbl.Position = UDim2.new(0, 32, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextColor3 = Theme.TextDim
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = btn

    -- Hover Effect
    btn.MouseEnter:Connect(function() if self.ActiveTab ~= name then TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.5, BackgroundColor3 = Theme.ElementHover}):Play() end end)
    btn.MouseLeave:Connect(function() if self.ActiveTab ~= name then TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 1, BackgroundColor3 = Theme.Sidebar}):Play() end end)
    
    btn.MouseButton1Click:Connect(function() self:SelectTab(name) end)

    self.TabButtons[name] = btn
    return btn
end

function Interface:CreateContentFrame(name)
    local frame = Instance.new("ScrollingFrame")
    frame.Name = name .. "Content"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.ScrollBarThickness = 2
    frame.ScrollBarImageColor3 = Theme.Accent
    frame.Visible = false
    frame.Parent = self.ContentFrame
    
    local layout = Instance.new("UIListLayout", frame)
    layout.Padding = UDim.new(0, 8)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local padding = Instance.new("UIPadding", frame)
    padding.PaddingTop = UDim.new(0, 5)
    padding.PaddingBottom = UDim.new(0, 5)
    padding.PaddingRight = UDim.new(0, 5)

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        frame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 15)
    end)

    self.TabFrames[name] = frame
    return frame
end

function Interface:SelectTab(name)
    if not self.TabFrames[name] then return end
    
    self.ActiveTab = name
    
    -- Atualiza Botões (Visual)
    for tabName, btn in pairs(self.TabButtons) do
        local isSelected = (tabName == name)
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundTransparency = isSelected and 0 or 1,
            BackgroundColor3 = isSelected and Theme.Element or Theme.Sidebar
        }):Play()
        TweenService:Create(btn.Icon, TweenInfo.new(0.2), {ImageColor3 = isSelected and Theme.Accent or Theme.TextDim}):Play()
        TweenService:Create(btn.Title, TweenInfo.new(0.2), {TextColor3 = isSelected and Theme.Text or Theme.TextDim}):Play()
    end
    
    -- Atualiza Frames (Visibilidade)
    for tabName, frame in pairs(self.TabFrames) do frame.Visible = (tabName == name) end
end

-- ==========================================
-- 🧊 ELEMENTOS DE UI PADRÃO (COMPONENTES)
-- ==========================================
function Interface:CreateSection(parent, title)
    local secFrame = Instance.new("Frame")
    secFrame.Name = title .. "Section"
    secFrame.Size = UDim2.new(0.96, 0, 0, 30)
    secFrame.BackgroundTransparency = 1
    secFrame.Parent = parent
    
    local layout = Instance.new("UIListLayout", secFrame)
    layout.Padding = UDim.new(0, 6)
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = title:upper()
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextColor3 = Theme.Accent
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = secFrame
    Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0, 2)

    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(1, 0, 0, 0)
    container.BackgroundTransparency = 1
    container.Parent = secFrame

    local cLayout = Instance.new("UIListLayout", container)
    cLayout.Padding = UDim.new(0, 5)

    cLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        container.Size = UDim2.new(1, 0, 0, cLayout.AbsoluteContentSize.Y)
        secFrame.Size = UDim2.new(0.96, 0, 0, cLayout.AbsoluteContentSize.Y + 25)
    end)

    return container
end

function Interface:CreateToggle(parent, name, configKey, callback)
    local configRef = self.Config
    local keys = string.split(configKey, ".")
    for i = 1, #keys - 1 do configRef = configRef[keys[i]] end
    local finalKey = keys[#keys]

    local base = Instance.new("TextButton")
    base.Name = name .. "Toggle"
    base.Size = UDim2.new(1, 0, 0, 32)
    base.BackgroundColor3 = Theme.Element
    base.Text = ""
    base.AutoButtonColor = false
    base.Parent = parent
    Instance.new("UICorner", base).CornerRadius = Theme.Corner

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -50, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextColor3 = Theme.Text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = base

    local switch = Instance.new("Frame")
    switch.Name = "Switch"
    switch.Size = UDim2.new(0, 36, 0, 18)
    switch.Position = UDim2.new(1, -46, 0.5, -9)
    switch.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    switch.Parent = base
    Instance.new("UICorner", switch).CornerRadius = UDim.new(1, 0)
    local stroke = Instance.new("UIStroke", switch); stroke.Color = Color3.fromRGB(50, 50, 50); stroke.Thickness = 1

    local circle = Instance.new("Frame")
    circle.Name = "Circle"
    circle.Size = UDim2.new(0, 14, 0, 14)
    circle.Position = UDim2.new(0, 2, 0.5, -7)
    circle.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    circle.Parent = switch
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)

    local function updateVisual(state)
        TweenService:Create(switch, TweenInfo.new(0.2), {BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(40, 40, 40)}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.2), {Color = state and Theme.Accent or Color3.fromRGB(50, 50, 50)}):Play()
        TweenService:Create(circle, TweenInfo.new(0.2), {
            Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
            BackgroundColor3 = state and Theme.Text or Color3.fromRGB(150, 150, 150)
        }):Play()
    end

    updateVisual(configRef[finalKey])

    base.MouseButton1Click:Connect(function()
        configRef[finalKey] = not configRef[finalKey]
        updateVisual(configRef[finalKey])
        if callback then callback(configRef[finalKey]) end
    end)

    base.MouseEnter:Connect(function() TweenService:Create(base, TweenInfo.new(0.2), {BackgroundColor3 = Theme.ElementHover}):Play() end)
    base.MouseLeave:Connect(function() TweenService:Create(base, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Element}):Play() end)

    return base, updateVisual
end

function Interface:CreateDropdown(parent, name, options, configKey, callback)
    local configRef = self.Config
    local keys = string.split(configKey, ".")
    for i = 1, #keys - 1 do configRef = configRef[keys[i]] end
    local finalKey = keys[#keys]

    local base = Instance.new("Frame")
    base.Name = name .. "Dropdown"
    base.Size = UDim2.new(1, 0, 0, 32)
    base.BackgroundColor3 = Theme.Element
    base.ClipsDescendants = false -- Importante para a lista aparecer
    base.Parent = parent
    Instance.new("UICorner", base).CornerRadius = Theme.Corner

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = base

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -70, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextColor3 = Theme.TextDim
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = base

    local selectedLbl = Instance.new("TextLabel")
    selectedLbl.Size = UDim2.new(1, -10, 1, 0)
    selectedLbl.BackgroundTransparency = 1
    selectedLbl.Text = tostring(configRef[finalKey]) or "Nenhum"
    selectedLbl.Font = Enum.Font.GothamMedium
    selectedLbl.TextSize = 13
    selectedLbl.TextColor3 = Theme.Text
    selectedLbl.TextXAlignment = Enum.TextXAlignment.Right
    selectedLbl.Parent = base
    Instance.new("UIPadding", selectedLbl).PaddingRight = UDim.new(0, 25)

    local arrow = Instance.new("ImageLabel")
    arrow.Size = UDim2.new(0, 14, 0, 14)
    arrow.Position = UDim2.new(1, -22, 0.5, -7)
    arrow.BackgroundTransparency = 1
    arrow.Image = "rbxassetid://10723415903" -- Ícone Seta Baixo
    arrow.ImageColor3 = Theme.TextDim
    arrow.Parent = base

    -- Container da Lista
    local listFrame = Instance.new("ScrollingFrame")
    listFrame.Size = UDim2.new(1, 0, 0, 0)
    listFrame.Position = UDim2.new(0, 0, 1, 2)
    listFrame.BackgroundColor3 = Theme.Element
    listFrame.BorderSizePixel = 0
    listFrame.ScrollBarThickness = 2
    listFrame.ScrollBarImageColor3 = Theme.Accent
    listFrame.Visible = false
    listFrame.ClipsDescendants = true
    listFrame.ZIndex = 10
    listFrame.Parent = base
    Instance.new("UICorner", listFrame).CornerRadius = Theme.Corner
    Instance.new("UIStroke", listFrame).Color = Color3.fromRGB(40, 40, 40)

    local listLayout = Instance.new("UIListLayout", listFrame)
    listLayout.Padding = UDim.new(0, 2)
    Instance.new("UIPadding", listFrame).PaddingTop = UDim.new(0, 2)

    local isOpen = false
    local function toggleDropdown()
        isOpen = not isOpen
        local targetSize = 0
        if isOpen then targetSize = math.min(#options * 26 + 6, 136) end
        
        listFrame.Visible = true
        TweenService:Create(listFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, targetSize)}):Play()
        TweenService:Create(arrow, TweenInfo.new(0.2), {Rotation = isOpen and 180 or 0}):Play()
        
        task.delay(0.2, function() if not isOpen then listFrame.Visible = false end end)
        listFrame.CanvasSize = UDim2.new(0, 0, 0, #options * 26 + 6)
    end

    local function refreshOptions(newOptions)
        for _, c in ipairs(listFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        for _, opt in ipairs(newOptions) do
            local optBtn = Instance.new("TextButton")
            optBtn.Size = UDim2.new(0.96, 0, 0, 24)
            optBtn.BackgroundColor3 = Theme.Element
            optBtn.BackgroundTransparency = 1
            optBtn.Text = tostring(opt)
            optBtn.Font = Enum.Font.Gotham
            optBtn.TextSize = 12
            optBtn.TextColor3 = (tostring(opt) == tostring(configRef[finalKey])) and Theme.Text or Theme.TextDim
            optBtn.Parent = listFrame
            optBtn.ZIndex = 11
            Instance.new("UICorner", optBtn).CornerRadius = UDim.new(0, 4)

            optBtn.MouseEnter:Connect(function() TweenService:Create(optBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0, BackgroundColor3 = Theme.ElementHover}):Play() end)
            optBtn.MouseLeave:Connect(function() TweenService:Create(optBtn, TweenInfo.new(0.2), {BackgroundTransparency = 1, BackgroundColor3 = Theme.Element}):Play() end)

            optBtn.MouseButton1Click:Connect(function()
                configRef[finalKey] = opt
                selectedLbl.Text = tostring(opt)
                toggleDropdown() -- Fecha
                if callback then callback(opt) end
                -- Atualiza cor do texto dos itens
                for _, other in ipairs(listFrame:GetChildren()) do if other:IsA("TextButton") then other.TextColor3 = (other.Text == selectedLbl.Text) and Theme.Text or Theme.TextDim end end
            end)
        end
        if isOpen then listFrame.CanvasSize = UDim2.new(0, 0, 0, #newOptions * 26 + 6) end
    end

    refreshOptions(options)
    btn.MouseButton1Click:Connect(toggleDropdown)

    -- Hover do Base
    base.MouseEnter:Connect(function() TweenService:Create(base, TweenInfo.new(0.2), {BackgroundColor3 = Theme.ElementHover}):Play() end)
    base.MouseLeave:Connect(function() TweenService:Create(base, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Element}):Play() end)

    return base, refreshOptions
end

function Interface:CreateButton(parent, name, callback)
    local base = Instance.new("TextButton")
    base.Name = name .. "Button"
    base.Size = UDim2.new(1, 0, 0, 32)
    base.BackgroundColor3 = Theme.Accent
    base.Text = name
    base.Font = Enum.Font.GothamMedium
    base.TextSize = 13
    base.TextColor3 = Color3.new(1, 1, 1)
    base.AutoButtonColor = false
    base.Parent = parent
    Instance.new("UICorner", base).CornerRadius = Theme.Corner

    -- Click Animation
    base.MouseButton1Down:Connect(function() TweenService:Create(base, TweenInfo.new(0.1), {BackgroundTransparency = 0.2}):Play() end)
    base.MouseButton1Up:Connect(function() TweenService:Create(base, TweenInfo.new(0.1), {BackgroundTransparency = 0}):Play() end)
    
    base.MouseButton1Click:Connect(function() if callback then callback() end end)

    return base
end

-- ==========================================
-- 🛠️ MONTAGEM DAS ABAS (UX V2)
-- ==========================================

-- Ícones padrão (Assets do Roblox)
local Icons = {
    Dashboard = "rbxassetid://10723415903", -- Home
    Combat = "rbxassetid://10723416110", -- Sword
    Automation = "rbxassetid://10723416260", -- Settings/Gear (Loop)
    World = "rbxassetid://10723346953", -- Map
    Character = "rbxassetid://10723346802", -- User
    Gacha = "rbxassetid://10723346231", -- Gift
    Settings = "rbxassetid://10723346452" -- Sliders
}

-- 1. ABA DASHBOARD (UX: Boas vindas e Status)
function Interface:BuildDashboardTab()
    local name = "Dashboard"
    self:CreateTabButton(name, Icons.Dashboard)
    local frame = self:CreateContentFrame(name)
    
    local sec = self:CreateSection(frame, "Bem vindo ao Sailor Hub")
    
    local welcome = Instance.new("TextLabel")
    welcome.Size = UDim2.new(1, 0, 0, 60)
    welcome.BackgroundTransparency = 1
    welcome.Text = "Olá, " .. LP.Name .. "!\nConfigure suas automações nas abas laterais.\nO script detecta o level e ilha atuais automaticamente."
    welcome.Font = Enum.Font.Gotham
    welcome.TextSize = 13
    welcome.TextColor3 = Theme.Text
    welcome.TextWrapped = true
    welcome.Parent = sec

    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, 0, 0, 20)
    info.BackgroundTransparency = 1
    info.Text = "Status: Executando ✔️ | Versão: POO V2.1"
    info.Font = Enum.Font.GothamMedium
    info.TextSize = 12
    info.TextColor3 = Theme.TextDim
    info.Parent = sec
    
    local discordBtn = self:CreateButton(sec, "Entrar no Discord (Copiar Link)", function()
        if setclipboard then setclipboard("https://discord.gg/seulink") print("Link copiado!") end
    end)
    discordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242) -- Discord Blue
end

-- 2. ABA COMBATE (UX: Matar coisas)
function Interface:BuildCombatTab()
    local name = "Combat"
    self:CreateTabButton(name, Icons.Combat)
    local frame = self:CreateContentFrame(name)
    
    -- Seção 1: Farm Principal
    local secFarm = self:CreateSection(frame, "Auto Farm NPCs")
    
    -- UX Dinâmico: Se ativar MaxLevel, desativa AutoQuest
    local autoQuestToggle, updateAutoQuest
    local autoMaxToggle, updateAutoMax
    
    autoQuestToggle, updateAutoQuest = self:CreateToggle(secFarm, "Auto Quest (Ilha Selecionada)", "AutoQuest", function(state)
        if state and self.Config.AutoFarmMaxLevel then self.Config.AutoFarmMaxLevel = false; updateAutoMax(false) end
    end)
    
    autoMaxToggle, updateAutoMax = self:CreateToggle(secFarm, "Auto Farm Max Level (Pula Ilhas)", "AutoFarmMaxLevel", function(state)
        if state and self.Config.AutoQuest then self.Config.AutoQuest = false; updateAutoQuest(false) end
    end)
    
    self:CreateToggle(secFarm, "Auto Dummy (Treinamento Melee)", "AutoDummy")

    -- Configuração de Ilha/Quest manual
    local islandList = self.Constants.QuestFilterOptions or {}
    local questList = {} -- Populado dinamicamente

    local questDropdown, refreshQuests
    
    self:CreateDropdown(secFarm, "Selecionar Ilha", islandList, "SelectedQuestIsland", function(ilha)
        local novasQuests = {}
        if self.Constants.QuestDataMap[ilha] then for _, q in ipairs(self.Constants.QuestDataMap[ilha]) do table.insert(novasQuests, q.Name) end end
        if #novasQuests == 0 then table.insert(novasQuests, "Nenhuma") end
        refreshQuests(novasQuests) -- Atualiza o próximo dropdown
        self.Config.SelectedQuest = novasQuests[1] -- Reseta quest selecionada
    end)
    
    questDropdown, refreshQuests = self:CreateDropdown(secFarm, "Selecionar Missão", {"Selecione a Ilha"}, "SelectedQuest")

    -- Seção 2: Farm Bosses
    local secBoss = self:CreateSection(frame, "Auto Farm Bosses")
    self:CreateToggle(secBoss, "Ativar Auto Bosses Selecionados", "AutoBoss")
    
    -- Lista de Chefes (Multi-seleção simplificada)
    local bossList = self.Constants.IslandDataMap and self.Constants.IslandDataMap["Starter"] and self.Constants.IslandDataMap["Starter"].Bosses or {}
    -- UX: Como é difícil fazer multiselect nativo em dropdown simples, listamos os Bosses
    local currentBossesFrame = Instance.new("Frame")
    currentBossesFrame.Size = UDim2.new(1,0,0,20)
    currentBossesFrame.BackgroundTransparency = 1
    currentBossesFrame.Parent = secBoss
    
    local bossesLbl = Instance.new("TextLabel")
    bossesLbl.Size = UDim2.new(1, -70, 1, 0)
    bossesLbl.Position = UDim2.new(0, 10, 0, 0)
    bossesLbl.BackgroundTransparency = 1
    bossesLbl.Text = "Bosses Ativos: " .. #self.Config.SelectedBosses
    bossesLbl.Font = Enum.Font.Gotham
    bossesLbl.TextSize = 13
    bossesLbl.TextColor3 = Theme.TextDim
    bossesLbl.TextXAlignment = Enum.TextXAlignment.Left
    bossesLbl.Parent = currentBossesFrame

    self:CreateButton(secBoss, "Gerenciar Lista de Bosses", function()
        -- UX: Em um hub completo, abriria um modal. Aqui vamos apenas popular o Config com TODOS para simplificar
        self.Config.SelectedBosses = bossList
        bossesLbl.Text = "Bosses Ativos: TODOS"
    end)

    -- Seção 3: Configurações de Ataque
    local secAtk = self:CreateSection(frame, "Configurações de Ataque")
    self:CreateDropdown(secAtk, "Posição", {"Cima", "Abaixo", "Atrás", "Orbital"}, "AttackPosition")
    self:CreateDropdown(secAtk, "Arma", {"Nenhuma", "Melee", "Sword", "Fruit"}, "SelectedWeapon")
end

-- 3. ABA AUTOMAÇÃO (UX: Coletar coisas passivamente)
function Interface:BuildAutomationTab()
    local name = "Automation"
    self:CreateTabButton(name, Icons.Automation)
    local frame = self:CreateContentFrame(name)
    
    local secCollect = self:CreateSection(frame, "Coletar Itens Automaticamente")
    self:CreateToggle(secCollect, "Coletar Frutas (Chão)", "AutoCollect.Fruits")
    self:CreateToggle(secCollect, "Coletar Hogyoku (Pula Ilhas)", "AutoCollect.Hogyoku")
    self:CreateToggle(secCollect, "Coletar Baús de Tesouro", "AutoCollect.Chests")
    self:CreateToggle(secCollect, "Coletar Puzzles/Orbs", "AutoCollect.Puzzles")
    self:CreateToggle(secCollect, "Fruit Sniper (Compra Automática)", "FruitSniper")
    
    local secMisc = self:CreateSection(frame, "Outras Automações")
    self:CreateToggle(secMisc, "Recompensas de Grupo Diárias", "AutoGroupReward")
end

-- 4. ABA MUNDO (UX: Viajar e Teleportar)
function Interface:BuildWorldTab()
    local name = "World"
    self:CreateTabButton(name, Icons.World)
    local frame = self:CreateContentFrame(name)
    
    local secTp = self:CreateSection(frame, "Teleporte Rápido (Ilhas)")
    
    local islandList = {}
    if self.Constants.TeleportMap then for island, _ in pairs(self.Constants.TeleportMap) do table.insert(islandList, island) end end
    table.sort(islandList)
    if #islandList == 0 then table.insert(islandList, "Starter") end

    self:CreateDropdown(secTp, "Viajar para", islandList, "SelectedQuestIsland", function(ilha)
        if _G.ComunidadeHub_Core and _G.ComunidadeHub_Core.CombatService then
            _G.ComunidadeHub_Core.CombatService:SmartIslandTeleport(ilha)
            print("🚀 Teleportando para " .. ilha)
        end
    end)
    
    local note = Instance.new("TextLabel")
    note.Size = UDim2.new(1, 0, 0, 20)
    note.BackgroundTransparency = 1
    note.Text = "Nota: O teleporte usa o sistema do jogo."
    note.Font = Enum.Font.Gotham
    note.TextSize = 11
    note.TextColor3 = Theme.TextDim
    note.Parent = secTp
end

-- 5. ABA PERSONAGEM (UX: Stats e Rerolls)
function Interface:BuildCharacterTab()
    local name = "Character"
    self:CreateTabButton(name, Icons.Character)
    local frame = self:CreateContentFrame(name)
    
    local secStats = self:CreateSection(frame, "Auto Stats (Distribuir Pontos)")
    self:CreateToggle(secStats, "Ativar Distribuição", "AutoStats")
    self:CreateDropdown(secStats, "Distribuir Em", {"Todos", "Melee", "Defense", "Sword", "Fruit"}, "SelectedStats")
    
    local secReroll = self:CreateSection(frame, "Gacha de Personagem (Reroll)")
    self:CreateDropdown(secReroll, "Alvo Raça", {"Human", "Fishman", "Mink", "Skypiean"}, "AutoReroll.TargetRace")
    self:CreateToggle(secReroll, "Auto Reroll Raça (Se tiver item)", "AutoReroll.Race")
    
    local secMisc = self:CreateSection(frame, "Melhorias de Movimento")
    self:CreateToggle(secMisc, "Super Velocidade (Voar)", "SuperSpeed")
    self:CreateToggle(secMisc, "Pulo Infinito", "InfJump")
end

-- 6. ABA GACHA (UX: Abrir coisas e RNG)
function Interface:BuildGachaTab()
    local name = "Gacha"
    self:CreateTabButton(name, Icons.Gacha)
    local frame = self:CreateContentFrame(name)
    
    local secChest = self:CreateSection(frame, "Abrir Baús do Inventário")
    self:CreateDropdown(secChest, "Quantidade por Vez", {1, 10, 50, "Todos"}, "ChestOpenAmount")
    self:CreateToggle(secChest, "Abrir Comuns", "AutoOpenChests.Common")
    self:CreateToggle(secChest, "Abrir Raros", "AutoOpenChests.Rare")
    self:CreateToggle(secChest, "Abrir Épicos", "AutoOpenChests.Epic")
    self:CreateToggle(secChest, "Abrir Lendários", "AutoOpenChests.Legendary")
    self:CreateToggle(secChest, "Abrir Míticos", "AutoOpenChests.Mythical")
end

-- 7. ABA CONFIGURAÇÕES (UX: Controle do script)
function Interface:BuildSettingsTab()
    local name = "Settings"
    self:CreateTabButton(name, Icons.Settings)
    local frame = self:CreateContentFrame(name)
    
    local secMenu = self:CreateSection(frame, "Controles do Menu")
    
    -- UX Simplificado: Atalho fixo RightControl
    local keyLbl = Instance.new("TextLabel")
    keyLbl.Size = UDim2.new(1, -20, 0, 32)
    keyLbl.Position = UDim2.new(0, 10, 0, 0)
    keyLbl.BackgroundTransparency = 1
    keyLbl.Text = "Atalho para fechar/abrir: [RightControl]"
    keyLbl.Font = Enum.Font.Gotham
    keyLbl.TextSize = 13
    keyLbl.TextColor3 = Theme.Text
    keyLbl.TextXAlignment = Enum.TextXAlignment.Left
    keyLbl.Parent = secMenu

    local secGame = self:CreateSection(frame, "Controles do Jogo")
    self:CreateButton(secGame, "Reentrar no Servidor (Rejoin)", function()
        pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId, LP) end)
    end)
    
    local unloadBtn = self:CreateButton(secGame, "Descarregar Script (Unload)", function()
        print("🧹 Descarregando Hub...")
        if _G.ComunidadeHub_Cleanup then _G.ComunidadeHub_Cleanup() end
    end)
    unloadBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50) -- Vermelho
end

-- ==========================================
-- 🔄 LÓGICA DE INPUT (FECHAR/ABRIR)
-- ==========================================
function Interface:HandleInput()
    -- RightControl para fechar/abrir
    table.insert(self._Connections, UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == Enum.KeyCode.RightControl then
            self.MainFrame.Visible = not self.MainFrame.Visible
        end
    end))
end

function Interface:Destroy()
    if self.ScreenGui then self.ScreenGui:Destroy() end
    for _, conn in ipairs(self._Connections) do if conn then conn:Disconnect() end end
    self._Connections = {}
end

return Interface
