-- =====================================================================
-- 🎒 SERVICES: ItemCache.lua (Sistema Otimizado de Varredura de Mapa)
-- =====================================================================
-- Substitui o loop custoso de GetDescendants por eventos passivos.
-- Mantém tabelas O(1) de acesso instantâneo aos itens do mapa.
-- =====================================================================

local ItemCache = {}
ItemCache.__index = ItemCache

function ItemCache.new(workspaceInstance)
    local self = setmetatable({}, ItemCache)
    
    self.Workspace = workspaceInstance
    self._connections = {}
    
    -- O nosso banco de dados em memória (Cache)
    self.Cache = {
        Fruits = {},
        Hogyokus = {},
        Puzzles = {},
        Chests = {}
    }
    
    -- 1. Varredura Inicial (Ocorre apenas UMA VEZ no carregamento)
    for _, obj in ipairs(self.Workspace:GetDescendants()) do
        self:Categorize(obj)
    end
    
    -- 2. Escuta Passiva de Novos Objetos (Quando algo spawna no mapa)
    table.insert(self._connections, self.Workspace.DescendantAdded:Connect(function(obj)
        -- Usamos um pequeno delay porque às vezes o objeto nasce sem o nome definitivo
        task.delay(0.1, function()
            if obj.Parent then self:Categorize(obj) end
        end)
    end))
    
    -- 3. Escuta Passiva de Remoção (Quando alguém pega a fruta ou o baú some)
    table.insert(self._connections, self.Workspace.DescendantRemoving:Connect(function(obj)
        self:Uncategorize(obj)
    end))
    
    return self
end

-- ==========================================
-- 🔍 LÓGICA DE CATEGORIZAÇÃO
-- ==========================================

function ItemCache:Categorize(obj)
    local name = string.lower(obj.Name)
    
    -- Filtro de Frutas
    if (name:find("fruit") or name:find("fruta")) and not name:find("dealer") and not name:find("npc") then
        self.Cache.Fruits[obj] = true
        return
    end
    
    -- Filtro de Hogyokus
    if name:find("hogyoku") then
        self.Cache.Hogyokus[obj] = true
        return
    end
    
    -- Filtro de Puzzles
    if name:find("puzzlepiece") or name:find("puzzle") then
        self.Cache.Puzzles[obj] = true
        return
    end
    
    -- Filtro de Baús (Chests)
    if name:find("box") or name:find("chest") then
        self.Cache.Chests[obj] = true
        return
    end
end

-- Limpa o objeto do cache instantaneamente (O(1))
function ItemCache:Uncategorize(obj)
    self.Cache.Fruits[obj] = nil
    self.Cache.Hogyokus[obj] = nil
    self.Cache.Puzzles[obj] = nil
    self.Cache.Chests[obj] = nil
end

-- ==========================================
-- 📦 MÉTODOS DE ACESSO (Para a FSM usar)
-- ==========================================

-- Retorna uma lista limpa com todos os itens disponíveis daquela categoria
function ItemCache:GetItems(categoryName)
    local list = {}
    local categoryTable = self.Cache[categoryName]
    
    if categoryTable then
        for obj, _ in pairs(categoryTable) do
            -- Validação extra: confirma se a peça tem onde clicar/interagir
            local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true) 
                        or (obj.Parent and obj.Parent:FindFirstChildWhichIsA("ProximityPrompt", true))
            local clicker = obj:FindFirstChildWhichIsA("ClickDetector", true)
            
            if prompt or clicker then
                table.insert(list, {
                    Instance = obj,
                    Prompt = prompt,
                    ClickDetector = clicker
                })
            end
        end
    end
    
    return list
end

-- ==========================================
-- 🧹 LIMPEZA TOTAL (Teardown)
-- ==========================================

function ItemCache:Destroy()
    for _, conn in ipairs(self._connections) do
        if conn then conn:Disconnect() end
    end
    self._connections = {}
    self.Cache = nil
end

return ItemCache
