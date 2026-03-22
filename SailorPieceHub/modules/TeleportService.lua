-- =========================================================================
-- 🗺️ TeleportService
-- Gerencia as viagens entre ilhas, salvar spawn e banco de dados de Mobs.
-- =========================================================================

local GameServices = Import("core/GameServices")
local Remotes = Import("core/Remotes")

local TeleportService = {}
TeleportService.__index = TeleportService

local IslandData = {
    ["Starter"] = {"Thief", "Bandit"},
    ["Jungle"] = {"Monkey", "Gorilla"},
    ["Desert"] = {"DesertBandit", "DesertOfficer"},
    ["Snow"] = {"SnowBandit", "Snowman"},
    ["Sailor"] = {"Marine", "MarineCaptain"},
    ["Shibuya"] = {"Curse", "SpecialCurse"},
    ["Hueco Mundo"] = {"Hollow", "Arrancar"},
    ["Judgement"] = {"Guard", "EliteGuard"}
}

function TeleportService.new()
    local self = setmetatable({
        _lastTeleport = 0
    }, TeleportService)
    return self
end

function TeleportService:GetIslands()
    local list = {}
    for island, _ in pairs(IslandData) do
        table.insert(list, island)
    end
    return list
end
function TeleportService:GetMobsFromIsland(islandName)
    if IslandData[islandName] then
        return IslandData[islandName]
    end
    return {"Nenhum"}
end
function TeleportService:GetIslandByMob(mobName)
    for island, mobs in pairs(IslandData) do
        if table.find(mobs, mobName) then
            return island
        end
    end
    return nil
end
function TeleportService:TeleportToIsland(islandName)
    if not islandName then return end
    if tick() - self._lastTeleport > 4 then
        if Remotes.TeleportRemote then
            Remotes.TeleportRemote:FireServer(islandName)
            self._lastTeleport = tick()
            print("🗺️ Viajando para a ilha: " .. islandName)
        end
    end
end

function TeleportService:SaveSpawn()
end

return TeleportService
