-- =====================================================================
-- ⚙️ CORE: Config.lua
-- Responsabilidade: Manter o estado das configurações do usuário.
-- =====================================================================
local HttpService = game:GetService("HttpService")

local Config = {
    IsRunning = true, 
    CurrentSpawnIsland = "Nenhuma",
    SelectedIslandFilter = "Todas",
    
    -- Combate
    Distance = 5,
    TweenSpeed = 150,
    AttackPosition = "Atrás",
    SelectedWeapon = "Nenhuma",
    
    -- Alvos
    AutoFarm = false, SelectedMob = "Nenhum",
    AutoBoss = false, SelectedBoss = "Nenhum", SelectedBosses = {},
    AutoSummon = false, SelectedSummonBoss = "Nenhum",
    AutoDummy = false,
    
    -- Missões
    AutoQuest = false, SelectedQuestIsland = "Starter", SelectedQuest = nil,
    AutoFarmMaxLevel = false,
    
    -- Itens
    AutoCollect = { Fruits = false, Hogyoku = false, Puzzles = false, Chests = false },
    AutoGroupReward = false, FruitSniper = false,
    
    -- Status & Reroll
    AutoStats = false, SelectedStats = {}, ManualStat = "Melee", ManualAmount = 1,
    ChestOpenAmount = 1,
    AutoOpenChests = { Common = false, Rare = false, Epic = false, Legendary = false, Mythical = false },
    AutoReroll = { Race = false, TargetRace = "Kitsune", Clan = false, TargetClan = "Gojo" },
    AutoTrait = false, AutoStatReroll = false, SelectedStatToReroll = "Damage",
    
    -- Misc
    SuperSpeed = false, SpeedMultiplier = 2, InfJump = false,
    HacksNativos = { HakiArmamento = false, HakiObservacao = false, NoShake = false, NoCutscene = false, DisablePvP = false, PuloExtra = false }
}

local ConfigFolderName = "ComunidadeHub"
local ConfigFileName = ConfigFolderName .. "/SailorPiece_Config.json"

function Config:Save()
    pcall(function()
        if not isfolder or not writefile then return end
        if not isfolder(ConfigFolderName) then makefolder(ConfigFolderName) end
        
        local DataToSave = {
            SelectedWeapon = self.SelectedWeapon, Distance = self.Distance, TweenSpeed = self.TweenSpeed, AttackPosition = self.AttackPosition,
            SelectedIslandFilter = self.SelectedIslandFilter, SelectedMob = self.SelectedMob, SelectedBoss = self.SelectedBoss,
            SelectedBosses = self.SelectedBosses, SelectedSummonBoss = self.SelectedSummonBoss, SelectedQuestIsland = self.SelectedQuestIsland,
            HacksNativos = self.HacksNativos, AutoCollect = self.AutoCollect, AutoOpenChests = self.AutoOpenChests, AutoReroll = self.AutoReroll
        }
        writefile(ConfigFileName, HttpService:JSONEncode(DataToSave))
    end)
end

function Config:Load()
    pcall(function()
        if isfile and readfile and isfile(ConfigFileName) then
            local DecodedData = HttpService:JSONDecode(readfile(ConfigFileName))
            if type(DecodedData) == "table" then
                for key, value in pairs(DecodedData) do
                    if self[key] ~= nil then
                        if type(value) == "table" and type(self[key]) == "table" then
                            for subKey, subValue in pairs(value) do self[key][subKey] = subValue end
                        else self[key] = value end
                    end
                end
            end
        end
    end)
end

Config:Load()
return Config
