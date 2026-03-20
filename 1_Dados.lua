-- SERVIÇOS DO ROBLOX
getgenv().Players = game:GetService("Players")
getgenv().RS = game:GetService("ReplicatedStorage")
getgenv().Workspace = game:GetService("Workspace")
getgenv().CoreGui = game:GetService("CoreGui")
getgenv().UserInputService = game:GetService("UserInputService")
getgenv().TweenService = game:GetService("TweenService")
getgenv().RunService = game:GetService("RunService")
getgenv().LP = Players.LocalPlayer

-- REMOTES
-- REMOTES
getgenv().CombatRemote = nil
getgenv().AbilityRemote = nil
getgenv().TeleportRemote = nil
getgenv().AllocateStatRemote = nil
getgenv().ResetStatsRemote = nil
getgenv().UseItemRemote = nil
getgenv().TitleEquipRemote = nil
getgenv().DisplayTitleEquipRemote = nil
getgenv().TraitRerollRemote = nil
getgenv().RerollSingleStatRemote = nil

pcall(function()
    getgenv().CombatRemote = RS:WaitForChild("CombatSystem"):WaitForChild("Remotes"):WaitForChild("RequestHit")
    getgenv().AbilityRemote = RS:WaitForChild("AbilitySystem"):WaitForChild("Remotes"):WaitForChild("RequestAbility")
    getgenv().TeleportRemote = RS:FindFirstChild("TeleportToPortal", true)
    getgenv().AllocateStatRemote = RS:FindFirstChild("AllocateStat", true)
    getgenv().ResetStatsRemote = RS:FindFirstChild("ResetStats", true)
    getgenv().UseItemRemote = RS:FindFirstChild("UseItem", true)
    getgenv().TitleEquipRemote = RS:FindFirstChild("TitleEquip", true)
    getgenv().DisplayTitleEquipRemote = RS:FindFirstChild("DisplayTitleEquip", true)
    getgenv().TraitRerollRemote = RS:FindFirstChild("TraitReroll", true)
    getgenv().RerollSingleStatRemote = RS:FindFirstChild("RerollSingleStat", true)
end)

-- DICIONÁRIO DE TELEPORTE
getgenv().TeleportMap = {
    ["Starter"] = "Starter", ["Jungle"] = "Jungle", ["Desert"] = "Desert",
    ["Snow"] = "Snow", ["Sailor"] = "Sailor", ["Shibuya Station"] = "Shibuya",
    ["Hueco Mundo"] = "HuecoMundo", ["Boss Island"] = "Boss", ["Dungeon"] = "Dungeon",
    ["Shinjuku"] = "Shinjuku", ["Slime"] = "Slime", ["Academy"] = "Academy",
    ["Judgement"] = "Judgement", ["Soul Society"] = "SoulSociety"
}

-- MAPA DE DADOS INTELIGENTE
getgenv().IslandDataMap = {
    ["Starter"] = { Mobs = {"Thief"}, Bosses = {"ThiefBoss"} },
    ["Jungle"] = { Mobs = {"Monkey"}, Bosses = {"MonkeyBoss"} },
    ["Desert"] = { Mobs = {"DesertBandit"}, Bosses = {"DesertBoss"} },
    ["Snow"] = { Mobs = {"FrostRogue"}, Bosses = {"SnowBoss"} },
    ["Shibuya"] = { Mobs = {"Sorcerer"}, Bosses = {"PandaMiniBoss"} }, 
    ["Hueco Mundo"] = { Mobs = {"Hollow"}, Bosses = {} },
    ["Shinjuku"] = { Mobs = {"Curse", "StrongSorcerer"}, Bosses = {} },
    ["Slime"] = { Mobs = {"Slime"}, Bosses = {} },
    ["Academy"] = { Mobs = {"AcademyTeacher"}, Bosses = {} },
    ["Judgement"] = { Mobs = {}, Bosses = {} },
    ["Soul Society"] = { Mobs = {"Swordsman", "Quincy"}, Bosses = {} },
    ["Eventos (Timed Bosses)"] = { Mobs = {}, Bosses = {"GojoBoss", "SukunaBoss", "YujiBoss", "JinwooBoss", "AizenBoss", "YamatoBoss", "AlucardBoss", "MadokaBoss", "Rimuru"} }
}

getgenv().QuestDataMap = {
    ["Starter"] = {{Name = "Quest 1: Mobs (Thief)", NPC = "QuestNPC1", Target = "Thief", Type = "Mob"}, {Name = "Quest 2: Boss (Thief Boss)", NPC = "QuestNPC2", Target = "ThiefBoss", Type = "Boss"}},
    ["Jungle"] = {{Name = "Quest 3: Mobs (Monkey)", NPC = "QuestNPC3", Target = "Monkey", Type = "Mob"}, {Name = "Quest 4: Boss (Monkey Boss)", NPC = "QuestNPC4", Target = "MonkeyBoss", Type = "Boss"}},
    ["Desert"] = {{Name = "Quest 5: Mobs (Bandits)", NPC = "QuestNPC5", Target = "DesertBandit", Type = "Mob"}, {Name = "Quest 6: Boss (Desert Boss)", NPC = "QuestNPC6", Target = "DesertBoss", Type = "Boss"}},
    ["Snow"] = {{Name = "Quest 7: Mobs (Frost Rogue)", NPC = "QuestNPC7", Target = "FrostRogue", Type = "Mob"}, {Name = "Quest 8: Boss (Snow Boss)", NPC = "QuestNPC8", Target = "SnowBoss", Type = "Boss"}},
    ["Shibuya"] = {{Name = "Quest 9: Mobs (Sorcerer)", NPC = "QuestNPC9", Target = "Sorcerer", Type = "Mob"}, {Name = "Quest 10: Mobs (Panda Sorcerer)", NPC = "QuestNPC10", Target = "PandaMiniBoss", Type = "Boss"}},
    ["Hueco Mundo"] = {{Name = "Quest 11: Mobs (Hollow)", NPC = "QuestNPC11", Target = "Hollow", Type = "Mob"}},
    ["Shinjuku"] = {{Name = "Quest 12: Mobs", NPC = "QuestNPC12", Target = "Curse", Type = "Mob"}, {Name = "Quest 13: Mobs", NPC = "QuestNPC13", Target = "StrongSorcerer", Type = "Mob"}},
    ["Slime"] = {{Name = "Quest 14: Mobs (Slime)", NPC = "QuestNPC14", Target = "Slime", Type = "Mob"}},
    ["Academy"] = {{Name = "Quest 15: Mobs (Teacher)", NPC = "QuestNPC15", Target = "AcademyTeacher", Type = "Mob"}},
    ["Judgement"] = {{Name = "Quest 16: Mobs", NPC = "QuestNPC16", Target = "Nenhum", Type = "Mob"}},
    ["Soul Society"] = {{Name = "Quest 17: Mobs", NPC = "QuestNPC17", Target = "Swordsman", Type = "Mob"}}
}

getgenv().QuestProgression = {
    { Island = "Starter", Quest = "Quest 1: Mobs (Thief)", MinLevel = 1 }, { Island = "Starter", Quest = "Quest 2: Boss (Thief Boss)", MinLevel = 100 },
    { Island = "Jungle", Quest = "Quest 3: Mobs (Monkey)", MinLevel = 250 }, { Island = "Jungle", Quest = "Quest 4: Boss (Monkey Boss)", MinLevel = 500 },
    { Island = "Desert", Quest = "Quest 5: Mobs (Bandits)", MinLevel = 750 }, { Island = "Desert", Quest = "Quest 6: Boss (Desert Boss)", MinLevel = 1000 },
    { Island = "Snow", Quest = "Quest 7: Mobs (Frost Rogue)", MinLevel = 1500 }, { Island = "Snow", Quest = "Quest 8: Boss (Snow Boss)", MinLevel = 2000 },
    { Island = "Shibuya", Quest = "Quest 9: Mobs (Sorcerer)", MinLevel = 3000 }, { Island = "Shibuya", Quest = "Quest 10: Mobs (Panda Sorcerer)", MinLevel = 4000 },
    { Island = "Hueco Mundo", Quest = "Quest 11: Mobs (Hollow)", MinLevel = 5000 }, { Island = "Shinjuku", Quest = "Quest 12: Mobs", MinLevel = 6250 },
    { Island = "Shinjuku", Quest = "Quest 13: Mobs", MinLevel = 7000 }, { Island = "Slime", Quest = "Quest 14: Mobs (Slime)", MinLevel = 8000 },
    { Island = "Academy", Quest = "Quest 15: Mobs (Teacher)", MinLevel = 10000 }, { Island = "Judgement", Quest = "Quest 16: Mobs", MinLevel = 10750 },
    { Island = "Soul Society", Quest = "Quest 17: Mobs", MinLevel = 11500 }
}

-- VARIÁVEIS DE CONTROLE (HubConfig)
getgenv().HubConfig = {
    FilterOptions = {"Todas", "Starter", "Jungle", "Desert", "Snow", "Shibuya", "Hueco Mundo", "Shinjuku", "Slime", "Academy", "Judgement", "Soul Society", "Eventos (Timed Bosses)"},
    QuestFilterOptions = {"Starter", "Jungle", "Desert", "Snow", "Shibuya", "Hueco Mundo", "Shinjuku", "Slime", "Academy", "Judgement", "Soul Society"},
    SelectedFilter = "Todas",
    AutoFarm = false, SelectedMob = "Nenhum", AvailableMobs = {},
    AutoBoss = false, SelectedBoss = "Nenhum", Bosses = {},
    AutoDummy = false, 
    SelectedWeapon = "Nenhuma", AvailableWeapons = {"Nenhuma"},
    AutoQuest = false, SelectedQuestIsland = "Starter", SelectedQuest = nil, AutoFarmMaxLevel = false,
    Distance = 5, TweenSpeed = 250, AttackPosition = "Atrás",
    AutoCollect = { Fruits = false, Hogyoku = false, Puzzles = false, Chests = false },
    AutoGroupReward = false, 
    AutoStats = false, SelectedStats = {}, StatsList = {"Melee", "Defense", "Sword", "Power"}, ManualStat = "Melee", ManualAmount = 1,
    SuperSpeed = false, SpeedMultiplier = 2, InfJump = false,
    AutoOpenChests = { Common = false, Rare = false, Epic = false, Mythical = false },
    AutoReroll = { Race = false, TargetRace = "Kitsune", Clan = false, TargetClan = "Gojo" },
    AutoTrait = false, AutoStatReroll = false, SelectedStatToReroll = "Damage", StatsToRerollList = {"Damage", "Luck", "Health", "Defense"},
    Islands = {"Starter", "Jungle", "Desert", "Snow", "Sailor", "Shibuya", "HuecoMundo", "Boss", "Dungeon", "Shinjuku", "Slime", "Academy", "Judgement", "SoulSociety"},
    NPCs = {"GroupRewardNPC", "BossRushShopNPC", "BossRushPortalNPC", "DungeonMerchantNPC", "EnchantNPC", "YujiBuyerNPC", "BlessingNPC", "SlimeCraftNPC", "RimuruMasteryNPC", "SkillTreeNPC", "Katana", "MadokaBuyer"},
    HacksNativos = { HakiArmamento = false, HakiObservacao = false, NoShake = false, NoCutscene = false, DisablePvP = false, PuloExtra = false },
    FruitSniper = false
}

-- REFERÊNCIAS INTERNAS
getgenv().MobDropdownRef = nil
getgenv().BossDropdownRef = nil
getgenv().NPCDropdownRef = nil
getgenv().QuestDropdownRef = nil
getgenv().WeaponDropdownRef = nil
getgenv().CurrentTarget = nil 
getgenv().FarmTarget = nil 
getgenv().FruitSniperEvent = nil
