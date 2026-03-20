-- IMPORTAÇÕES GLOBAIS
local LP = getgenv().LP
local Workspace = getgenv().Workspace
local RunService = getgenv().RunService
local UserInputService = getgenv().UserInputService
local HubConfig = getgenv().HubConfig
local QuestProgression = getgenv().QuestProgression
local CombatRemote = getgenv().CombatRemote
local AbilityRemote = getgenv().AbilityRemote
local AllocateStatRemote = getgenv().AllocateStatRemote
local ResetStatsRemote = getgenv().ResetStatsRemote
local UseItemRemote = getgenv().UseItemRemote
local TraitRerollRemote = getgenv().TraitRerollRemote
local RerollSingleStatRemote = getgenv().RerollSingleStatRemote
local scriptConnections = getgenv().scriptConnections

local getCurrentIsland = getgenv().getCurrentIsland
local getQuestDataByName = getgenv().getQuestDataByName
local getIslandByTarget = getgenv().getIslandByTarget
local isQuestActive = getgenv().isQuestActive
local SmartIslandTeleport = getgenv().SmartIslandTeleport
local SafeTeleport = getgenv().SafeTeleport
local getValidTarget = getgenv().getValidTarget
local executeAttackLogic = getgenv().executeAttackLogic
local unfreezeCharacter = getgenv().unfreezeCharacter
local isSafePrompt = getgenv().isSafePrompt
local TeleportAndCollectFruit = getgenv().TeleportAndCollectFruit

-- Monitor de Frutas (Sniper)
table.insert(scriptConnections, Workspace.DescendantAdded:Connect(TeleportAndCollectFruit))

-- Movimentação e Motor de Quest
task.spawn(function()
    while getgenv().isRunning and task.wait(0.05) do
        local attacking = false
        local myIsland = getCurrentIsland()
        
        if HubConfig.AutoFarmMaxLevel then
            local data = LP:FindFirstChild("Data")
            local currentLevel = data and data:FindFirstChild("Level") and data.Level.Value or 1
            local bestIsland = "Starter"; local bestQuest = "Quest 1: Mobs (Thief)"
            
            for _, q in ipairs(QuestProgression) do
                if currentLevel >= q.MinLevel then bestIsland = q.Island; bestQuest = q.Quest else break end
            end
            HubConfig.SelectedQuestIsland = bestIsland
            HubConfig.SelectedQuest = bestQuest
        end

        if HubConfig.AutoFarmMaxLevel or HubConfig.AutoQuest then
            if HubConfig.SelectedQuest then
                local questData = getQuestDataByName(HubConfig.SelectedQuestIsland, HubConfig.SelectedQuest)
                if questData then
                    local npcIsland = HubConfig.SelectedQuestIsland
                    local mobIsland = getIslandByTarget(questData.Type or "Mob", questData.Target) or npcIsland
                    
                    if not isQuestActive(questData) then
                        if myIsland and myIsland ~= npcIsland and npcIsland ~= "Eventos (Timed Bosses)" then
                            SmartIslandTeleport(npcIsland)
                            attacking = true 
                        else
                            getgenv().CurrentTarget = nil 
                            local npc = Workspace:FindFirstChild("ServiceNPCs") and Workspace.ServiceNPCs:FindFirstChild(questData.NPC)
                            if npc and npc:FindFirstChild("HumanoidRootPart") then
                                local tween = SafeTeleport(npc, 1.5)
                                if tween then
                                    tween.Completed:Wait()
                                    task.wait(0.4)
                                    local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
                                    if prompt and fireproximityprompt then fireproximityprompt(prompt) end
                                    task.wait(1) 
                                end
                            end
                            attacking = true 
                        end
                    else
                        if myIsland and myIsland ~= mobIsland and mobIsland ~= "Eventos (Timed Bosses)" then
                            SmartIslandTeleport(mobIsland)
                            attacking = true
                        else
                            attacking = executeAttackLogic(getValidTarget(questData.Type or "Mob", questData.Target))
                        end
                    end
                end
            end
        end

        if not attacking and not HubConfig.AutoFarmMaxLevel and not HubConfig.AutoQuest then
            if HubConfig.AutoDummy then attacking = executeAttackLogic(getValidTarget("Dummy", "")) end
            if not attacking and HubConfig.AutoBoss and HubConfig.SelectedBoss ~= "Nenhum" then 
                local targetIsland = getIslandByTarget("Boss", HubConfig.SelectedBoss)
                if myIsland and targetIsland and targetIsland ~= "Eventos (Timed Bosses)" and myIsland ~= targetIsland then
                    SmartIslandTeleport(targetIsland); attacking = true
                else
                    attacking = executeAttackLogic(getValidTarget("Boss", HubConfig.SelectedBoss)) 
                end
            end
            if not attacking and HubConfig.AutoFarm and HubConfig.SelectedMob ~= "Nenhum" then 
                local targetIsland = getIslandByTarget("Mob", HubConfig.SelectedMob)
                if myIsland and targetIsland and myIsland ~= targetIsland then
                    SmartIslandTeleport(targetIsland); attacking = true
                else
                    attacking = executeAttackLogic(getValidTarget("Mob", HubConfig.SelectedMob)) 
                end
            end
        end
        if not attacking then 
            getgenv().FarmTarget = nil
            pcall(function() unfreezeCharacter(LP.Character) end) 
        end
    end
end)

-- Spam de Combate
task.spawn(function()
    while getgenv().isRunning and task.wait(0.1) do
        local ft = getgenv().FarmTarget
        if ft and ft:FindFirstChild("Humanoid") and ft.Humanoid.Health > 0 then
            pcall(function()
                if CombatRemote then CombatRemote:FireServer() end
                if AbilityRemote then for i = 1, 4 do AbilityRemote:FireServer(i) end end
            end)
        end
    end
end)

-- Coleta Mapa Tradicional
task.spawn(function()
    while getgenv().isRunning and task.wait(1) do
        pcall(function()
            if not (HubConfig.AutoCollect.Fruits or HubConfig.AutoCollect.Hogyoku or HubConfig.AutoCollect.Puzzles or HubConfig.AutoCollect.Chests) then return end
            for _, obj in pairs(Workspace:GetDescendants()) do
                local name = string.lower(obj.Name)
                local isFruit = HubConfig.AutoCollect.Fruits and (name:find("fruit") or name:find("fruta")) and not name:find("dealer") and not name:find("npc")
                local isHogyoku = HubConfig.AutoCollect.Hogyoku and name:find("hogyoku")
                local isPuzzle = HubConfig.AutoCollect.Puzzles and (name:find("puzzlepiece") or name:find("puzzle"))
                local isChest = HubConfig.AutoCollect.Chests and (name:find("box") or name:find("chest"))
                
                if isFruit or isHogyoku or isPuzzle or isChest then
                    local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true) or (obj.Parent and obj.Parent:FindFirstChildWhichIsA("ProximityPrompt", true))
                    local clicker = obj:FindFirstChildWhichIsA("ClickDetector", true)
                    if prompt or clicker then
                        if prompt and not isSafePrompt(prompt) then continue end
                        local tween = SafeTeleport(obj, 1.5)
                        if tween then
                            tween.Completed:Wait(); task.wait(0.3)
                            if prompt and fireproximityprompt then fireproximityprompt(prompt) end
                            if clicker and fireclickdetector then fireclickdetector(clicker) end
                        end
                    end
                end
            end
        end)
    end
end)

-- Group Reward
task.spawn(function()
    while getgenv().isRunning and task.wait(5) do
        if HubConfig.AutoGroupReward then
            pcall(function()
                local serviceFolder = Workspace:FindFirstChild("ServiceNPCs")
                local groupNpc = serviceFolder and serviceFolder:FindFirstChild("GroupRewardNPC")
                if groupNpc then
                    local prompt = groupNpc:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt and fireproximityprompt then
                        local tween = SafeTeleport(groupNpc, 3)
                        if tween then tween.Completed:Wait() task.wait(0.5) fireproximityprompt(prompt) end
                    end
                end
            end)
        end
    end
end)

-- Auto Stats
task.spawn(function()
    while getgenv().isRunning and task.wait(0.5) do
        if HubConfig.AutoStats then
            pcall(function()
                local data = LP:FindFirstChild("Data")
                if data and data:FindFirstChild("StatPoints") and data.StatPoints.Value > 0 and AllocateStatRemote then
                    local availablePts = data.StatPoints.Value
                    local selectedCount = #HubConfig.SelectedStats
                    if selectedCount > 0 then
                        local basePoints = math.floor(availablePts / selectedCount)
                        local remainder = availablePts % selectedCount
                        for i, stat in ipairs(HubConfig.SelectedStats) do
                            local pointsToAllocate = basePoints
                            if i <= remainder then pointsToAllocate = pointsToAllocate + 1 end
                            if pointsToAllocate > 0 then AllocateStatRemote:FireServer(stat, pointsToAllocate) end
                        end
                    end
                end
            end)
        end
    end
end)

-- Auto Reroll & Baús Inventário
task.spawn(function()
    while getgenv().isRunning and task.wait(1.5) do
        pcall(function()
            if UseItemRemote then
                if HubConfig.AutoReroll.Race then
                    local currentRace = LP:GetAttribute("CurrentRace")
                    if currentRace and currentRace ~= HubConfig.AutoReroll.TargetRace then UseItemRemote:FireServer("Use", "Race Reroll", 1, false) else HubConfig.AutoReroll.Race = false end
                end
                if HubConfig.AutoReroll.Clan then
                    local currentClan = LP:GetAttribute("CurrentClan")
                    if currentClan and currentClan ~= HubConfig.AutoReroll.TargetClan then UseItemRemote:FireServer("Use", "Clan Reroll", 1, false) else HubConfig.AutoReroll.Clan = false end
                end
                if HubConfig.AutoOpenChests.Common then UseItemRemote:FireServer("Use", "Common Chest", 1, false) task.wait(0.2) end
                if HubConfig.AutoOpenChests.Rare then UseItemRemote:FireServer("Use", "Rare Chest", 1, false) task.wait(0.2) end
                if HubConfig.AutoOpenChests.Epic then UseItemRemote:FireServer("Use", "Epic Chest", 1, false) task.wait(0.2) end
                if HubConfig.AutoOpenChests.Mythical then UseItemRemote:FireServer("Use", "Mythical Chest", 1, false) task.wait(0.2) end
            end
            if HubConfig.AutoTrait and TraitRerollRemote then TraitRerollRemote:FireServer() end
            if HubConfig.AutoStatReroll and RerollSingleStatRemote then RerollSingleStatRemote:InvokeServer(HubConfig.SelectedStatToReroll) end
        end)
    end
end)

-- Super Velocidade e Hacks Nativos
table.insert(scriptConnections, RunService.Heartbeat:Connect(function()
    if HubConfig.SuperSpeed then
        local char = LP.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if hum and hum.MoveDirection.Magnitude > 0 then char:TranslateBy(hum.MoveDirection * HubConfig.SpeedMultiplier) end
    end
    if HubConfig.HacksNativos.PuloExtra then pcall(function() LP:SetAttribute("RaceExtraJumps", 5) end) end
end))

table.insert(scriptConnections, UserInputService.JumpRequest:Connect(function()
    if HubConfig.InfJump then
        local hum = LP.Character and LP.Character:FindFirstChild("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))
