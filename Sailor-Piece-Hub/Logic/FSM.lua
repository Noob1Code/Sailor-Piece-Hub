-- =====================================================================
-- 🧠 LOGIC: FSM.lua (Cérebro OOP Refatorado - SRP)
-- Responsabilidade: Decidir o estado atual com base em prioridades (Loops).
-- =====================================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
    self.LastSummonTime = 0
    
    self.BossState = {}
    self.BossPatience = 0
    self.LastAutoBossState = false 
    self.IsCollecting = false
    self.QuestGuiCache = nil
    self._Connections = {} 
    
    self:_InitChatMonitor()
    self:_InitFruitSniper()
    return self
end

-- =========================================================
-- 🎧 EVENTOS EM TEMPO REAL (Fruit Sniper e Chat)
-- =========================================================
function FSM:_InitFruitSniper()
    self.ItemCache.OnFruitSpawned = function(fruitInstance)
        if not self.Config.FruitSniper then return end
        
        -- Lógica de Teleporte Direto (Igual ao antigo TeleportAndCollectFruit)
        local prompt = fruitInstance:FindFirstChildWhichIsA("ProximityPrompt", true) or (fruitInstance.Parent and fruitInstance.Parent:FindFirstChildWhichIsA("ProximityPrompt", true))
        local clicker = fruitInstance:FindFirstChildWhichIsA("ClickDetector", true)
        
        if prompt or clicker then
            local pos = fruitInstance:IsA("BasePart") and fruitInstance.Position or (fruitInstance:IsA("Model") and fruitInstance.PrimaryPart and fruitInstance.PrimaryPart.Position)
            if pos then
                local char = LP.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    if _G.SendToast then _G.SendToast("🍎 Sniper Ativado", "Coletando: " .. fruitInstance.Name, 4) end
                    self.CombatService:SetCharacterFrozen(true)
                    char.HumanoidRootPart.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
                    task.wait(0.5)
                    if prompt and fireproximityprompt then fireproximityprompt(prompt) end
                    if clicker and fireclickdetector then fireclickdetector(clicker) end
                    self.ItemCache:IgnoreItem(fruitInstance)
                end
            end
        end
    end
end

function FSM:_InitChatMonitor()
    local function ParseChat(mensagem)
        if not self.Config.AutoBoss or #self.Config.SelectedBosses == 0 then return end
        local msg = string.lower(mensagem)
        local msgNoSpaces = msg:gsub("%s+", "")
        
        if msg:find("spawned") then
            for _, bossName in ipairs(self.Config.SelectedBosses) do
                local baseName = string.lower(bossName:gsub("Boss", ""):gsub("Mini", "")):gsub("%s+", "")
                if msgNoSpaces:find(baseName) then 
                    self.BossState[bossName] = "Alive"
                    self.BossPatience = 0
                    if _G.SendToast then _G.SendToast("🚨 Boss Sniper", bossName .. " spawnou! Interceptando...", 4) end
                end
            end
        elseif msg:find("defeated") then
            for _, bossName in ipairs(self.Config.SelectedBosses) do
                local baseName = string.lower(bossName:gsub("Boss", ""):gsub("Mini", "")):gsub("%s+", "")
                if msgNoSpaces:find(baseName) then self.BossState[bossName] = "Dead" end
            end
        end
    end

    pcall(function()
        if TextChatService then table.insert(self._Connections, TextChatService.MessageReceived:Connect(function(msg) if msg and msg.Text then ParseChat(msg.Text) end end)) end
        local defaultChat = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if defaultChat and defaultChat:FindFirstChild("OnMessageDoneFiltering") then table.insert(self._Connections, defaultChat.OnMessageDoneFiltering.OnClientEvent:Connect(function(data) if data and data.Message then ParseChat(data.Message) end end)) end
    end)
end

-- =========================================================
-- 🔄 MOTOR DE ESTADO (Executa a cada frame)
-- =========================================================
function FSM:Update(deltaTime)
    self:_HandleBackgroundTasks()
    
    if self.Config.AutoBoss and not self.LastAutoBossState then
        for _, b in ipairs(self.Config.SelectedBosses) do self.BossState[b] = "PendingCheck" end
        self.BossPatience = 0
    end
    self.LastAutoBossState = self.Config.AutoBoss
    
    local isFarming = self.Config.AutoFarm or self.Config.AutoBoss or self.Config.AutoQuest or self.Config.AutoFarmMaxLevel or self.Config.AutoDummy or self.Config.AutoSummon
    local isCollecting = self.Config.AutoCollect.Fruits or self.Config.AutoCollect.Hogyoku or self.Config.AutoCollect.Puzzles or self.Config.AutoCollect.Chests or self.Config.AutoGroupReward
    
    if not isFarming and not isCollecting then
        if self.State ~= "IDLE" then
            self.TargetManager:ClearTarget(); self.TargetManager:ClearInteractionTarget()
            self.State = "IDLE"; self.IsCollecting = false; self.CombatService:SetCharacterFrozen(false)
            if self.CombatService.CurrentTween then self.CombatService.CurrentTween:Cancel() end
        end
        return
    end

    if self.IsCollecting then return end

    if self.State == "IDLE" then self.State = "SEARCHING"
    elseif self.State == "SEARCHING" then self:_State_SEARCHING(deltaTime)
    elseif self.State == "NAVIGATING" then self:_State_NAVIGATING()
    elseif self.State == "ATTACKING" then self:_State_ATTACKING()
    elseif self.State == "COLLECTING" then self:_State_COLLECTING()
    end
end

-- =========================================================
-- 🧠 TOMADA DE DECISÃO: LÓGICA DE PRIORIDADES
-- =========================================================
function FSM:_CheckAndNavigate(targetInstance, expectedIsland)
    if expectedIsland and self:GetCurrentIsland() ~= expectedIsland then
        self.CombatService:SmartIslandTeleport(expectedIsland)
        return true -- Corta o fluxo
    end
    
    if not targetInstance then return false end
    
    local pos = targetInstance:IsA("Model") and (targetInstance.PrimaryPart and targetInstance.PrimaryPart.Position or (targetInstance:FindFirstChildWhichIsA("BasePart", true) and targetInstance:FindFirstChildWhichIsA("BasePart", true).Position)) or targetInstance.Position
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    
    if hrp and pos and (hrp.Position - pos).Magnitude > 1000 then
        self.CombatService:SmartIslandTeleport(expectedIsland or self:GetCurrentIsland())
        return true
    end
    
    if targetInstance:IsA("Model") and targetInstance:FindFirstChild("Humanoid") then
        self.TargetManager:SetTarget(targetInstance)
    else self.TargetManager:SetInteractionTarget(targetInstance) end
    
    self.State = "NAVIGATING"
    return true
end

function FSM:_State_SEARCHING(deltaTime)
    -- PRIO 0: Itens no Chão
    local checkList = {
        { Ativo = self.Config.AutoCollect.Fruits, Tipo = "Fruits" },
        { Ativo = self.Config.AutoCollect.Hogyoku, Tipo = "Hogyokus" },
        { Ativo = self.Config.AutoCollect.Puzzles, Tipo = "Puzzles" },
        { Ativo = self.Config.AutoCollect.Chests, Tipo = "Chests" }
    }
    for _, configItem in ipairs(checkList) do
        if configItem.Ativo then
            local items = self.ItemCache:GetItems(configItem.Tipo)
            if #items > 0 then self.TargetManager:SetInteractionTarget(items[1].Instance); self.State = "COLLECTING"; return end
        end
    end

    -- PRIO 1: Auto Summon Exclusivo
    if self.Config.AutoSummon and self.Config.SelectedSummonBoss ~= "Nenhum" then
        local targetIsland = "Boss Island"
        local bTarget = self:FindMob("Boss", self.Config.SelectedSummonBoss, targetIsland)
        if bTarget then
            if self:_CheckAndNavigate(bTarget, targetIsland) then return end
        else
            if self:GetCurrentIsland() ~= targetIsland then self.CombatService:SmartIslandTeleport(targetIsland); return end
            if tick() - self.LastSummonTime > 5 then
                self.CombatService:SummonBoss(self.Config.SelectedSummonBoss)
                self.LastSummonTime = tick(); task.wait(2)
            end
            return
        end
    end

    -- PRIO 2: Máquina de Boss
    if self.Config.AutoBoss and #self.Config.SelectedBosses > 0 then
        local bossTargetName = nil
        for _, b in ipairs(self.Config.SelectedBosses) do
            if self.BossState[b] == "PendingCheck" or self.BossState[b] == "Alive" or not self.BossState[b] then 
                bossTargetName = b; if not self.BossState[b] then self.BossState[b] = "PendingCheck" end; break 
            end
        end
        
        if bossTargetName then
            local targetIsland = self:GetIslandByTarget("Boss", bossTargetName)
            if targetIsland and self:GetCurrentIsland() ~= targetIsland then
                self.BossPatience = 0; self.CombatService:SmartIslandTeleport(targetIsland); return 
            end

            local bTarget = self:FindMob("Boss", bossTargetName, targetIsland)
            if bTarget then
                self.BossState[bossTargetName] = "Alive"; self.BossPatience = 0
                if self:_CheckAndNavigate(bTarget, targetIsland) then return end
            else
                self.BossPatience = self.BossPatience + deltaTime
                local maxPatience = (self.BossState[bossTargetName] == "Alive") and 10 or 4
                if self.BossPatience > maxPatience then 
                    self.BossState[bossTargetName] = "Dead"; self.BossPatience = 0; self.TargetManager:ClearTarget()
                end
                self.CombatService:SetCharacterFrozen(false)
                return 
            end
        end
    end

    -- PRIO 3: Missões e Level
    if self.Config.AutoFarmMaxLevel or self.Config.AutoQuest then
        if self.Config.AutoFarmMaxLevel then
            local data = LP:FindFirstChild("Data")
            local lvl = data and data:FindFirstChild("Level") and data.Level.Value or 1
            for _, q in ipairs(self.Constants.QuestProgression) do
                if lvl >= q.MinLevel then self.Config.SelectedQuestIsland = q.Island; self.Config.SelectedQuest = q.Quest else break end
            end
        end

        local qData = self:_GetQuestData(self.Config.SelectedQuestIsland, self.Config.SelectedQuest)
        if qData then
            local npcIsland = self.Config.SelectedQuestIsland
            local mobIsland = self:GetIslandByTarget(qData.Type or "Mob", qData.Target) or npcIsland
            
            if not self:_IsQuestActive(qData) then
                local npc = Workspace:FindFirstChild("ServiceNPCs") and Workspace.ServiceNPCs:FindFirstChild(qData.NPC)
                if self:_CheckAndNavigate(npc, npcIsland) then return end
            else
                local mob = self:FindMob(qData.Type or "Mob", qData.Target, mobIsland)
                if self:_CheckAndNavigate(mob, mobIsland) then return end
            end
        end
    end

    -- PRIO 4: Dummy e Mob (Manual)
    if self.Config.AutoDummy then
        if self:_CheckAndNavigate(self:FindMob("Dummy", ""), self:GetCurrentIsland()) then return end
    elseif self.Config.AutoFarm and self.Config.SelectedMob ~= "Nenhum" then
        local expectedIsland = self.Config.SelectedMob == "Todos" and (self.Config.SelectedIslandFilter ~= "Todas" and self.Config.SelectedIslandFilter or self:GetCurrentIsland()) or self:GetIslandByTarget("Mob", self.Config.SelectedMob)
        if self:_CheckAndNavigate(self:FindMob("Mob", self.Config.SelectedMob, expectedIsland), expectedIsland) then return end
    end

    -- Sem Ação
    self.CombatService:SetCharacterFrozen(false)
end

function FSM:_State_NAVIGATING()
    local combatTarget = self.TargetManager:GetTarget()
    local interactTarget = self.TargetManager:GetInteractionTarget()
    
    if not combatTarget and not interactTarget then 
        self.State = "SEARCHING"; return 
    end
    
    if combatTarget then
        if self.CombatService:MoveToTarget(combatTarget) then self.State = "ATTACKING" end
    elseif interactTarget then
        if self.CombatService:MoveToTarget(interactTarget, 1.5) then self.State = "COLLECTING" end
    end
end

function FSM:_State_ATTACKING()
    local target = self.TargetManager:GetTarget()
    if not target then self.State = "SEARCHING"; return end
    
    if not self.CombatService:MoveToTarget(target) then self.State = "NAVIGATING"; return end
    self.CombatService:ExecuteAttack(target)
end

function FSM:_State_COLLECTING()
    local item = self.TargetManager:GetInteractionTarget()
    if not item then self.State = "SEARCHING"; return end
    
    self.CombatService:SetCharacterFrozen(false)
    if self.IsCollecting then return end
    self.IsCollecting = true
    
    task.spawn(function()
        pcall(function()
            local pos = item:IsA("BasePart") and item.Position or (item:IsA("Model") and item.PrimaryPart and item.PrimaryPart.Position)
            if not pos then local p = item:FindFirstChildWhichIsA("BasePart", true); if p then pos = p.Position end end
            
            local char = LP.Character
            if char and char:FindFirstChild("HumanoidRootPart") and pos then
                char.HumanoidRootPart.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
                task.wait(0.5)
                local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true) or (item.Parent and item.Parent:FindFirstChildWhichIsA("ProximityPrompt", true))
                local clicker = item:FindFirstChildWhichIsA("ClickDetector", true)
                
                if prompt and prompt:IsA("ProximityPrompt") and prompt.Enabled and fireproximityprompt then fireproximityprompt(prompt) end
                if clicker and clicker:IsA("ClickDetector") and fireclickdetector then fireclickdetector(clicker) end
                
                self.ItemCache:IgnoreItem(item); task.wait(1.5) 
            end
            self.TargetManager:ClearInteractionTarget()
        end)
        self.State = "SEARCHING"; self.IsCollecting = false
    end)
end

-- =========================================================
-- ⚙️ TAREFAS DE SEGUNDO PLANO (Status, Rerolls, Hacks)
-- =========================================================
function FSM:_HandleBackgroundTasks()
    local now = tick()
    if now - self.LastBackgroundTick < 1.0 then return end
    self.LastBackgroundTick = now

    pcall(function()
        -- Auto Stats
        if self.Config.AutoStats then
            local data = LP:FindFirstChild("Data")
            if data and data:FindFirstChild("StatPoints") and data.StatPoints.Value > 0 then
                self.CombatService:AllocateStats(self.Config.SelectedStats, data.StatPoints.Value)
            end
        end
        
        -- Auto Rerolls & Baús
        if self.Config.AutoReroll.Race and LP:GetAttribute("CurrentRace") ~= self.Config.AutoReroll.TargetRace then self.CombatService:UseItem("Use", "Race Reroll", 1) end
        if self.Config.AutoReroll.Clan and LP:GetAttribute("CurrentClan") ~= self.Config.AutoReroll.TargetClan then self.CombatService:UseItem("Use", "Clan Reroll", 1) end
        
        local amt = self.Config.ChestOpenAmount or 1
        if self.Config.AutoOpenChests.Common then self.CombatService:UseItem("Use", "Common Chest", amt) end
        if self.Config.AutoOpenChests.Rare then self.CombatService:UseItem("Use", "Rare Chest", amt) end
        if self.Config.AutoOpenChests.Epic then self.CombatService:UseItem("Use", "Epic Chest", amt) end
        if self.Config.AutoOpenChests.Legendary then self.CombatService:UseItem("Use", "Legendary Chest", amt) end
        if self.Config.AutoOpenChests.Mythical then self.CombatService:UseItem("Use", "Mythical Chest", amt) end
        
        if self.Config.AutoTrait and self.CombatService.Remotes.TraitReroll then self.CombatService.Remotes.TraitReroll:FireServer() end
        if self.Config.AutoStatReroll and self.CombatService.Remotes.RerollSingleStat then self.CombatService.Remotes.RerollSingleStat:InvokeServer(self.Config.SelectedStatToReroll) end

        -- Auto Group Reward
        if self.Config.AutoGroupReward and self.State == "IDLE" then
            local npc = Workspace:FindFirstChild("ServiceNPCs") and Workspace.ServiceNPCs:FindFirstChild("GroupRewardNPC")
            if npc then self.TargetManager:SetInteractionTarget(npc); self.State = "NAVIGATING" end
        end
        
        -- Hacks Nativos: Enforcing Pulo Extra
        if self.Config.HacksNativos.PuloExtra then LP:SetAttribute("RaceExtraJumps", 5) end
        if self.Config.SuperSpeed then
            local char = LP.Character; local hum = char and char:FindFirstChild("Humanoid")
            if hum and hum.MoveDirection.Magnitude > 0 then char:TranslateBy(hum.MoveDirection * (self.Config.SpeedMultiplier or 2)) end
        end
    end)
end

-- =========================================================
-- 🔍 FUNÇÕES AUXILIARES DE BUSCA NO MAPA
-- =========================================================
function FSM:FindMob(typeStr, name, expectedIsland)
    local char = LP.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local myPos = hrp.Position; local closest, minDist = nil, math.huge
    local npcsFolder = Workspace:FindFirstChild("NPCs")
    
    if typeStr == "Dummy" and npcsFolder then
        for _, npc in ipairs(npcsFolder:GetChildren()) do if npc.Name == "TrainingDummy" or npc:GetAttribute("IsTrainingDummy") then return npc end end
    elseif typeStr == "Mob" and npcsFolder then
        for _, npc in ipairs(npcsFolder:GetChildren()) do
            local hum = npc:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 and not npc:GetAttribute("IsTrainingDummy") then
                if not (npc.Name:lower():find("boss") or npc:GetAttribute("Boss")) then
                    local baseName = npc.Name:gsub("%d+", "")
                    local isValid = false
                    if name == "Todos" then
                        local mobIsland = self:GetIslandByTarget("Mob", baseName)
                        if mobIsland == expectedIsland or expectedIsland == "Todas" then isValid = true end
                    elseif baseName == name then isValid = true end

                    if isValid then 
                        local part = npc:FindFirstChild("HumanoidRootPart")
                        if part then local dist = (myPos - part.Position).Magnitude; if dist < minDist then minDist = dist; closest = npc end end
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
                            local part = boss:FindFirstChild("HumanoidRootPart")
                            if part then local dist = (myPos - part.Position).Magnitude; if dist < minDist then minDist = dist; closest = boss end end
                        end
                    end
                end
            end
        end
    end
    return closest
end

function FSM:GetIslandByTarget(typeStr, name)
    if not self.Constants or not self.Constants.IslandDataMap then return nil end
    for island, data in pairs(self.Constants.IslandDataMap) do
        if typeStr == "Mob" and data.Mobs then for _, mob in ipairs(data.Mobs) do if mob == name then return island end end
        elseif typeStr == "Boss" and data.Bosses then for _, boss in ipairs(data.Bosses) do if boss == name then return island end end end
    end
    return nil
end

function FSM:GetCurrentIsland()
    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return "Starter" end
    local myPos = char.HumanoidRootPart.Position
    
    local serviceNPCs = Workspace:FindFirstChild("ServiceNPCs")
    if serviceNPCs then
        local ascendNPC = serviceNPCs:FindFirstChild("AscendNPC") or serviceNPCs:FindFirstChild("JinwooMovesetNPC")
        if ascendNPC then
            local pos = ascendNPC:IsA("Model") and ascendNPC.PrimaryPart and ascendNPC.PrimaryPart.Position or (ascendNPC:IsA("BasePart") and ascendNPC.Position) or Vector3.new(252, 4, 715)
            if (myPos - pos).Magnitude < 1500 then return "Sailor" end
        end
    end

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

function FSM:_GetQuestData(island, name)
    if not self.Constants.QuestDataMap[island] then return nil end
    for _, q in ipairs(self.Constants.QuestDataMap[island]) do if q.Name == name then return q end end
    return nil
end

function FSM:_IsQuestActive(questData)
    local pg = LP:FindFirstChild("PlayerGui"); if not pg then return false end
    local desc = self.QuestGuiCache
    if not desc or not desc.Parent or not desc.Visible then
        self.QuestGuiCache = nil
        for _, obj in ipairs(pg:GetDescendants()) do
            if obj:IsA("TextLabel") and obj.Name == "QuestRequirement" and obj.Text:find("/") then
                local isVis, temp = true, obj
                while temp and temp:IsA("GuiObject") do if not temp.Visible then isVis = false break end; temp = temp.Parent end
                if isVis then self.QuestGuiCache = obj; desc = obj; break end
            end
        end
    end
    if not desc then return false end
    if not questData then return true end
    
    local targetBase = questData.Target:gsub("Boss", ""):gsub("Mini", ""):lower():gsub("%s+", "")
    local uiText = desc.Text:lower():gsub("%s+", "")
    local titleText = ""
    if desc.Parent then for _, sib in ipairs(desc.Parent:GetChildren()) do if sib:IsA("TextLabel") and sib.Name ~= "QuestRequirement" then titleText = titleText .. sib.Text:lower():gsub("%s+", "") end end end
    
    local isMatch = (uiText:find(targetBase) or titleText:find(targetBase))
    if targetBase == "sorcerer" and (uiText:find("strong") or titleText:find("strong")) then isMatch = false end
    if targetBase == "swordsman" and (uiText:find("swordsmen") or titleText:find("swordsmen")) then isMatch = true end
    
    if isMatch then
        local curr, max = desc.Text:match("(%d+)/(%d+)")
        if curr and max and tonumber(curr) < tonumber(max) then return true end
    end
    return false
end

function FSM:Destroy()
    for _, conn in ipairs(self._Connections) do if conn then conn:Disconnect() end end
    self._Connections = {}
end

return FSM
