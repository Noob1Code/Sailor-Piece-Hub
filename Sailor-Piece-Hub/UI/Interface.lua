-- =====================================================================
-- 🖥️ UI: Interface.lua (Gerenciador Visual e Interação do Usuário)
-- =====================================================================
-- Constrói a UI e conecta os botões/toggles diretamente ao módulo Config.
-- Não contém lógica de farm, apenas delega ações.
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
    
    -- Configuração do Parente da UI (Suporte a executores sem CoreGui)
    local uiParent = pcall(function() return CoreGui.Name end) and CoreGui or LP:WaitForChild("PlayerGui")
    if uiParent:FindFirstChild("ComunidadeHubGUI") then 
        uiParent.ComunidadeHubGUI:Destroy() 
    end
    
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "ComunidadeHubGUI"
    self.ScreenGui.Parent = uiParent
    self.ScreenGui.ResetOnSpawn = false
    
    -- Criação da Janela Principal
    self.MainFrame = Instance.new("Frame")
    self.MainFrame.Size = UDim2.new(0, 540, 0, 460)
    self.MainFrame.Position = UDim2.new(0.5, -270, 0.5, -230)
    self.MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    self.MainFrame.ClipsDescendants = true
    self.MainFrame.Parent = self.ScreenGui
    Instance.new("UICorner", self.MainFrame).CornerRadius = UDim.new(0, 8)
    
    -- Barra de Título e Arrastar (Drag)
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

    -- Áreas de Conteúdo
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

    -- Botões de Fechar e Minimizar
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

    -- Container de Notificações
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

    -- 🌟 INICIALIZA AS ABAS E OS BOTÕES
    self:BuildTabs()

    -- Notificação de Boas Vindas
    self:Notify("Hub Inicializado", "Arquitetura Modular carregada com sucesso!", 4)

    return self
end

-- ==========================================
-- 🛠️ FUNÇÕES INTERNAS DE UI (Drag, Notify)
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
    -- Lógica de UI do Toast mantida igual ao original (encapsulada de forma limpa aqui)
    duration = duration or 3 
    local Notif = Instance.new("Frame")
    Notif.Size = UDim2.new(1, 0, 0, 60)
    Notif.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    Notif.BackgroundTransparency = 1 
    Instance.new("UICorner", Notif).CornerRadius = UDim.new(0, 6)
    Notif.Parent = self.NotifyFrame
    
    local TitleLbl = Instance.new("TextLabel")
    TitleLbl.Size = UDim2.new(1, -20, 0, 20); TitleLbl.Position = UDim2.new(0, 15, 0, 5)
    TitleLbl.BackgroundTransparency = 1; TitleLbl.Text = title
    TitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255); TitleLbl.Font = Enum.Font.GothamBold; TitleLbl.TextSize = 13
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left; TitleLbl.Parent = Notif

    local DescLbl = Instance.new("TextLabel")
    DescLbl.Size = UDim2.new(1, -20, 0, 30); DescLbl.Position = UDim2.new(0, 15, 0, 25)
    DescLbl.BackgroundTransparency = 1; DescLbl.Text = text
    DescLbl.TextColor3 = Color3.fromRGB(180, 180, 180); DescLbl.Font = Enum.Font.Gotham; DescLbl.TextSize = 11
    DescLbl.TextXAlignment = Enum.TextXAlignment.Left; DescLbl.Parent = Notif

    TweenService:Create(Notif, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
    task.spawn(function()
        task.wait(duration)
        local fadeOut = TweenService:Create(Notif, TweenInfo.new(0.5), {BackgroundTransparency = 1})
        fadeOut:Play()
        fadeOut.Completed:Wait()
        Notif:Destroy()
    end)
end

-- ==========================================
-- 📚 CONSTRUÇÃO DOS MENUS (Abas)
-- ==========================================

function Interface:CreateTab(name, icon)
    -- Lógica de Aba mantida. Retorna objeto Tab para criar componentes.
    local Tab = {}
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
    
    local TabContent = Instance.new("ScrollingFrame")
    TabContent.Size = UDim2.new(1, -10, 1, -10)
    TabContent.Position = UDim2.new(0, 5, 0, 5)
    TabContent.BackgroundTransparency = 1
    TabContent.ScrollBarThickness = 2
    TabContent.Visible = false
    TabContent.Parent = self.ContentContainer
    
    local ContentLayout = Instance.new("UIListLayout")
    ContentLayout.Parent = TabContent
    ContentLayout.Padding = UDim.new(0, 8) 
    ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() 
        TabContent.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 10) 
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

    -- Componentes da Aba
    function Tab:CreateLabel(text)
        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, 0, 0, 20); Label.BackgroundTransparency = 1; Label.TextColor3 = Color3.fromRGB(150, 150, 180)
        Label.Text = text; Label.TextXAlignment = Enum.TextXAlignment.Left; Label.Font = Enum.Font.GothamBold; Label.TextSize = 12
        Label.Parent = self.Container
        return Label
    end

    function Tab:CreateButton(text, callback, color)
        local Btn = Instance.new("TextButton")
        Btn.Size = UDim2.new(1, -5, 0, 32); Btn.BackgroundColor3 = color or Color3.fromRGB(45, 100, 255)
        Btn.TextColor3 = Color3.fromRGB(255, 255, 255); Btn.Text = text; Btn.Font = Enum.Font.GothamSemibold
        Btn.TextSize = 13; Btn.Parent = self.Container
        Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
        Btn.MouseButton1Click:Connect(callback)
        return Btn
    end

    function Tab:CreateToggle(text, defaultState, callback)
        local state = defaultState
        local colorOn, colorOff = Color3.fromRGB(40, 180, 80), Color3.fromRGB(40, 40, 50)
        local ToggleBtn = Instance.new("TextButton")
        ToggleBtn.Size = UDim2.new(1, -5, 0, 32); ToggleBtn.BackgroundColor3 = state and colorOn or colorOff
        ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255); ToggleBtn.Text = text .. " [" .. (state and "ON" or "OFF") .. "]"
        ToggleBtn.Font = Enum.Font.GothamSemibold; ToggleBtn.TextSize = 13; ToggleBtn.Parent = self.Container
        Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 4)
        
        ToggleBtn.MouseButton1Click:Connect(function()
            state = not state
            TweenService:Create(ToggleBtn, TweenInfo.new(0.3), {BackgroundColor3 = state and colorOn or colorOff}):Play()
            ToggleBtn.Text = text .. " [" .. (state and "ON" or "OFF") .. "]"
            callback(state)
        end)
    end

    -- Dropdown modularizado
    function Tab:CreateDropdown(title, options, defaultOption, callback)
        local DropFrame = Instance.new("Frame")
        DropFrame.Size = UDim2.new(1, -5, 0, 32); DropFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        DropFrame.ClipsDescendants = true; DropFrame.Parent = self.Container
        Instance.new("UICorner", DropFrame).CornerRadius = UDim.new(0, 4)
        
        local MainBtn = Instance.new("TextButton")
        MainBtn.Size = UDim2.new(1, 0, 0, 32); MainBtn.BackgroundTransparency = 1; MainBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        MainBtn.Text = "  " .. title .. ": " .. tostring(defaultOption); MainBtn.Font = Enum.Font.GothamSemibold
        MainBtn.TextSize = 12; MainBtn.TextXAlignment = Enum.TextXAlignment.Left; MainBtn.Parent = DropFrame
        
        local ListFrame = Instance.new("ScrollingFrame")
        ListFrame.Size = UDim2.new(1, 0, 1, -32); ListFrame.Position = UDim2.new(0, 0, 0, 32)
        ListFrame.BackgroundTransparency = 1; ListFrame.ScrollBarThickness = 2; ListFrame.Parent = DropFrame
        local ListLayout = Instance.new("UIListLayout"); ListLayout.Parent = ListFrame
        
        local isOpen = false
        MainBtn.MouseButton1Click:Connect(function()
            isOpen = not isOpen
            local targetHeight = isOpen and math.min(ListLayout.AbsoluteContentSize.Y + 32, 140) or 32
            TweenService:Create(DropFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, -5, 0, targetHeight)}):Play()
            ListFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y)
        end)

        local function refresh(newOptions)
            for _, b in pairs(ListFrame:GetChildren()) do if b:IsA("TextButton") then b:Destroy() end end
            for _, opt in ipairs(newOptions) do
                local OptBtn = Instance.new("TextButton")
                OptBtn.Size = UDim2.new(1, 0, 0, 28); OptBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
                OptBtn.TextColor3 = Color3.fromRGB(180, 180, 180); OptBtn.Text = "  " .. tostring(opt)
                OptBtn.Font = Enum.Font.Gotham; OptBtn.TextSize = 12; OptBtn.TextXAlignment = Enum.TextXAlignment.Left; OptBtn.Parent = ListFrame
                
                OptBtn.MouseButton1Click:Connect(function()
                    MainBtn.Text = "  " .. title .. ": " .. tostring(opt)
                    callback(opt)
                    isOpen = false
                    TweenService:Create(DropFrame, TweenInfo.new(0.3), {Size = UDim2.new(1, -5, 0, 32)}):Play()
                end)
            end
        end
        refresh(options)
        return { Refresh = refresh }
    end

    return Tab
end

-- ==========================================
-- 📝 LIGAÇÃO DE DADOS: INJETANDO AS CONFIGURAÇÕES
-- ==========================================

function Interface:BuildTabs()
    local c = self.Config
    local const = self.Constants
    
    -- ⚔️ ABA COMBATE
    local TabCombat = self:CreateTab("Combate", "⚔️")
    
    TabCombat:CreateToggle("Auto Farm Mobs", c.AutoFarm, function(v) 
        c.AutoFarm = v; c:Save() 
    end)
    
    local MobDrop = TabCombat:CreateDropdown("Inimigo", {"Nenhum"}, c.SelectedMob, function(s) 
        c.SelectedMob = s; c:Save() 
    end)
    
    -- Exemplo de como povoamos os dados lendo do Constants estático (sem getgenv)
    TabCombat:CreateDropdown("Filtrar por Área", const.FilterOptions, "Todas", function(ilhaName)
        local mobsDisp = {"Nenhum"}
        if ilhaName == "Todas" then
            mobsDisp = {"Thief", "Monkey", "Sorcerer"} -- E assim por diante
        elseif const.IslandDataMap[ilhaName] then
            for _, m in ipairs(const.IslandDataMap[ilhaName].Mobs) do table.insert(mobsDisp, m) end
        end
        MobDrop.Refresh(mobsDisp)
    end)

    TabCombat:CreateLabel("---------------------------")
    TabCombat:CreateToggle("Auto Boss", c.AutoBoss, function(v) 
        c.AutoBoss = v; c:Save() 
    end)
    
    TabCombat:CreateDropdown("Selecionar Boss", const.SummonBossList, c.SelectedSummonBoss, function(s)
        c.SelectedSummonBoss = s; c:Save()
    end)

    -- 🎒 ABA ITENS & COLETA
    local TabCollect = self:CreateTab("Itens", "🎒")
    TabCollect:CreateToggle("Coletar Frutas (Map Scan Otimizado)", c.AutoCollect.Fruits, function(v) 
        c.AutoCollect.Fruits = v; c:Save() 
    end)
    TabCollect:CreateToggle("Coletar Baús do Chão", c.AutoCollect.Chests, function(v) 
        c.AutoCollect.Chests = v; c:Save() 
    end)
    
    -- 🌍 ABA MUNDO (Teleportes)
    local TabWorld = self:CreateTab("Mundo", "🌍")
    TabWorld:CreateDropdown("Viajar para Ilha", const.Islands, "Starter", function(ilhaDestino)
        local targetStr = const.TeleportMap[ilhaDestino]
        if targetStr then
            local TeleportRemote = ReplicatedStorage:FindFirstChild("TeleportToPortal", true)
            if TeleportRemote then TeleportRemote:FireServer(targetStr) end
            self:Notify("Teleporte", "Viajando para " .. ilhaDestino, 3)
        end
    end)

    -- ⚙️ ABA MISC
    local TabMisc = self:CreateTab("Misc", "⚙️")
    TabMisc:CreateToggle("Super Velocidade", c.SuperSpeed, function(v) 
        c.SuperSpeed = v; c:Save() 
    end)
    TabMisc:CreateToggle("Remover Tremores da Tela", c.HacksNativos.NoShake, function(v) 
        c.HacksNativos.NoShake = v; c:Save()
        -- Exemplo seguro de hack nativo focado no Player (Sem global states)
        pcall(function() LP:SetAttribute("DisableScreenShake", v) end)
    end)
end

function Interface:Destroy()
    if self.ScreenGui then self.ScreenGui:Destroy() end
    for _, conn in ipairs(self._connections) do
        if conn then conn:Disconnect() end
    end
end

return Interface
