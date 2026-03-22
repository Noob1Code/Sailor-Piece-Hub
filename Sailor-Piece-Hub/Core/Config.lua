-- =====================================================================
-- ⚙️ CORE: Config.lua (Estado Dinâmico e Preferências do Usuário)
-- =====================================================================

local HttpService = game:GetService("HttpService")

local Config = {
    -- Variável mestre de controle do ciclo de vida
    IsRunning = true, 
    
    -- ==========================================
    -- 🌍 CONTROLE DE MAPA E SPAWN
    -- ==========================================
    CurrentSpawnIsland = "Nenhuma", -- Evita setar spawn múltiplas vezes
    SelectedIslandFilter = "Todas", -- Guarda o filtro atual da UI para a lógica "Todos"
    
    -- ==========================================
    -- ⚔️ COMBATE & MOVIMENTO
    -- ==========================================
    Distance = 5,
    TweenSpeed = 150,
    AttackPosition = "Atrás",
    SelectedWeapon = "Nenhuma",
    
    -- Mobs
    AutoFarm = false,
    SelectedMob = "Nenhum",
    
    -- Bosses
    AutoBoss = false,
    SelectedBoss = "Nenhum",
    SelectedBosses = {},
    
    -- Summon & Dummy
    AutoSummon = false,
    SelectedSummonBoss = "Nenhum",
    AutoDummy = false,
    
    -- ==========================================
    -- 📜 MISSÕES (QUESTS)
    -- ==========================================
    AutoQuest = false,
    SelectedQuestIsland = "Starter",
    SelectedQuest = nil,
    AutoFarmMaxLevel = false,
    
    -- ==========================================
    -- 🎒 COLETA & ITENS
    -- ==========================================
    AutoCollect = {
        Fruits = false,
        Hogyoku = false,
        Puzzles = false,
        Chests = false
    },
    AutoGroupReward = false,
    
    -- ==========================================
    -- 📈 STATUS (STATS)
    -- ==========================================
    AutoStats = false,
    SelectedStats = {},
    ManualStat = "Melee",
    ManualAmount = 1,
    
    -- ==========================================
    -- 🎲 ROLETA & BAÚS (REROLL)
    -- ==========================================
    ChestOpenAmount = 1,
    AutoOpenChests = {
        Common = false, Rare = false, Epic = false, Legendary = false, Mythical = false
    },
    AutoReroll = {
        Race = false, TargetRace = "Kitsune", Clan = false, TargetClan = "Gojo"
    },
    AutoTrait = false,
    AutoStatReroll = false,
    SelectedStatToReroll = "Damage",
    
    -- ==========================================
    -- ⚡ MISC & HACKS NATIVOS
    -- ==========================================
    SuperSpeed = false,
    SpeedMultiplier = 2,
    InfJump = false,
    FruitSniper = false,
    
    HacksNativos = {
        HakiArmamento = false,
        HakiObservacao = false,
        NoShake = false,
        NoCutscene = false,
        DisablePvP = false,
        PuloExtra = false
    }
}

-- =====================================================================
-- 💾 SISTEMA DE SALVAMENTO ENCAPSULADO (OOP)
-- =====================================================================
local ConfigFolderName = "ComunidadeHub"
local ConfigFileName = ConfigFolderName .. "/SailorPiece_Config.json"

function Config:Save()
    pcall(function()
        if not isfolder or not writefile then return end
        if not isfolder(ConfigFolderName) then makefolder(ConfigFolderName) end
        
        local DataToSave = {
            SelectedWeapon = self.SelectedWeapon,
            Distance = self.Distance,
            TweenSpeed = self.TweenSpeed,
            AttackPosition = self.AttackPosition,
            SelectedIslandFilter = self.SelectedIslandFilter,
            SelectedMob = self.SelectedMob,
            SelectedBoss = self.SelectedBoss,
            SelectedBosses = self.SelectedBosses,
            SelectedSummonBoss = self.SelectedSummonBoss,
            SelectedQuestIsland = self.SelectedQuestIsland,
            HacksNativos = self.HacksNativos,
            AutoCollect = self.AutoCollect,
            AutoOpenChests = self.AutoOpenChests,
            AutoReroll = self.AutoReroll
        }
        
        local JSONData = HttpService:JSONEncode(DataToSave)
        writefile(ConfigFileName, JSONData)
    end)
end

function Config:Load()
    pcall(function()
        if isfile and readfile and isfile(ConfigFileName) then
            local JSONData = readfile(ConfigFileName)
            local DecodedData = HttpService:JSONDecode(JSONData)
            if type(DecodedData) == "table" then
                for key, value in pairs(DecodedData) do
                    if self[key] ~= nil then
                        if type(value) == "table" and type(self[key]) == "table" then
                            for subKey, subValue in pairs(value) do self[key][subKey] = subValue end
                        else
                            self[key] = value
                        end
                    end
                end
            end
        end
    end)
end

Config:Load()
return Config
