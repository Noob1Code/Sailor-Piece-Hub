-- =====================================================================
-- 🎒 SERVICES: ItemCache.lua (Sistema Otimizado com Blacklist)
-- =====================================================================

local ItemCache = {}
ItemCache.__index = ItemCache

function ItemCache.new(workspaceInstance)
    local self = setmetatable({}, ItemCache)
    
    self.Workspace = workspaceInstance
    self._connections = {}
    
    self.Cache = {
        Fruits = {},
        Hogyokus = {},
        Puzzles = {},
        Chests = {}
    }
    
    -- 🚫 A SUA BLACKLIST OOP (Fica restrita a esta instância)
    self.Blacklist = {}
    
    for _, obj in ipairs(self.Workspace:GetDescendants()) do
        self:Categorize(obj)
    end
    
    table.insert(self._connections, self.Workspace.DescendantAdded:Connect(function(obj)
        task.delay(0.1, function()
            if obj.Parent then self:Categorize(obj) end
        end)
    end))
    
    table.insert(self._connections, self.Workspace.DescendantRemoving:Connect(function(obj)
        self:Uncategorize(obj)
    end))
    
    return self
end

-- Função para o Cérebro ignorar um item bugado
function ItemCache:IgnoreItem(obj)
    self.Blacklist[obj] = true
    self:Uncategorize(obj) -- Tira das listas ativas imediatamente
end

function ItemCache:Categorize(obj)
    if self.Blacklist[obj] then return end -- Se tá na blacklist, ignora
    
    local name = string.lower(obj.Name)
    
    if (name:find("fruit") or name:find("fruta")) and not name:find("dealer") and not name:find("npc") then
        self.Cache.Fruits[obj] = true
        return
    end
    
    -- Adicionado o "fragment" conforme a sua lógica
    if name:find("hogyoku") or name:find("fragment") then
        self.Cache.Hogyokus[obj] = true
        return
    end
    
    if name:find("puzzlepiece") or name:find("puzzle") then
        self.Cache.Puzzles[obj] = true
        return
    end
    
    if name:find("box") or name:find("chest") then
        self.Cache.Chests[obj] = true
        return
    end
end

function ItemCache:Uncategorize(obj)
    self.Cache.Fruits[obj] = nil
    self.Cache.Hogyokus[obj] = nil
    self.Cache.Puzzles[obj] = nil
    self.Cache.Chests[obj] = nil
end

function ItemCache:GetItems(categoryName)
    local list = {}
    local categoryTable = self.Cache[categoryName]
    
    if categoryTable then
        for obj, _ in pairs(categoryTable) do
            if self.Blacklist[obj] then continue end -- Prevenção dupla
            
            local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true) 
                        or (obj.Parent and obj.Parent:FindFirstChildWhichIsA("ProximityPrompt", true))
            local clicker = obj:FindFirstChildWhichIsA("ClickDetector", true)
            
            if prompt or clicker then
                table.insert(list, { Instance = obj, Prompt = prompt, ClickDetector = clicker })
            end
        end
    end
    return list
end

function ItemCache:Destroy()
    for _, conn in ipairs(self._connections) do if conn then conn:Disconnect() end end
    self._connections = {}
    self.Cache = nil
    self.Blacklist = nil
end

return ItemCache
