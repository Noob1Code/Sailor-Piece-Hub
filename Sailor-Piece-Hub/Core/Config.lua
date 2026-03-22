-- =====================================================================
-- ⚙️ CORE: Config.lua (Estado Dinâmico e Preferências do Usuário)
-- =====================================================================

local HttpService = game:GetService("HttpService")

local Config = {
    -- Variável mestre de controle do ciclo de vida
    IsRunning = true,
    CurrentSpawnIsland = "Nenhuma",
    
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

-- Método para salvar as configurações
function Config:Save()
    pcall(function()
        -- Verifica se o executor suporta file system
        if not isfolder or not writefile then return end
        
        if not isfolder(ConfigFolderName) then 
            makefolder(ConfigFolderName) 
        end
        
        -- Monta a tabela apenas com o que precisa ser salvo
        local DataToSave = {
            SelectedWeapon = self.SelectedWeapon,
            Distance = self.Distance,
            TweenSpeed = self.TweenSpeed,
            AttackPosition = self.AttackPosition,
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

-- Método para carregar as configurações
function Config:Load()
    pcall(function()
        if isfile and readfile and isfile(ConfigFileName) then
            local JSONData = readfile(ConfigFileName)
            local DecodedData = HttpService:JSONDecode(JSONData)
            
            if type(DecodedData) == "table" then
                for key, value in pairs(DecodedData) do
                    -- Aplica apenas se a chave existir no Config padrão
                    if self[key] ~= nil then
                        if type(value) == "table" and type(self[key]) == "table" then
                            -- Mescla sub-tabelas (ex: HacksNativos, AutoCollect)
                            for subKey, subValue in pairs(value) do 
                                self[key][subKey] = subValue 
                            end
                        else
                            self[key] = value
                        end
                    end
                end
            end
        end
    end)
end

-- Carrega os dados salvos automaticamente na inicialização do módulo
Config:Load()

-- Retorna a tabela limpa para quem fizer o require
return Config
