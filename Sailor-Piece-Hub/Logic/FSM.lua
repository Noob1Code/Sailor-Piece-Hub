-- =====================================================================
-- 🧠 LOGIC: FSM.lua (Cérebro OOP Refatorado para o Sistema Dual-Tick)
-- Responsabilidade: O exato Padrão do Script Original (Cérebro Lento + Musculo Rápido)
-- Isso erradica para sempre os travamentos do CoreScriptsProfiler.
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
    
    self.LastBrainTick = 0
    self.LastMuscleTick = 0
    self.LastBackgroundTick = 0
    self.LastSummonTime = 0
    
    self.BossState = {}
    self.BossPatience = 0
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
        
        local prompt = fruitInstance:FindFirstChildWhichIsA("ProximityPrompt", true) or (fruitInstance.Parent and fruitInstance.Parent:FindFirstChildWhichIsA("ProximityPrompt", true))
        local clicker = fruitInstance:FindFirstChildWhichIsA("ClickDetector", true)
        
        if prompt or clicker then
            local pos = fruitInstance:IsA("BasePart") and fruitInstance.Position or (fruitInstance:IsA("Model") and fruitInstance.PrimaryPart and fruitInstance.PrimaryPart.Position)
            if not pos then local part = fruitInstance:FindFirstChildWhichIsA("BasePart", true); if part then pos = part.Position end end
            
            if pos then
                local char = LP.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    if _G.SendToast then _G.SendToast("🍎 Sniper Ativado", "Coletando: " .. fruitInstance.Name, 4) end
                    char.HumanoidRootPart.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
                    task.wait(0.5)
                    pcall(function()
                        if prompt and fireproximityprompt then fireproximityprompt(prompt) end
                        if clicker and fireclickdetector then fireclickdetector(clicker) end
                    end)
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
-- 🔄 MOTOR DE ESTADO E LIMITADOR DE DESEMPENHO (O Segredo!)
-- =========================================================
function FSM:Update(deltaTime)
    local now = tick()
    
    -- ⚡ LOOP RÁPIDO (Músculos - Voo/Tweens) - Executa a cada 0.05 segundos
    if now - self.LastMuscleTick >= 0.05 then
        self.LastMuscleTick = now
        self:_MuscleUpdate()
    end
    
    -- 🧠 LOOP LENTO (Cérebro - Busca de NPCs/Missões) - Executa a cada 1 segundo (Evita o Lag!)
    if now - self.LastBrainTick >= 1.0 then
        self.LastBrainTick = now
        self:_BrainUpdate()
        self:_HandleBackgroundTasks()
    end
end

-- =========================================================
-- 🧠 CÉREBRO: TOMADA DE DECISÃO E PRIORIDADES
-- =========================================================
function FSM:_BrainUpdate()
    local myIsland = self:_GetCurrentIsland()
    local hasAction = false
    
    if self.Config.AutoBoss and not self.LastAutoBossState then
        for _, b in ipairs(self.Config.SelectedBosses) do self.BossState[b] = "PendingCheck" end
        self.BossPatience = 0
    end
    self.LastAutoBossState = self.Config.AutoBoss

    -- 0. Coleta Terrestre de Área (Mais Prioritária Temporária)
    local checkList = { { Ativo = self.Config.AutoCollect.Fruits, Tipo = "Fruits" }, { Ativo = self.Config.AutoCollect.Hogyoku, Tipo = "Hogyokus" }, { Ativo = self.Config.AutoCollect.Puzzles, Tipo = "Puzzles" }, { Ativo = self.Config.AutoCollect.Chests, Tipo = "Chests" } }
    for _, configItem in ipairs(checkList) do
        if configItem.Ativo then
            local items = self.ItemCache:GetItems(configItem.Tipo)
            if #items > 0 then self.TargetManager:SetInteractionTarget(items[1].Instance); hasAction = true; break end
        end
    end

    -- 1. Auto Summon
    if not hasAction and self.Config.AutoSummon and self.Config.SelectedSummonBoss ~= "Nenhum" then
        local targetIsland = "Boss Island"
        local bTarget = self:_FindValidTarget("Boss", self.Config.SelectedSummonBoss, targetIsland)
        if bTarget then
            if myIsland ~= targetIsland then self.CombatService:SmartIslandTeleport(targetIsland)
            else self.TargetManager:SetTarget(bTarget) end
            hasAction = true
        else
            if myIsland ~= targetIsland then self.CombatService:SmartIslandTeleport(targetIsland)
            else
                if tick() - self.LastSummonTime > 5 and self.CombatService.Remotes.SummonBoss then
                    self.CombatService.Remotes.SummonBoss:FireServer(self.Config.SelectedSummonBoss)
                    self.LastSummonTime = tick()
                end
            end
            hasAction = true
        end
    end

    -- 2. Máquina de Boss
    if not hasAction and self.Config.AutoBoss and #self.Config.SelectedBosses > 0 then
        local bossName, targetIsland
        -- Identifica quem caçar baseado no Status
        for _, b in ipairs(self.Config.SelectedBosses) do if self.BossState[b] == "Alive" then bossName = b; targetIsland = self:_GetIslandByTarget("Boss", b); break end end
        if not bossName then for _, b in ipairs(self.Config.SelectedBosses) do if self.BossState[b] == "PendingCheck" then bossName = b; targetIsland = self:_GetIslandByTarget("Boss", b); break end end end
        
        if bossName and targetIsland then
            local bTarget = self:_FindValidTarget("Boss", bossName, targetIsland)
            if bTarget then
                self.BossState[bossName] = "Alive"
                self.BossPatience = 0
                self.TargetManager:SetTarget(bTarget)
                hasAction = true
            else
                if myIsland ~= targetIsland then
                    self.CombatService:SmartIslandTeleport(targetIsland)
                    hasAction = true
                else
                    self.BossPatience = self.BossPatience + 1
                    if self.BossPatience > ((self.BossState[bossName] == "Alive") and 10 or 4) then
                        self.BossState[bossName] = "Dead"
                        self.BossPatience = 0
                    end
                    hasAction = true
                end
            end
        end
    end

    -- 3. Missões e Level
    if not hasAction and (self.Config.AutoFarmMaxLevel or self.Config.AutoQuest) then
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
            local mobIsland = self:_GetIslandByTarget(qData.Type or "Mob", qData.Target) or npcIsland
            
            if not self:_IsQuestActive(qData) then
                if myIsland ~= npcIsland then self.CombatService:SmartIslandTeleport(npcIsland); hasAction = true
                else
                    local npc = Workspace:FindFirstChild("ServiceNPCs") and Workspace.ServiceNPCs:FindFirstChild(qData.NPC)
                    self.TargetManager:SetInteractionTarget(npc); hasAction = true
                end
            else
                if myIsland ~= mobIsland then self.CombatService:SmartIslandTeleport(mobIsland); hasAction = true
                else
                    local mob = self:_FindValidTarget(qData.Type or "Mob", qData.Target, mobIsland)
                    self.TargetManager:SetTarget(mob); hasAction = true
                end
            end
        end
    end

    -- 4. Dummy e Mob (Com FIX da Ilha Atual para "Todos")
    if not hasAction then
        if self.Config.AutoDummy then
            self.TargetManager:SetTarget(self:_FindValidTarget("Dummy", ""))
            hasAction = true
        elseif self.Config.AutoFarm and self.Config.SelectedMob ~= "Nenhum" then
            local expectedIsland = self.Config.SelectedMob == "Todos" and (self.Config.SelectedIslandFilter ~= "Todas" and self.Config.SelectedIslandFilter or myIsland) or self:_GetIslandByTarget("Mob", self.Config.SelectedMob)
            if expectedIsland and myIsland ~= expectedIsland then self.CombatService:SmartIslandTeleport(expectedIsland); hasAction = true
            else
                self.TargetManager:SetTarget(self:_FindValidTarget("Mob", self.Config.SelectedMob, expectedIsland))
                hasAction = true
            end
        end
    end

    -- Limpa a memória se não houver tarefas
    if not hasAction then
        self.TargetManager:ClearTarget()
        self.TargetManager:ClearInteractionTarget()
    end
end

-- =========================================================
-- ⚡ MÚSCULOS: MOVIMENTAÇÃO E INTERAÇÃO
-- =========================================================
function FSM:_MuscleUpdate()
    local interactTarget = self.TargetManager:GetInteractionTarget()
    local combatTarget = self.TargetManager:GetTarget()
    local attacking = false
    
    if interactTarget then
        if self.CombatService:MoveToTarget(interactTarget, 1.5) then
            pcall(function()
                local prompt = interactTarget:FindFirstChildWhichIsA("ProximityPrompt", true) or (interactTarget.Parent and interactTarget.Parent:FindFirstChildWhichIsA("ProximityPrompt", true))
                if prompt and prompt:IsA("ProximityPrompt") and prompt.Enabled and fireproximityprompt then fireproximityprompt(prompt) end
                local clicker = interactTarget:FindFirstChildWhichIsA("ClickDetector", true)
                if clicker and clicker:IsA("ClickDetector") and fireclickdetector then fireclickdetector(clicker) end
            end)
            if self.IsCollecting then self.TargetManager:ClearInteractionTarget() end
        end
        attacking = true
    elseif combatTarget then
        if self.CombatService:MoveToTarget(combatTarget) then
            self.CombatService:ExecuteAttack(combatTarget)
        end
        attacking = true
    end
    
    if not attacking then
        self.CombatService:SetCharacterFrozen(false)
    end
end

-- =========================================================
-- ⚙️ TAREFAS DE SEGUNDO PLANO (Status, Rerolls, Hacks)
-- =========================================================
function FSM:_HandleBackgroundTasks()
    pcall(function()
        if self.Config.AutoStats then
            local data = LP:FindFirstChild("Data")
            if data and data:FindFirstChild("StatPoints") and data.StatPoints.Value > 0 and self.CombatService.Remotes.AllocateStat then
                local pts = data.StatPoints.Value; local qt = #self.Config.SelectedStats
                if qt > 0 then local bp = math.floor(pts / qt); local rem = pts % qt; for i, st in ipairs(self.Config.SelectedStats) do local ap = bp + (i <= rem and 1 or 0); if ap > 0 then self.CombatService.Remotes.AllocateStat:FireServer(st, ap) end end end
            end
        end
        
        if self.CombatService.Remotes.UseItem then
            if self.Config.AutoReroll.Race and LP:GetAttribute("CurrentRace") ~= self.Config.AutoReroll.TargetRace then self.CombatService.Remotes.UseItem:FireServer("Use", "Race Reroll", 1, false) end
            if self.Config.AutoReroll.Clan and LP:GetAttribute("CurrentClan") ~= self.Config.AutoReroll.TargetClan then self.CombatService.Remotes.UseItem:FireServer("Use", "Clan Reroll", 1, false) end
            local amt = self.Config.ChestOpenAmount or 1
            if self.Config.AutoOpenChests.Common then self.CombatService.Remotes.UseItem:FireServer("Use", "Common Chest", amt, false) end
            if self.Config.AutoOpenChests.Rare then self.CombatService.Remotes.UseItem:FireServer("Use", "Rare Chest", amt, false) end
            if self.Config.AutoOpenChests.Epic then self.CombatService.Remotes.UseItem:FireServer("Use", "Epic Chest", amt, false) end
            if self.Config.AutoOpenChests.Legendary then self.CombatService.Remotes.UseItem:FireServer("Use", "Legendary Chest", amt, false) end
            if self.Config.AutoOpenChests.Mythical then self.CombatService.Remotes.UseItem:FireServer("Use", "Mythical Chest", amt, false) end
        end
        
        if self.Config.AutoTrait and self.CombatService.Remotes.TraitReroll then self.CombatService.Remotes.TraitReroll:FireServer() end
        if self.Config.AutoStatReroll and self.CombatService.Remotes.RerollSingleStat then self.CombatService.Remotes.RerollSingleStat:InvokeServer(self.Config.SelectedStatToReroll) end

        if self.Config.AutoGroupReward and not self.TargetManager:GetTarget() and not self.TargetManager:GetInteractionTarget() then
            local npc = Workspace:FindFirstChild("ServiceNPCs") and Workspace.ServiceNPCs:FindFirstChild("GroupRewardNPC")
            if npc then self.TargetManager:SetInteractionTarget(npc) end
        end
        
        if self.Config.HacksNativos.PuloExtra then LP:SetAttribute("RaceExtraJumps", 5) end
        if self.Config.SuperSpeed then
            local char = LP.Character; local hum = char and char:FindFirstChild("Humanoid")
            if hum and hum.MoveDirection.Magnitude > 0 then char:TranslateBy(hum.MoveDirection * (self.Config.SpeedMultiplier or 2)) end
        end
    end)
end

-- =========================================================
-- 🔍 BUSCAS E RECONHECIMENTO (Helpers)
-- =========================================================
function FSM:_FindValidTarget(typeStr, name, expectedIsland)
    local char = LP.Character; local myPos = char and char:FindFirstChild("HumanoidRootPart") and char.HumanoidRootPart.Position or Vector3.zero
    local closest, minDist = nil, math.huge
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
                        local mobIsland = self:_GetIslandByTarget("Mob", baseName)
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

function FSM:_GetIslandByTarget(typeStr, name)
    for island, data in pairs(self.Constants.IslandDataMap) do
        if typeStr == "Mob" and data.Mobs then for _, mob in ipairs(data.Mobs) do if mob == name then return island end end
        elseif typeStr == "Boss" and data.Bosses then for _, boss in ipairs(data.Bosses) do if boss == name then return island end end end
    end
    return nil
end

function FSM:_GetCurrentIsland()
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
                    local island = self:_GetIslandByTarget(isBoss and "Boss" or "Mob", npc.Name:gsub("%d+", ""))
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
