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

getgenv().CurrentIslandCache = "Starter"

-- =========================================================================
-- 🧠 TICKER LENTO: CÉREBRO (DECISÕES PESADAS - Roda a cada 1 segundo)
-- =========================================================================
task.spawn(function()
    while getgenv().isRunning and task.wait(1) do
        getgenv().CurrentIslandCache = getCurrentIsland()
        local myIsland = getgenv().CurrentIslandCache
        local hasAction = false

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
                            hasAction = true 
                        else
                            local npc = Workspace:FindFirstChild("ServiceNPCs") and Workspace.ServiceNPCs:FindFirstChild(questData.NPC)
                            getgenv().InteractionTarget = npc
                            getgenv().FarmTarget = nil
                            hasAction = true 
                        end
                    else
                        if myIsland and myIsland ~= mobIsland and mobIsland ~= "Eventos (Timed Bosses)" then
                            SmartIslandTeleport(mobIsland)
                            hasAction = true
                        else
                            getgenv().InteractionTarget = nil
                            getgenv().FarmTarget = getValidTarget(questData.Type or "Mob", questData.Target)
                            hasAction = true
                        end
                    end
                end
            end
        end

        if not hasAction and not HubConfig.AutoFarmMaxLevel and not HubConfig.AutoQuest then
            if HubConfig.AutoDummy then 
                getgenv().FarmTarget = getValidTarget("Dummy", "")
                hasAction = true 
            end
            
            if not hasAction and HubConfig.AutoBoss and #HubConfig.SelectedBosses > 0 then 
                local bossDeAcao = nil
                local alvoDoBoss = nil
            
                -- 1. Varre a fila inteira procurando o primeiro boss que esteja VIVO e RENDERIZADO no mapa
                for _, bossName in ipairs(HubConfig.SelectedBosses) do
                    local bTarget = getValidTarget("Boss", bossName)
                    if bTarget then
                        bossDeAcao = bossName
                        alvoDoBoss = bTarget
                        break -- Achou um vivo, para de procurar
                    end
                end
            
                -- 2. Se achou um boss vivo, decide se precisa teleportar ou atacar
                if bossDeAcao and alvoDoBoss then
                    local targetIsland = getIslandByTarget("Boss", bossDeAcao)
                    
                    -- Confere se a nossa ilha atual é diferente da ilha do Boss
                    if myIsland and targetIsland and targetIsland ~= "Eventos (Timed Bosses)" and myIsland ~= targetIsland then
                        -- Vai teleportar! (A função SmartIslandTeleport já chama o AutoSaveSpawn internamente)
                        SmartIslandTeleport(targetIsland) 
                        hasAction = true
                    else
                        -- Já estamos na ilha certa (ou o teleporte já acabou). Vai para cima!
                        getgenv().FarmTarget = alvoDoBoss
                        hasAction = true
                    end
                end
            end
            
            if not hasAction and HubConfig.AutoFarm and HubConfig.SelectedMob ~= "Nenhum" then 
                local targetIsland = getIslandByTarget("Mob", HubConfig.SelectedMob)
                if myIsland and targetIsland and myIsland ~= targetIsland then
                    SmartIslandTeleport(targetIsland); hasAction = true
                else
                    getgenv().FarmTarget = getValidTarget("Mob", HubConfig.SelectedMob)
                    hasAction = true
                end
            end
        end

        if not hasAction then 
            getgenv().FarmTarget = nil
            getgenv().InteractionTarget = nil
        end
    end
end)

-- =========================================================================
-- ⚡ TICKER RÁPIDO: MÚSCULOS (APENAS AÇÃO E VOO - Roda a cada 0.05 seg)
-- =========================================================================
task.spawn(function()
    while getgenv().isRunning and task.wait(0.05) do
        local attacking = false

        if getgenv().InteractionTarget then
            local npc = getgenv().InteractionTarget
            if npc and npc:FindFirstChild("HumanoidRootPart") then
                local tween = SafeTeleport(npc, 1.5)
                if tween then
                    tween.Completed:Wait()
                    task.wait(0.4)
                    local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt and fireproximityprompt then fireproximityprompt(prompt) end
                    task.wait(1) 
                    getgenv().InteractionTarget = nil
                end
            end
            attacking = true

        elseif getgenv().FarmTarget then
            attacking = executeAttackLogic(getgenv().FarmTarget)
        end

        if not attacking then 
            pcall(function() unfreezeCharacter(LP.Character) end) 
        end
    end
end)

-- SPAM DE COMBATE
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

-- COLETA MAPA TRADICIONAL
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

-- GROUP REWARD
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

-- AUTO STATS
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

-- 📦 AUTO REROLL & BAÚS INVENTÁRIO (ATUALIZADO)
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
                
                -- Usa a variável configurada na interface (Padrão: 1)
                local amount = HubConfig.ChestOpenAmount or 1
                
                if HubConfig.AutoOpenChests.Common then UseItemRemote:FireServer("Use", "Common Chest", amount, false) task.wait(0.2) end
                if HubConfig.AutoOpenChests.Rare then UseItemRemote:FireServer("Use", "Rare Chest", amount, false) task.wait(0.2) end
                if HubConfig.AutoOpenChests.Epic then UseItemRemote:FireServer("Use", "Epic Chest", amount, false) task.wait(0.2) end
                if HubConfig.AutoOpenChests.Legendary then UseItemRemote:FireServer("Use", "Legendary Chest", amount, false) task.wait(0.2) end
                if HubConfig.AutoOpenChests.Mythical then UseItemRemote:FireServer("Use", "Mythical Chest", amount, false) task.wait(0.2) end
            end
            if HubConfig.AutoTrait and TraitRerollRemote then TraitRerollRemote:FireServer() end
            if HubConfig.AutoStatReroll and RerollSingleStatRemote then RerollSingleStatRemote:InvokeServer(HubConfig.SelectedStatToReroll) end
        end)
    end
end)

-- SUPER VELOCIDADE E HACKS NATIVOS
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
