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
            if obj and obj.Parent then self:Categorize(obj) end
        end)
    end))
    
    table.insert(self._connections, self.Workspace.DescendantRemoving:Connect(function(obj)
        self:Uncategorize(obj)
    end))
    
    return self
end

function ItemCache:IgnoreItem(obj)
    if typeof(obj) == "Instance" then
        self.Blacklist[obj] = true
        self:Uncategorize(obj) 
    end
end

function ItemCache:Categorize(obj)
    if typeof(obj) ~= "Instance" or self.Blacklist[obj] then return end 
    
    local name = string.lower(obj.Name)
    
    if (name:find("fruit") or name:find("fruta")) and not name:find("dealer") and not name:find("npc") then
        self.Cache.Fruits[obj] = true
    elseif name:find("hogyoku") or name:find("fragment") then
        self.Cache.Hogyokus[obj] = true
    elseif name:find("puzzlepiece") or name:find("puzzle") then
        self.Cache.Puzzles[obj] = true
    elseif name:find("box") or name:find("chest") then
        self.Cache.Chests[obj] = true
    end
end

function ItemCache:Uncategorize(obj)
    if typeof(obj) == "Instance" then
        self.Cache.Fruits[obj] = nil
        self.Cache.Hogyokus[obj] = nil
        self.Cache.Puzzles[obj] = nil
        self.Cache.Chests[obj] = nil
    end
end

function ItemCache:GetItems(categoryName)
    local list = {}
    local categoryTable = self.Cache[categoryName]
    
    if categoryTable then
        for obj, _ in pairs(categoryTable) do
            -- Limpeza rigorosa: previne tentar ir até um item que já foi apagado do mapa
            if typeof(obj) ~= "Instance" or not obj.Parent or not obj:IsDescendantOf(self.Workspace) then
                categoryTable[obj] = nil
                continue
            end
            
            if self.Blacklist[obj] then continue end 
            
            table.insert(list, { Instance = obj })
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
