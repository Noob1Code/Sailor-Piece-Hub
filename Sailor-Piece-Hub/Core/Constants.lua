-- =====================================================================
-- 📚 CORE: Constants.lua (Banco de Dados Estático do Jogo)
-- =====================================================================
-- Este módulo retorna apenas uma tabela pura com os dados do jogo.
-- Não contém lógica, funções do Roblox ou variáveis de estado.
-- =====================================================================

local Constants = {}

-- 🌍 MAPA DE TELEPORTES (Nome na UI -> Nome no Jogo)
Constants.TeleportMap = {
    ["Starter"] = "Starter", 
    ["Jungle"] = "Jungle", 
    ["Desert"] = "Desert",
    ["Snow"] = "Snow", 
    ["Sailor"] = "Sailor", 
    ["Shibuya Station"] = "Shibuya",
    ["Hueco Mundo"] = "HuecoMundo", 
    ["Boss Island"] = "Boss", 
    ["Dungeon"] = "Dungeon",
    ["Shinjuku"] = "Shinjuku", 
    ["Slime"] = "Slime", 
    ["Academy"] = "Academy",
    ["Judgement"] = "Judgement", 
    ["Soul Society"] = "SoulSociety"
}

-- 🗺️ DADOS DAS ILHAS (Mobs e Bosses disponíveis por região)
Constants.IslandDataMap = {
    ["Starter"] = { Mobs = {"Thief"}, Bosses = {"ThiefBoss"} },
    ["Jungle"] = { Mobs = {"Monkey"}, Bosses = {"MonkeyBoss"} },
    ["Desert"] = { Mobs = {"DesertBandit"}, Bosses = {"DesertBoss"} },
    ["Snow"] = { Mobs = {"FrostRogue"}, Bosses = {"SnowBoss"} },
    ["Sailor"] = { Mobs = {}, Bosses = {"JinwooBoss", "AlucardBoss"} }, 
    ["Shibuya"] = { Mobs = {"Sorcerer"}, Bosses = {"PandaMiniBoss", "YujiBoss", "SukunaBoss", "GojoBoss"} },
    ["Hueco Mundo"] = { Mobs = {"Hollow"}, Bosses = {"AizenBoss"} },
    ["Shinjuku"] = { Mobs = {"Curse", "StrongSorcerer"}, Bosses = {} },
    ["Slime"] = { Mobs = {"Slime"}, Bosses = {} },
    ["Academy"] = { Mobs = {"AcademyTeacher"}, Bosses = {} },
    ["Judgement"] = { Mobs = {"Swordsman"}, Bosses = {"YamatoBoss"} },
    ["Soul Society"] = { Mobs = {"Quincy"}, Bosses = {} },
    ["Boss Island"] = { Mobs = {}, Bosses = {"SaberBoss", "QinShiBoss", "IchigoBoss", "GilgameshBoss", "BlessedMaidenBoss", "SaberAlterBoss"} },
    ["Eventos (Timed Bosses)"] = { Mobs = {}, Bosses = {"MadokaBoss", "Rimuru"} }
}

-- 📜 DADOS DAS MISSÕES (Nome, NPC que entrega, Alvo da missão e Tipo)
Constants.QuestDataMap = {
    ["Starter"] = {
        {Name = "Quest 1: Mobs (Thief)", NPC = "QuestNPC1", Target = "Thief", Type = "Mob"}, 
        {Name = "Quest 2: Boss (Thief Boss)", NPC = "QuestNPC2", Target = "ThiefBoss", Type = "Boss"}
    },
    ["Jungle"] = {
        {Name = "Quest 3: Mobs (Monkey)", NPC = "QuestNPC3", Target = "Monkey", Type = "Mob"}, 
        {Name = "Quest 4: Boss (Monkey Boss)", NPC = "QuestNPC4", Target = "MonkeyBoss", Type = "Boss"}
    },
    ["Desert"] = {
        {Name = "Quest 5: Mobs (Bandits)", NPC = "QuestNPC5", Target = "DesertBandit", Type = "Mob"}, 
        {Name = "Quest 6: Boss (Desert Boss)", NPC = "QuestNPC6", Target = "DesertBoss", Type = "Boss"}
    },
    ["Snow"] = {
        {Name = "Quest 7: Mobs (Frost Rogue)", NPC = "QuestNPC7", Target = "FrostRogue", Type = "Mob"}, 
        {Name = "Quest 8: Boss (Snow Boss)", NPC = "QuestNPC8", Target = "SnowBoss", Type = "Boss"}
    },
    ["Sailor"] = {
        {Name = "Âncora Sailor", NPC = "JinwooMovesetNPC", Target = "Nenhum", Type = "Mob"}
    },
    ["Shibuya"] = {
        {Name = "Quest 9: Mobs (Sorcerer)", NPC = "QuestNPC9", Target = "Sorcerer", Type = "Mob"}, 
        {Name = "Quest 10: Mobs (Panda Sorcerer)", NPC = "QuestNPC10", Target = "PandaMiniBoss", Type = "Boss"}
    },
    ["Hueco Mundo"] = {
        {Name = "Quest 11: Mobs (Hollow)", NPC = "QuestNPC11", Target = "Hollow", Type = "Mob"}
    },
    ["Shinjuku"] = {
        {Name = "Quest 12: Mobs", NPC = "QuestNPC12", Target = "StrongSorcerer", Type = "Mob"}, 
        {Name = "Quest 13: Mobs", NPC = "QuestNPC13", Target = "Curse", Type = "Mob"}
    },
    ["Slime"] = {
        {Name = "Quest 14: Mobs (Slime)", NPC = "QuestNPC14", Target = "Slime", Type = "Mob"}
    },
    ["Academy"] = {
        {Name = "Quest 15: Mobs (Teacher)", NPC = "QuestNPC15", Target = "AcademyTeacher", Type = "Mob"}
    },
    ["Judgement"] = {
        {Name = "Quest 16: Mobs", NPC = "QuestNPC16", Target = "Swordsman", Type = "Mob"}
    },
    ["Soul Society"] = {
        {Name = "Quest 17: Mobs", NPC = "QuestNPC17", Target = "Quincy", Type = "Mob"}
    },
    ["Boss Island"] = {
        {Name = "Âncora de Ilha", NPC = "SummonBossNPC", Target = "Nenhum", Type = "Mob"}
    }
}

-- 📊 PROGRESSÃO DE AUTO-LEVEL (Tabela de roteiro do level 1 ao Max)
Constants.QuestProgression = {
    { Island = "Starter", Quest = "Quest 1: Mobs (Thief)", MinLevel = 1 }, 
    { Island = "Starter", Quest = "Quest 2: Boss (Thief Boss)", MinLevel = 100 },
    { Island = "Jungle", Quest = "Quest 3: Mobs (Monkey)", MinLevel = 250 }, 
    { Island = "Jungle", Quest = "Quest 4: Boss (Monkey Boss)", MinLevel = 500 },
    { Island = "Desert", Quest = "Quest 5: Mobs (Bandits)", MinLevel = 750 }, 
    { Island = "Desert", Quest = "Quest 6: Boss (Desert Boss)", MinLevel = 1000 },
    { Island = "Snow", Quest = "Quest 7: Mobs (Frost Rogue)", MinLevel = 1500 }, 
    { Island = "Snow", Quest = "Quest 8: Boss (Snow Boss)", MinLevel = 2000 },
    { Island = "Shibuya", Quest = "Quest 9: Mobs (Sorcerer)", MinLevel = 3000 }, 
    { Island = "Shibuya", Quest = "Quest 10: Mobs (Panda Sorcerer)", MinLevel = 4000 },
    { Island = "Hueco Mundo", Quest = "Quest 11: Mobs (Hollow)", MinLevel = 5000 }, 
    { Island = "Shinjuku", Quest = "Quest 12: Mobs", MinLevel = 6250 },
    { Island = "Shinjuku", Quest = "Quest 13: Mobs", MinLevel = 7000 }, 
    { Island = "Slime", Quest = "Quest 14: Mobs (Slime)", MinLevel = 8000 },
    { Island = "Academy", Quest = "Quest 15: Mobs (Teacher)", MinLevel = 10000 }, 
    { Island = "Judgement", Quest = "Quest 16: Mobs", MinLevel = 10750 },
    { Island = "Soul Society", Quest = "Quest 17: Mobs", MinLevel = 11500 }
}

-- ⚙️ LISTAS ESTÁTICAS PARA MENUS (Dropdowns da UI)
Constants.FilterOptions = {"Todas", "Starter", "Jungle", "Desert", "Snow", "Shibuya", "Hueco Mundo", "Shinjuku", "Slime", "Academy", "Judgement", "Soul Society", "Boss Island", "Eventos (Timed Bosses)"}
Constants.QuestFilterOptions = {"Starter", "Jungle", "Desert", "Snow", "Shibuya", "Hueco Mundo", "Shinjuku", "Slime", "Academy", "Judgement", "Soul Society"}
Constants.StatsList = {"Melee", "Defense", "Sword", "Power"}
Constants.StatsToRerollList = {"Damage", "Luck", "Health", "Defense"}
Constants.Islands = {"Starter", "Jungle", "Desert", "Snow", "Sailor", "Shibuya", "HuecoMundo", "Boss", "Dungeon", "Shinjuku", "Slime", "Academy", "Judgement", "SoulSociety"}
Constants.NPCs = {"GroupRewardNPC", "BossRushShopNPC", "BossRushPortalNPC", "DungeonMerchantNPC", "EnchantNPC", "YujiBuyerNPC", "BlessingNPC", "SlimeCraftNPC", "RimuruMasteryNPC", "SkillTreeNPC", "Katana", "MadokaBuyer", "HakiQuestNPC", "SummonBossNPC"}
Constants.SummonBossList = {"Nenhum", "SaberBoss", "QinShiBoss", "IchigoBoss", "GilgameshBoss", "BlessedMaidenBoss", "SaberAlterBoss"}

return Constants
