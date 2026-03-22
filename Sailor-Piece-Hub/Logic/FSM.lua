-- =====================================================================
-- 🧠 LOGIC: FSM.lua (Cérebro Completo)
-- =====================================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local LP = Players.LocalPlayer

local FSM = {}
FSM.__index = FSM

function FSM.new(TargetManager, Config, CombatService, ItemCache, Constants)
    local self = setmetatable({}, FSM)
    self.TargetManager = TargetManager
    self.Config = Config
    self.CombatService = CombatService
    self.ItemCache = ItemCache
    self.Constants = Constants
    self.State = "IDLE"
    self.LastBackgroundTick = 0
    
    -- Controle de Bosses e Quests
    self.BossState = {}
    self.BossPatience = 0
    self.QuestGuiCache = nil
    
    self:_InitChatMonitor()
    return self
end

-- 📡 MONITOR DE CHAT (BOSS SNIPER)
function FSM:_InitChatMonitor()
    local function ParseChat(mensagem)
        if not self.Config.AutoBoss or #self.Config.SelectedBosses == 0 then return end
        local msg = string.lower(mensagem):gsub("%s+", "")
        
        if string.lower(mensagem):find("spawned") then
            for _, bossName in ipairs(self.Config.SelectedBosses) do
                local baseName = string.lower(bossName:gsub("Boss", ""):gsub("Mini", "")):gsub("%s+", "")
                if msg:find(baseName) then
                    self.BossState[bossName] = "Alive"
                    self.BossPatience = 0
                end
            end
        elseif string.lower(mensagem):find("defeated") then
            for _, bossName in ipairs(self.Config.SelectedBosses) do
                local baseName = string.lower(bossName:gsub("Boss", ""):gsub("Mini", "")):gsub("%s+", "")
                if msg:find(baseName) then
                    self.BossState[bossName] = "Dead"
                    self.BossPatience = 0
                end
            end
        end
    end

    pcall(function()
        if TextChatService then
            TextChatService.MessageReceived:Connect(function(msg) if msg and msg.Text then ParseChat(msg.Text) end end)
        end
        local defaultChat = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if defaultChat and defaultChat:FindFirstChild("OnMessageDoneFiltering") then
            defaultChat.OnMessageDoneFiltering.OnClientEvent:Connect(function(data) if data and data.Message then ParseChat(data.Message) end end)
        end
    end)
end

-- 📜 LEITOR DE INTERFACE DE QUEST
function FSM:IsQuestActive(questData)
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return false end

    local desc = self.QuestGuiCache
    if not desc or not desc.Parent or not desc.Visible then
        self.QuestGuiCache = nil
        for _, obj in ipairs(pg:GetDescendants()) do
            if obj:IsA("TextLabel") and obj.Name == "QuestRequirement" and obj.Text:find("/") then
                local isVis, temp = true, obj
                while temp and temp:IsA("GuiObject") do
                    if not temp.Visible then isVis = false break end
                    temp = temp.Parent
                end
                if isVis then self.QuestGuiCache = obj; desc = obj; break end
            end
        end
    end

    if not desc then return false end
    if not questData then return true end

    local targetBase = questData.Target:gsub("Boss", ""):gsub("Mini", ""):lower():gsub("%s+", "")
    local uiText = desc.Text:lower():gsub("%s+", "")
    local titleText = ""
    if desc.Parent then
        for _, sib in ipairs(desc.Parent:GetChildren()) do
            if sib:IsA("TextLabel") and sib.Name ~= "QuestRequirement" then titleText = titleText .. sib.Text:lower():gsub("%s+", "") end
        end
    end
    
    local isMatch = false
    if uiText:find(targetBase) or titleText:find(targetBase) then isMatch = true end
    if targetBase == "sorcerer" and (uiText:find("strong") or titleText:find("strong")) then isMatch = false end
    if targetBase == "swordsman" and (uiText:find("swordsmen") or titleText:find("swordsmen")) then isMatch = true end
    
    if isMatch then
        local curr, max = desc.Text:match("(%d+)/(%d+)")
        if curr and max and tonumber(curr) < tonumber(max) then return true end
    end
    return false
end

-- ==========================================
-- 🔄 MOTOR DE ESTADOS (UPDATE)
-- ==========================================
function FSM:Update(deltaTime)
    self:HandleBackgroundTasks()

    if self.State == "IDLE" then self:State_IDLE()
    elseif self.State == "SEARCHING" then self:State_SEARCHING()
    elseif self.State == "NAVIGATING" then self:State_NAVIGATING()
    elseif self.State == "ATTACKING" then self:State_ATTACKING()
    elseif self.State == "COLLECTING" then self:State_COLLECTING()
    end
end

function FSM:State_IDLE()
    if self.Config.AutoFarm or self.Config.AutoBoss or self.Config.AutoQuest or self.Config.AutoFarmMaxLevel or
       self.Config.AutoCollect.Fruits or self.Config.AutoCollect.Chests or self.Config.FruitSniper or self.Config.AutoDummy then
        self.State = "SEARCHING"
    else
        self.CombatService:SetCharacterFrozen(false)
    end
end

function FSM:State_SEARCHING()
    -- 1. SNIPER E COLETA RÁPIDA
    if self.Config.FruitSniper or self.Config.AutoCollect.Fruits then
        local fruits = self.ItemCache:GetItems("Fruits")
        if #fruits > 0 then self.TargetManager:SetInteractionTarget(fruits[1].Instance); self.State = "NAVIGATING"; return end
    end
    
    -- 2. AUTO BOSS (Com Chat Monitor)
    if self.Config.AutoBoss and #self.Config.SelectedBosses > 0 then
        local bossTargetName = nil
        for _, b in ipairs(self.Config.SelectedBosses) do
            if self.BossState[b] == "Alive" or not self.BossState[b] then bossTargetName = b; break end
        end
        if bossTargetName then
            local bTarget = self:FindMob("Boss", bossTargetName)
            if bTarget then
                self.BossState[bossTargetName] = "Alive"
                self.BossPatience = 0
                self.TargetManager:SetTarget(bTarget)
                self.State = "NAVIGATING"
                return
            else
                local targetIsland = self:GetIslandByTarget("Boss", bossTargetName)
                local currentIsland = self:GetCurrentIsland()
                if currentIsland and targetIsland and currentIsland ~= targetIsland then
                    self.CombatService:SmartIslandTeleport(targetIsland)
                else
                    self.BossPatience = self.BossPatience + 1
                    if self.BossPatience > 10 then self.BossState[bossTargetName] = "Dead"; self.BossPatience = 0 end
                end
            end
        end
    end

    -- 3. AUTO QUEST & LEVEL MAX
    if self.Config.AutoFarmMaxLevel or self.Config.AutoQuest then
        if self.Config.AutoFarmMaxLevel then
            local data = LP:FindFirstChild("Data")
            local lvl = data and data:FindFirstChild("Level") and data.Level.Value or 1
            for _, q in ipairs(self.Constants.QuestProgression) do
                if lvl >= q.MinLevel then self.Config.SelectedQuestIsland = q.Island; self.Config.SelectedQuest = q.Quest else break end
            end
        end

        local qData = self:GetQuestData(self.Config.SelectedQuestIsland, self.Config.SelectedQuest)
        if qData then
            local npcIsland = self.Config.SelectedQuestIsland
            local mobIsland = self:GetIslandByTarget(qData.Type or "Mob", qData.Target) or npcIsland
            local currentIsland = self:GetCurrentIsland()
            
            if not self:IsQuestActive(qData) then
                if currentIsland ~= npcIsland then 
                    self.CombatService:SmartIslandTeleport(npcIsland)
                else
                    local npc = Workspace:FindFirstChild("ServiceNPCs") and Workspace.ServiceNPCs:FindFirstChild(qData.NPC)
                    if npc then self.TargetManager:SetInteractionTarget(npc); self.State = "NAVIGATING"; return end
                end
            else
                if currentIsland ~= mobIsland then
                    self.CombatService:SmartIslandTeleport(mobIsland)
                else
                    local mob = self:FindMob(qData.Type or "Mob", qData.Target)
                    if mob then self.TargetManager:SetTarget(mob); self.State = "NAVIGATING"; return end
                end
            end
        end
    end

    -- 4. AUTO MOB MANUAL E DUMMY
    if self.Config.AutoDummy then
        local dummy = self:FindMob("Dummy", "")
        if dummy then self.TargetManager:SetTarget(dummy); self.State = "NAVIGATING"; return end
    elseif self.Config.AutoFarm and self.Config.SelectedMob ~= "Nenhum" then
        local targetIsland = self:GetIslandByTarget("Mob", self.Config.SelectedMob)
        if targetIsland and self:GetCurrentIsland() ~= targetIsland then
            self.CombatService:SmartIslandTeleport(targetIsland)
        else
            local mob = self:FindMob("Mob", self.Config.SelectedMob)
            if mob then self.TargetManager:SetTarget(mob); self.State = "NAVIGATING"; return end
        end
    end
    
    self.State = "IDLE"
end

function FSM:State_NAVIGATING()
    local combatTarget = self.TargetManager:GetTarget()
    local interactTarget = self.TargetManager:GetInteractionTarget()
    
    if not combatTarget and not interactTarget then self.State = "SEARCHING"; return end
    
    if combatTarget then
        if self.CombatService:MoveToTarget(combatTarget) then self.State = "ATTACKING" end
    elseif interactTarget then
        if self.CombatService:MoveToTarget(interactTarget, 1.5) then self.State = "COLLECTING" end
    end
end

function FSM:State_ATTACKING()
    local target = self.TargetManager:GetTarget()
    if not target then self.State = "SEARCHING"; return end
    if not self.CombatService:MoveToTarget(target) then self.State = "NAVIGATING"; return end
    self.CombatService:ExecuteAttack(target)
end

function FSM:State_COLLECTING()
    local item = self.TargetManager:GetInteractionTarget()
    if not item then self.State = "SEARCHING"; return end
    self.CombatService:MoveToTarget(item, 1.5)
    
    local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
    local clicker = item:FindFirstChildWhichIsA("ClickDetector", true)
    
    if prompt and fireproximityprompt then fireproximityprompt(prompt) end
    if clicker and fireclickdetector then fireclickdetector(clicker) end
    task.wait(0.5) -- Pausa rápida pós-coleta
end

-- ==========================================
-- 🔍 FUNÇÕES AUXILIARES DE BUSCA (MOB/ILHA)
-- ==========================================
function FSM:FindMob(typeStr, name)
    local myPos = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") and LP.Character.HumanoidRootPart.Position or Vector3.zero
    local closest, minDist = nil, math.huge
    
    local npcsFolder = Workspace:FindFirstChild("NPCs")
    if typeStr == "Dummy" and npcsFolder then
        for _, npc in ipairs(npcsFolder:GetChildren()) do if npc.Name == "TrainingDummy" or npc:GetAttribute("IsTrainingDummy") then return npc end end
    elseif typeStr == "Mob" and npcsFolder then
        for _, npc in ipairs(npcsFolder:GetChildren()) do
            local hum = npc:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 and not npc:GetAttribute("IsTrainingDummy") then
                local isBoss = npc.Name:lower():find("boss") or npc:GetAttribute("Boss")
                if not isBoss then
                    local baseName = npc.Name:gsub("%d+", "")
                    if name == "Todos" or baseName == name then 
                        local hrp = npc:FindFirstChild("HumanoidRootPart")
                        if hrp then local dist = (myPos - hrp.Position).Magnitude; if dist < minDist then minDist = dist; closest = npc end end
                    end
                end
            end
        end
    elseif typeStr == "Boss" then
        for _, obj in pairs(Workspace:GetChildren()) do
            if obj.Name:find("BossSpawn_") or obj.Name:find("TimedBoss") or obj.Name == "NPCs" then
                for _, boss in pairs(obj:GetDescendants()) do
                    if boss:IsA("Model") and boss:FindFirstChild("Humanoid") and boss.Humanoid.Health > 0 then
                        if boss.Name:find(name) and (boss:GetAttribute("Boss") or boss:GetAttribute("_IsTimedBoss") or boss.Name:lower():find("boss")) then 
                            local hrp = boss:FindFirstChild("HumanoidRootPart")
                            if hrp then local dist = (myPos - hrp.Position).Magnitude; if dist < minDist then minDist = dist; closest = boss end end
                        end
                    end
                end
            end
        end
    end
    return closest
end

function FSM:GetIslandByTarget(typeStr, name)
    for island, data in pairs(self.Constants.IslandDataMap) do
        if typeStr == "Mob" then for _, mob in ipairs(data.Mobs) do if mob == name then return island end end
        elseif typeStr == "Boss" then for _, boss in ipairs(data.Bosses) do if boss == name then return island end end end
    end
    return nil
end

function FSM:GetCurrentIsland()
    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return "Starter" end
    local myPos = char.HumanoidRootPart.Position
    local closestIsland, minDist = "Starter", math.huge
    
    local npcsFolder = Workspace:FindFirstChild("NPCs")
    if npcsFolder then
        for _, npc in pairs(npcsFolder:GetChildren()) do
            local hrp = npc:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (myPos - hrp.Position).Magnitude
                if dist < minDist then
                    local isBoss = npc.Name:lower():find("boss") or npc:GetAttribute("Boss")
                    local island = self:GetIslandByTarget(isBoss and "Boss" or "Mob", npc.Name:gsub("%d+", ""))
                    if island and island ~= "Eventos (Timed Bosses)" then minDist = dist; closestIsland = island end
                end
            end
        end
    end
    return closestIsland
end

function FSM:GetQuestData(island, name)
    if self.Constants.QuestDataMap[island] then
        for _, q in ipairs(self.Constants.QuestDataMap[island]) do if q.Name == name then return q end end
    end
    return nil
end

-- ==========================================
-- ⚙️ TAREFAS DE BACKGROUND (Itens, Status, Roleta)
-- ==========================================
function FSM:HandleBackgroundTasks()
    local now = tick()
    if now - self.LastBackgroundTick < 1.5 then return end
    self.LastBackgroundTick = now

    pcall(function()
        -- 1. Auto Stats
        if self.Config.AutoStats then
            local data = LP:FindFirstChild("Data")
            local AllocateRemote = ReplicatedStorage:FindFirstChild("AllocateStat", true)
            if data and data:FindFirstChild("StatPoints") and data.StatPoints.Value > 0 and AllocateRemote then
                local pts = math.floor(data.StatPoints.Value / #self.Config.SelectedStats)
                if pts > 0 then for _, stat in ipairs(self.Config.SelectedStats) do AllocateRemote:FireServer(stat, pts) end end
            end
        end

        -- 2. Auto Roleta & Baús
        local UseItemRemote = ReplicatedStorage:FindFirstChild("UseItem", true)
        if UseItemRemote then
            if self.Config.AutoReroll.Race and LP:GetAttribute("CurrentRace") ~= self.Config.AutoReroll.TargetRace then 
                UseItemRemote:FireServer("Use", "Race Reroll", 1, false) 
            end
            if self.Config.AutoReroll.Clan and LP:GetAttribute("CurrentClan") ~= self.Config.AutoReroll.TargetClan then 
                UseItemRemote:FireServer("Use", "Clan Reroll", 1, false) 
            end
            
            local amount = self.Config.ChestOpenAmount or 1
            if self.Config.AutoOpenChests.Common then UseItemRemote:FireServer("Use", "Common Chest", amount, false) end
            if self.Config.AutoOpenChests.Rare then UseItemRemote:FireServer("Use", "Rare Chest", amount, false) end
            if self.Config.AutoOpenChests.Epic then UseItemRemote:FireServer("Use", "Epic Chest", amount, false) end
            if self.Config.AutoOpenChests.Legendary then UseItemRemote:FireServer("Use", "Legendary Chest", amount, false) end
            if self.Config.AutoOpenChests.Mythical then UseItemRemote:FireServer("Use", "Mythical Chest", amount, false) end
        end

        -- 3. Group Reward (Pega instantâneo se estiver livre)
        if self.Config.AutoGroupReward and self.State == "IDLE" then
            local npc = Workspace:FindFirstChild("ServiceNPCs") and Workspace.ServiceNPCs:FindFirstChild("GroupRewardNPC")
            if npc then self.TargetManager:SetInteractionTarget(npc); self.State = "NAVIGATING" end
        end
    end)
end

return FSM
