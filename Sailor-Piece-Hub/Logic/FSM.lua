-- =====================================================================
-- 🧠 LOGIC: FSM.lua (Cérebro Blindado Anti-Crash V3)
-- =====================================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LP = Players.LocalPlayer

local FSM = {}
FSM.__index = FSM

function FSM.new(TargetManager, Config, CombatService, ItemCache, Constants)
    local self = setmetatable({}, FSM)
    self.TargetManager = TargetManager
    self.Config = Config
    self.CombatService = CombatService
    self.ItemCache = ItemCache
    self.Constants = Constants or { QuestFilterOptions = {}, QuestDataMap = {}, IslandDataMap = {}, QuestProgression = {} }
    
    self.State = "IDLE"
    self.LastBackgroundTick = 0
    self.HogyokuIslandIndex = 1
    self.BossState = {}
    self.BossPatience = 0
    self.QuestGuiCache = nil
    self.IsCollecting = false
    self._Connections = {} 
    
    self:_InitChatMonitor()
    self:_InitMisc()
    return self
end

function FSM:_InitMisc()
    table.insert(self._Connections, RunService.Heartbeat:Connect(function()
        if self.Config.SuperSpeed then
            local char = LP.Character
            local hum = char and char:FindFirstChild("Humanoid")
            if hum and hum.MoveDirection.Magnitude > 0 then
                char:TranslateBy(hum.MoveDirection * (self.Config.SpeedMultiplier or 2))
            end
        end
    end))
    table.insert(self._Connections, UserInputService.JumpRequest:Connect(function()
        if self.Config.InfJump then
            local hum = LP.Character and LP.Character:FindFirstChild("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end))
end

function FSM:_InitChatMonitor()
    local function ParseChat(mensagem)
        if not self.Config.AutoBoss or #self.Config.SelectedBosses == 0 then return end
        local msg = string.lower(mensagem):gsub("%s+", "")
        if msg:find("spawned") then
            for _, bossName in ipairs(self.Config.SelectedBosses) do
                local baseName = string.lower(bossName:gsub("Boss", ""):gsub("Mini", "")):gsub("%s+", "")
                if msg:find(baseName) then self.BossState[bossName] = "Alive"; self.BossPatience = 0 end
            end
        elseif msg:find("defeated") then
            for _, bossName in ipairs(self.Config.SelectedBosses) do
                local baseName = string.lower(bossName:gsub("Boss", ""):gsub("Mini", "")):gsub("%s+", "")
                if msg:find(baseName) then self.BossState[bossName] = "Dead"; self.BossPatience = 0 end
            end
        end
    end
    pcall(function()
        if TextChatService then table.insert(self._Connections, TextChatService.MessageReceived:Connect(function(msg) if msg and msg.Text then ParseChat(msg.Text) end end)) end
        local defaultChat = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if defaultChat and defaultChat:FindFirstChild("OnMessageDoneFiltering") then
            table.insert(self._Connections, defaultChat.OnMessageDoneFiltering.OnClientEvent:Connect(function(data) if data and data.Message then ParseChat(data.Message) end end))
        end
    end)
end

function FSM:Update(deltaTime)
    self:HandleBackgroundTasks()
    
    local isFarmingActive = self.Config.AutoFarm or self.Config.AutoBoss or self.Config.AutoQuest or self.Config.AutoFarmMaxLevel or self.Config.AutoDummy
    local isCollectingActive = self.Config.AutoCollect.Fruits or self.Config.AutoCollect.Hogyoku or self.Config.AutoCollect.Puzzles or self.Config.AutoCollect.Chests or self.Config.FruitSniper
    
    if not isFarmingActive and not isCollectingActive then
        if self.State ~= "IDLE" then
            self.TargetManager:ClearTarget()
            self.TargetManager:ClearInteractionTarget()
            self.State = "IDLE"
            self.IsCollecting = false
            self.CombatService:SetCharacterFrozen(false)
            if self.CombatService.CurrentTween then self.CombatService.CurrentTween:Cancel() end
        end
        return
    end

    if self.IsCollecting then return end

    if self.State == "IDLE" then self:State_IDLE()
    elseif self.State == "SEARCHING" then self:State_SEARCHING()
    elseif self.State == "NAVIGATING" then self:State_NAVIGATING()
    elseif self.State == "ATTACKING" then self:State_ATTACKING()
    elseif self.State == "COLLECTING" then self:State_COLLECTING()
    end
end

function FSM:State_IDLE()
    self.State = "SEARCHING"
end

function FSM:State_SEARCHING()
    -- 1. Coleta Terrestre
    local checkList = {
        { Ativo = self.Config.FruitSniper or self.Config.AutoCollect.Fruits, Tipo = "Fruits" },
        { Ativo = self.Config.AutoCollect.Hogyoku, Tipo = "Hogyokus" },
        { Ativo = self.Config.AutoCollect.Puzzles, Tipo = "Puzzles" },
        { Ativo = self.Config.AutoCollect.Chests, Tipo = "Chests" }
    }
    
    local achouItem = false
    for _, configItem in ipairs(checkList) do
        if configItem.Ativo then
            local items = self.ItemCache:GetItems(configItem.Tipo)
            if #items > 0 then 
                self.TargetManager:SetInteractionTarget(items[1].Instance)
                self.State = "COLLECTING"
                achouItem = true
                return 
            end
        end
    end

    -- FUNÇÃO DE TRAVA DE DESLIZAMENTO (Previne voar pelo mar e obriga Teleporte)
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local myPos = hrp and hrp.Position or Vector3.zero

    local function checkAndNavigate(targetInstance, expectedIsland)
        if not targetInstance then
            if expectedIsland and self:GetCurrentIsland() ~= expectedIsland then
                self.CombatService:SmartIslandTeleport(expectedIsland)
                return true
            end
            return false
        end
        
        local targetPos = targetInstance:IsA("Model") and targetInstance:FindFirstChild("HumanoidRootPart") and targetInstance.HumanoidRootPart.Position or targetInstance.Position
        local distance = (myPos - targetPos).Magnitude
        
        -- Se o alvo estiver a mais de 800 studs, FORCE O TELEPORTE
        if distance > 800 and expectedIsland then
             self.CombatService:SmartIslandTeleport(expectedIsland)
             return true
        end

        if targetInstance:IsA("Model") and targetInstance:FindFirstChild("Humanoid") then
            self.TargetManager:SetTarget(targetInstance)
        else
            self.TargetManager:SetInteractionTarget(targetInstance)
        end
        self.State = "NAVIGATING"
        return true
    end

    -- 2. Prioridade Boss
    if self.Config.AutoBoss and #self.Config.SelectedBosses > 0 then
        local bossTargetName = nil
        for _, b in ipairs(self.Config.SelectedBosses) do
            if self.BossState[b] == "Alive" or not self.BossState[b] then bossTargetName = b; break end
        end
        if bossTargetName then
            local bTarget = self:FindMob("Boss", bossTargetName)
            local targetIsland = self:GetIslandByTarget("Boss", bossTargetName)
            
            if bTarget then
                self.BossState[bossTargetName] = "Alive"
                self.BossPatience = 0
            else
                self.BossPatience = self.BossPatience + 1
                if self.BossPatience > 10 then self.BossState[bossTargetName] = "Dead"; self.BossPatience = 0 end
            end
            
            if checkAndNavigate(bTarget, targetIsland) then return end
        end
    end

    -- 3. Prioridade Missões/Level
    if self.Config.AutoFarmMaxLevel or self.Config.AutoQuest then
        if self.Config.AutoFarmMaxLevel then
            local data = LP:FindFirstChild("Data")
            local lvl = data and data:FindFirstChild("Level") and data.Level.Value or 1
            if self.Constants and self.Constants.QuestProgression then
                for _, q in ipairs(self.Constants.QuestProgression) do
                    if lvl >= q.MinLevel then self.Config.SelectedQuestIsland = q.Island; self.Config.SelectedQuest = q.Quest else break end
                end
            end
        end

        local qData = self:GetQuestData(self.Config.SelectedQuestIsland, self.Config.SelectedQuest)
        if qData then
            local npcIsland = self.Config.SelectedQuestIsland
            local mobIsland = self:GetIslandByTarget(qData.Type or "Mob", qData.Target) or npcIsland
            
            if not self:IsQuestActive(qData) then
                local npc = Workspace:FindFirstChild("ServiceNPCs") and Workspace.ServiceNPCs:FindFirstChild(qData.NPC)
                if checkAndNavigate(npc, npcIsland) then return end
            else
                local mob = self:FindMob(qData.Type or "Mob", qData.Target)
                if checkAndNavigate(mob, mobIsland) then return end
            end
        end
    end

    -- 4. Prioridade Dummy/Farm Manual
    if self.Config.AutoDummy then
        local dummy = self:FindMob("Dummy", "")
        if checkAndNavigate(dummy, self:GetCurrentIsland()) then return end
    elseif self.Config.AutoFarm and self.Config.SelectedMob ~= "Nenhum" then
        local targetIsland = self:GetIslandByTarget("Mob", self.Config.SelectedMob)
        local mob = self:FindMob("Mob", self.Config.SelectedMob)
        if checkAndNavigate(mob, targetIsland) then return end
    end
    
    -- 5. Lógica de Pulo de Ilhas (Hogyoku)
    local isFarmingActive = self.Config.AutoBoss or self.Config.AutoFarmMaxLevel or self.Config.AutoQuest or self.Config.AutoFarm or self.Config.AutoDummy
    if self.Config.AutoCollect.Hogyoku and not achouItem and not isFarmingActive then
        local listaIlhas = self.Constants and self.Constants.QuestFilterOptions or {}
        if #listaIlhas > 0 then
            if self.HogyokuIslandIndex > #listaIlhas then self.HogyokuIslandIndex = 1 end
            local ilhaDestino = listaIlhas[self.HogyokuIslandIndex]
            if self.CombatService:SmartIslandTeleport(ilhaDestino) then
                self.HogyokuIslandIndex = self.HogyokuIslandIndex + 1
                self.IsCollecting = true
                task.spawn(function() task.wait(3.5); self.IsCollecting = false end)
            end
        end
    end

    -- IMPORTANTE: Se o código chegou até aqui, nenhuma tarefa foi ativada.
    -- Então ele DESCONGELA o jogador para você ficar livre e voltar a andar.
    self.CombatService:SetCharacterFrozen(false)
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
    
    self.CombatService:SetCharacterFrozen(false)
    if self.IsCollecting then return end
    self.IsCollecting = true
    
    task.spawn(function()
        pcall(function()
            local pos = nil
            if item:IsA("BasePart") then pos = item.Position
            elseif item:IsA("Model") and item.PrimaryPart then pos = item.PrimaryPart.Position
            elseif item:IsA("Model") then 
                local p = item:FindFirstChildWhichIsA("BasePart", true)
                if p then pos = p.Position end
            end
            
            local char = LP.Character
            if char and char:FindFirstChild("HumanoidRootPart") and pos then
                char.HumanoidRootPart.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
                task.wait(0.5)
                
                local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true) or (item.Parent and item.Parent:FindFirstChildWhichIsA("ProximityPrompt", true))
                local clicker = item:FindFirstChildWhichIsA("ClickDetector", true)
                
                if prompt and fireproximityprompt then fireproximityprompt(prompt) end
                if clicker and fireclickdetector then fireclickdetector(clicker) end
                
                self.ItemCache:IgnoreItem(item)
                self.TargetManager:ClearInteractionTarget()
                task.wait(1.5) 
            else
                self.ItemCache:IgnoreItem(item)
                self.TargetManager:ClearInteractionTarget()
            end
        end)
        self.State = "SEARCHING"
        self.IsCollecting = false
    end)
end

function FSM:FindMob(typeStr, name)
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local myPos = hrp.Position
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
        if typeStr == "Mob" and data.Mobs then 
            for _, mob in ipairs(data.Mobs) do if mob == name then return island end end
        elseif typeStr == "Boss" and data.Bosses then 
            for _, boss in ipairs(data.Bosses) do if boss == name then return island end end 
        end
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
    if not self.Constants or not self.Constants.QuestDataMap or not self.Constants.QuestDataMap[island] then return nil end
    for _, q in ipairs(self.Constants.QuestDataMap[island]) do if q.Name == name then return q end end
    return nil
end

function FSM:IsQuestActive(questData)
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return false end
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
    if desc.Parent then
        for _, sib in ipairs(desc.Parent:GetChildren()) do if sib:IsA("TextLabel") and sib.Name ~= "QuestRequirement" then titleText = titleText .. sib.Text:lower():gsub("%s+", "") end end
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

function FSM:HandleBackgroundTasks()
    local now = tick()
    if now - self.LastBackgroundTick < 1.5 then return end
    self.LastBackgroundTick = now

    pcall(function()
        if self.Config.AutoStats then
            local data = LP:FindFirstChild("Data")
            local AllocateRemote = ReplicatedStorage:FindFirstChild("AllocateStat", true)
            if data and data:FindFirstChild("StatPoints") and data.StatPoints.Value > 0 and AllocateRemote then
                local pts = math.floor(data.StatPoints.Value / #self.Config.SelectedStats)
                if pts > 0 then for _, stat in ipairs(self.Config.SelectedStats) do AllocateRemote:FireServer(stat, pts) end end
            end
        end
        local UseItemRemote = ReplicatedStorage:FindFirstChild("UseItem", true)
        if UseItemRemote then
            if self.Config.AutoReroll.Race and LP:GetAttribute("CurrentRace") ~= self.Config.AutoReroll.TargetRace then UseItemRemote:FireServer("Use", "Race Reroll", 1, false) end
            if self.Config.AutoReroll.Clan and LP:GetAttribute("CurrentClan") ~= self.Config.AutoReroll.TargetClan then UseItemRemote:FireServer("Use", "Clan Reroll", 1, false) end
            local amount = self.Config.ChestOpenAmount or 1
            if self.Config.AutoOpenChests.Common then UseItemRemote:FireServer("Use", "Common Chest", amount, false) end
            if self.Config.AutoOpenChests.Rare then UseItemRemote:FireServer("Use", "Rare Chest", amount, false) end
            if self.Config.AutoOpenChests.Epic then UseItemRemote:FireServer("Use", "Epic Chest", amount, false) end
            if self.Config.AutoOpenChests.Legendary then UseItemRemote:FireServer("Use", "Legendary Chest", amount, false) end
            if self.Config.AutoOpenChests.Mythical then UseItemRemote:FireServer("Use", "Mythical Chest", amount, false) end
        end
        if self.Config.AutoGroupReward and self.State == "IDLE" then
            local npc = Workspace:FindFirstChild("ServiceNPCs") and Workspace.ServiceNPCs:FindFirstChild("GroupRewardNPC")
            if npc then self.TargetManager:SetInteractionTarget(npc); self.State = "NAVIGATING" end
        end
    end)
end

function FSM:Destroy()
    for _, conn in ipairs(self._Connections) do if conn then conn:Disconnect() end end
    self._Connections = {}
end

return FSM
