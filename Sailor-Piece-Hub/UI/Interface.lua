-- =====================================================================
-- 🖥️ UI: Interface.lua (REVISADA E CORRIGIDA)
-- =====================================================================

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer

local Interface = {}
Interface.__index = Interface

local Theme = {
    Bg = Color3.fromRGB(15, 15, 15),
    Sidebar = Color3.fromRGB(10, 10, 10),
    Accent = Color3.fromRGB(30, 160, 255),
    Element = Color3.fromRGB(25, 25, 25),
    ElementHover = Color3.fromRGB(35, 35, 35),
    Text = Color3.fromRGB(240, 240, 240),
    TextDim = Color3.fromRGB(160, 160, 160),
    Corner = UDim.new(0, 6)
}

function Interface.new(Config, FSM, Constants)
    local self = setmetatable({}, Interface)
    self.Config = Config
    self.FSM = FSM
    self.Constants = Constants
    self.Tabs = {}
    self.TabButtons = {}
    self.ActiveTab = nil
    self._Connections = {}

    self:BuildFramework()
    self:CreateTabs()
    
    -- Seleciona Dashboard por padrão
    if self.Tabs["Dashboard"] then self:SelectTab("Dashboard") end
    
    return self
end

-- ==========================================
-- 🏗️ CORE FRAMEWORK & DRAGGING
-- ==========================================
function Interface:BuildFramework()
    local old = CoreGui:FindFirstChild("SailorPieceHub_V2") or LP.PlayerGui:FindFirstChild("SailorPieceHub_V2")
    if old then old:Destroy() end

    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "SailorPieceHub_V2"
    self.ScreenGui.ResetOnSpawn = false
    pcall(function() self.ScreenGui.Parent = CoreGui end)
    if not self.ScreenGui.Parent then self.ScreenGui.Parent = LP.PlayerGui end

    self.MainFrame = Instance.new("Frame")
    self.MainFrame.Size = UDim2.new(0, 600, 0, 400)
    self.MainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
    self.MainFrame.BackgroundColor3 = Theme.Bg
    self.MainFrame.BorderSizePixel = 0
    self.MainFrame.Parent = self.ScreenGui
    Instance.new("UICorner", self.MainFrame).CornerRadius = Theme.Corner

    self.Sidebar = Instance.new("Frame")
    self.Sidebar.Size = UDim2.new(0, 150, 1, 0)
    self.Sidebar.BackgroundColor3 = Theme.Sidebar
    self.Sidebar.BorderSizePixel = 0
    self.Sidebar.Parent = self.MainFrame
    Instance.new("UICorner", self.Sidebar).CornerRadius = Theme.Corner

    local layout = Instance.new("UIListLayout", self.Sidebar)
    layout.Padding = UDim.new(0, 2)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    self.Container = Instance.new("Frame")
    self.Container.Size = UDim2.new(1, -160, 1, -10)
    self.Container.Position = UDim2.new(0, 155, 0, 5)
    self.Container.BackgroundTransparency = 1
    self.Container.Parent = self.MainFrame

    self:ApplyDrag(self.MainFrame)
end

function Interface:ApplyDrag(frame)
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- ==========================================
-- 🧊 COMPONENTES DE UI
-- ==========================================
function Interface:SelectTab(name)
    for tName, tFrame in pairs(self.Tabs) do
        tFrame.Visible = (tName == name)
        local btn = self.TabButtons[tName]
        if btn then
            TweenService:Create(btn, TweenInfo.new(0.2), {
                BackgroundColor3 = (tName == name) and Theme.Element or Theme.Sidebar,
                BackgroundTransparency = (tName == name) and 0 or 1
            }):Play()
        end
    end
    self.ActiveTab = name
end

function Interface:AddTab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 30)
    btn.BackgroundColor3 = Theme.Sidebar
    btn.BackgroundTransparency = 1
    btn.Text = name
    btn.Font = Enum.Font.GothamMedium
    btn.TextColor3 = Theme.Text
    btn.Parent = self.Sidebar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    btn.MouseButton1Click:Connect(function() self:SelectTab(name) end)
    self.TabButtons[name] = btn

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 2
    scroll.Visible = false
    scroll.Parent = self.Container
    local layout = Instance.new("UIListLayout", scroll)
    layout.Padding = UDim.new(0, 5)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    self.Tabs[name] = scroll
    return scroll
end

function Interface:CreateToggle(parent, text, configKey, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.95, 0, 0, 32)
    btn.BackgroundColor3 = Theme.Element
    btn.Text = "  " .. text
    btn.Font = Enum.Font.Gotham
    btn.TextColor3 = Theme.TextDim
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = Theme.Corner

    local status = Instance.new("Frame")
    status.Size = UDim2.new(0, 20, 0, 20)
    status.Position = UDim2.new(1, -30, 0.5, -10)
    status.BackgroundColor3 = self.Config[configKey] and Theme.Accent or Color3.fromRGB(40,40,40)
    status.Parent = btn
    Instance.new("UICorner", status).CornerRadius = UDim.new(1, 0)

    btn.MouseButton1Click:Connect(function()
        self.Config[configKey] = not self.Config[configKey]
        status.BackgroundColor3 = self.Config[configKey] and Theme.Accent or Color3.fromRGB(40,40,40)
        if callback then callback(self.Config[configKey]) end
    end)
end

function Interface:CreateDropdown(parent, text, options, configKey, callback)
    local base = Instance.new("Frame")
    base.Size = UDim2.new(0.95, 0, 0, 32)
    base.BackgroundColor3 = Theme.Element
    base.Parent = parent
    Instance.new("UICorner", base).CornerRadius = Theme.Corner

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = "  " .. text .. ": " .. tostring(self.Config[configKey] or "Nenhum")
    btn.Font = Enum.Font.Gotham
    btn.TextColor3 = Theme.Text
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = base

    btn.MouseButton1Click:Connect(function()
        -- Lógica simplificada: alterna entre opções ao clicar para evitar dropdowns que travam
        local current = self.Config[configKey]
        local nextIdx = 1
        for i, v in ipairs(options) do if v == current then nextIdx = (i % #options) + 1 break end end
        local selection = options[nextIdx]
        self.Config[configKey] = selection
        btn.Text = "  " .. text .. ": " .. tostring(selection)
        if callback then callback(selection) end
    end)
    
    return function(newOptions) options = newOptions end -- Função de Refresh
end

-- ==========================================
-- 📑 CONSTRUÇÃO DAS ABAS
-- ==========================================
function Interface:CreateTabs()
    -- Dashboard
    local dash = self:AddTab("Dashboard")
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 50)
    title.Text = "Bem-vindo ao Sailor Hub\nStatus: Online"
    title.TextColor3 = Theme.Accent
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Parent = dash

    -- Combate
    local combat = self:AddTab("Combat")
    self:CreateToggle(combat, "Auto Farm Max Level", "AutoFarmMaxLevel")
    self:CreateToggle(combat, "Auto Quest", "AutoQuest")
    
    local islandList = self.Constants.QuestFilterOptions or {"Starter"}
    local questList = {"Selecione Ilha"}
    
    local refreshQuests
    self:CreateDropdown(combat, "Selecionar Ilha", islandList, "SelectedQuestIsland", function(val)
        local newQuests = {}
        if self.Constants.QuestDataMap[val] then
            for _, q in ipairs(self.Constants.QuestDataMap[val]) do table.insert(newQuests, q.Name) end
        end
        refreshQuests(newQuests)
    end)
    
    refreshQuests = self:CreateDropdown(combat, "Selecionar Missão", questList, "SelectedQuest")
    
    self:CreateToggle(combat, "Auto Dummy", "AutoDummy")
    self:CreateToggle(combat, "Auto Boss", "AutoBoss")

    -- Itens
    local items = self:AddTab("Automation")
    self:CreateToggle(items, "Coletar Frutas", "AutoCollect.Fruits")
    self:CreateToggle(items, "Coletar Hogyoku", "AutoCollect.Hogyoku")
end

function Interface:Destroy()
    if self.ScreenGui then self.ScreenGui:Destroy() end
end

return Interface
