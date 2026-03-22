-- =====================================================================
-- 🎨 INTERFACE DO USUÁRIO (UI) - Sailor Piece Hub
-- =====================================================================

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Simulação de carregamento do módulo de configurações e constantes
-- No ambiente real, substitua pelas chamadas require corretas
local Config = _G.HubConfig or {} 
local Constants = _G.HubConstants or {
    FilterOptions = {"Todas", "Starter"},
    StatsList = {"Melee", "Defense", "Sword", "Power"},
    Islands = {"Starter", "Jungle", "Desert"}
}

-- Prevenção de sobreposição
if CoreGui:FindFirstChild("ComunidadeHubUI") then
    CoreGui.ComunidadeHubUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ComunidadeHubUI"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

-- Tema de Cores
local Theme = {
    Background = Color3.fromRGB(25, 25, 25),
    Sidebar = Color3.fromRGB(35, 35, 35),
    Component = Color3.fromRGB(45, 45, 45),
    Accent = Color3.fromRGB(0, 195, 255),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(180, 180, 180)
}

-- Container Principal
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 550, 0, 350)
MainFrame.Position = UDim2.new(0.5, -275, 0.5, -175)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainUICorner = Instance.new("UICorner")
MainUICorner.CornerRadius = UDim.new(0, 8)
MainUICorner.Parent = MainFrame

-- Título
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundTransparency = 1
Title.Text = "  SAILOR PIECE HUB"
Title.TextColor3 = Theme.Accent
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

-- Barra Lateral (Sidebar)
local Sidebar = Instance.new("ScrollingFrame")
Sidebar.Size = UDim2.new(0, 140, 1, -35)
Sidebar.Position = UDim2.new(0, 0, 0, 35)
Sidebar.BackgroundColor3 = Theme.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.ScrollBarThickness = 2
Sidebar.Parent = MainFrame

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Parent = Sidebar

-- Área de Conteúdo
local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -140, 1, -35)
ContentArea.Position = UDim2.new(0, 140, 0, 35)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainFrame

-- Variáveis de Estado da UI
local activeTabBtn = nil
local tabs = {}

-- ==========================================
-- 🛠️ FUNÇÕES CONSTRUTORAS DE COMPONENTES
-- ==========================================

local function CreateTab(name)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(1, 0, 0, 35)
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
    pagePadding.Parent = page

    tabBtn.MouseButton1Click:Connect(function()
        if activeTabBtn then
            activeTabBtn.TextColor3 = Theme.TextDim
            activeTabBtn.BackgroundColor3 = Theme.Sidebar
            tabs[activeTabBtn.Text].Visible = false
        end
        tabBtn.TextColor3 = Theme.Accent
        tabBtn.BackgroundColor3 = Theme.Component
        page.Visible = true
        activeTabBtn = tabBtn
    end)

    tabs[name] = page
    return page
end

local function CreateToggle(parent, text, configKey, subTable)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 35)
    frame.BackgroundColor3 = Theme.Component
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -50, 1, 0)
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
    indicator.Position = UDim2.new(0, 2, 0.5, -8)
    indicator.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    indicator.Parent = btn
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 4)

    local state = false

    local function updateState()
        state = not state
        
        -- Atualiza Config
        if subTable then
            if not Config[subTable] then Config[subTable] = {} end
            Config[subTable][configKey] = state
        else
            Config[configKey] = state
        end

        -- Atualiza Visual
        if state then
            TweenService:Create(indicator, TweenInfo.new(0.2), {Position = UDim2.new(1, -18, 0.5, -8), BackgroundColor3 = Theme.Accent}):Play()
        else
            TweenService:Create(indicator, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -8), BackgroundColor3 = Color3.fromRGB(200, 50, 50)}):Play()
        end
    end

    btn.MouseButton1Click:Connect(updateState)
end

local function CreateSlider(parent, text, min, max, configKey)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.BackgroundColor3 = Theme.Component
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 20)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Theme.Text
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0, 50, 0, 20)
    valLabel.Position = UDim2.new(1, -60, 0, 5)
    valLabel.BackgroundTransparency = 1
    valLabel.Text = tostring(Config[configKey] or min)
    valLabel.TextColor3 = Theme.Accent
    valLabel.Font = Enum.Font.GothamBold
    valLabel.TextSize = 14
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.Parent = frame

    local sliderBG = Instance.new("TextButton")
    sliderBG.Size = UDim2.new(1, -20, 0, 8)
    sliderBG.Position = UDim2.new(0, 10, 0, 30)
    sliderBG.BackgroundColor3 = Theme.Background
    sliderBG.Text = ""
    sliderBG.AutoButtonColor = false
    sliderBG.Parent = frame
    Instance.new("UICorner", sliderBG).CornerRadius = UDim.new(0, 4)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Theme.Accent
    fill.Parent = sliderBG
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)

    -- Lógica simples de drag do slider
    local dragging = false
    local function updateSlider(input)
        local relX = math.clamp((input.Position.X - sliderBG.AbsolutePosition.X) / sliderBG.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * relX)
        fill.Size = UDim2.new(relX, 0, 1, 0)
        valLabel.Text = tostring(val)
        Config[configKey] = val
    end

    sliderBG.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; updateSlider(input)
        end
    end)
    game:GetService("UserInputService").InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then updateSlider(input) end
    end)
end

-- ==========================================
-- 🗂️ CONSTRUÇÃO DAS ABAS E CONTEÚDO
-- ==========================================

-- 1. Farm Principal
local pageFarm = CreateTab("Principal (Farm)")
CreateToggle(pageFarm, "Auto Farm Max Level", "AutoFarmMaxLevel")
CreateToggle(pageFarm, "Auto Farm Mob", "AutoFarm")
CreateToggle(pageFarm, "Auto Boss", "AutoBoss")
CreateToggle(pageFarm, "Auto Dummy", "AutoDummy")

-- 2. Combate Config
local pageCombat = CreateTab("Combate")
CreateSlider(pageCombat, "Distância de Ataque", 0, 50, "Distance")
CreateSlider(pageCombat, "Velocidade do Tween", 50, 300, "TweenSpeed")

-- 3. Missões
local pageQuests = CreateTab("Missões")
CreateToggle(pageQuests, "Auto Quest", "AutoQuest")

-- 4. Coleta & Itens
local pageCollect = CreateTab("Coleta")
CreateToggle(pageCollect, "Coletar Frutas do Chão", "Fruits", "AutoCollect")
CreateToggle(pageCollect, "Fruit Sniper", "FruitSniper")
CreateToggle(pageCollect, "Coletar Hogyoku", "Hogyoku", "AutoCollect")
CreateToggle(pageCollect, "Coletar Puzzles", "Puzzles", "AutoCollect")
CreateToggle(pageCollect, "Coletar Baús", "Chests", "AutoCollect")

-- 5. Status & Gacha
local pageStats = CreateTab("Status & Gacha")
CreateToggle(pageStats, "Distribuir Status", "AutoStats")
CreateToggle(pageStats, "Auto Roletar Raça", "Race", "AutoReroll")
CreateToggle(pageStats, "Auto Roletar Clã", "Clan", "AutoReroll")
CreateSlider(pageStats, "Baús para Abrir", 1, 10, "ChestOpenAmount")

-- 6. Misc
local pageMisc = CreateTab("Miscelânea")
CreateToggle(pageMisc, "Super Velocidade", "SuperSpeed")
CreateSlider(pageMisc, "Multiplicador Velocidade", 1, 5, "SpeedMultiplier")
CreateToggle(pageMisc, "Pulo Infinito", "InfJump")
CreateToggle(pageMisc, "Haki do Armamento", "HakiArmamento", "HacksNativos")
CreateToggle(pageMisc, "Haki da Observação", "HakiObservacao", "HacksNativos")
CreateToggle(pageMisc, "Remover Cutscenes", "NoCutscene", "HacksNativos")

-- Inicializar Primeira Aba
for _, btn in ipairs(Sidebar:GetChildren()) do
    if btn:IsA("TextButton") then
        btn.TextColor3 = Theme.Accent
        btn.BackgroundColor3 = Theme.Component
        tabs[btn.Text].Visible = true
        activeTabBtn = btn
        break
    end
end
