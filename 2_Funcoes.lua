-- IMPORTAÇÕES GLOBAIS
local LP = getgenv().LP
local TweenService = getgenv().TweenService
local Workspace = getgenv().Workspace
local HubConfig = getgenv().HubConfig
local IslandDataMap = getgenv().IslandDataMap
local QuestDataMap = getgenv().QuestDataMap
local TeleportMap = getgenv().TeleportMap
local TeleportRemote = getgenv().TeleportRemote

getgenv().isSafePrompt = function(prompt)
    if not prompt then return false end
    local text = string.lower(prompt.ActionText)
    if text:find("spin") or text:find("buy") or text:find("cost") or text:find("gems") or text:find("coins") or text:find("purchase") then return false end
    return true
end

getgenv().freezeCharacter = function(char)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if hrp and hum then hrp.Velocity = Vector3.zero; hum.PlatformStand = true end
end

getgenv().unfreezeCharacter = function(char)
    local hum = char and char:FindFirstChild("Humanoid")
    if hum then hum.PlatformStand = false end
end

getgenv().SafeTeleport = function(target, heightOffset)
    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    local targetPos
    if typeof(target) == "Vector3" then targetPos = target
    elseif typeof(target) == "Instance" then
        if target:IsA("Model") then targetPos = target.PrimaryPart and target.PrimaryPart.Position or (target:FindFirstChildWhichIsA("BasePart") and target:FindFirstChildWhichIsA("BasePart").Position)
        elseif target:IsA("BasePart") then targetPos = target.Position end
    end

    if targetPos then
        local distance = (hrp.Position - targetPos).Magnitude
        local tempo = distance / HubConfig.TweenSpeed
        if tempo < 0.1 then tempo = 0.1 end 
        local tween = TweenService:Create(hrp, TweenInfo.new(tempo, Enum.EasingStyle.Linear), {CFrame = CFrame.new(targetPos + Vector3.new(0, heightOffset or 0, 0))})
        tween:Play()
        return tween
    end
    return nil
end

getgenv().getIslandByTarget = function(typeStr, name)
    for island, data in pairs(IslandDataMap) do
        if typeStr == "Mob" then
            for _, mob in ipairs(data.Mobs) do if string.find(name, mob) or mob == name then return island end end
        elseif typeStr == "Boss" then
            for _, boss in ipairs(data.Bosses) do if boss == name then return island end end
        end
    end
    return nil
end

getgenv().getCurrentIsland = function()
    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = char.HumanoidRootPart.Position
    local closestIsland = nil
    local minDist = math.huge
    
    local npcsFolder = Workspace:FindFirstChild("NPCs")
    if npcsFolder then
        for _, npc in pairs(npcsFolder:GetChildren()) do
            local hrp = npc:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (myPos - hrp.Position).Magnitude
                if dist < minDist then
                    local isBoss = npc.Name:lower():find("boss") or npc:GetAttribute("Boss")
                    local baseName = npc.Name:gsub("%d+", "")
                    local island = getgenv().getIslandByTarget(isBoss and "Boss" or "Mob", baseName)
                    if island and island ~= "Eventos (Timed Bosses)" then minDist = dist; closestIsland = island end
                end
            end
        end
    end
    
    local serviceFolder = Workspace:FindFirstChild("ServiceNPCs")
    if serviceFolder then
        for _, npc in pairs(serviceFolder:GetChildren()) do
            local hrp = npc:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (myPos - hrp.Position).Magnitude
                if dist < minDist then
                    for island, quests in pairs(QuestDataMap) do
                        for _, q in ipairs(quests) do
                            if q.NPC == npc.Name then minDist = dist; closestIsland = island end
                        end
                    end
                end
            end
        end
    end
    return closestIsland
end

-- 🌟 NOVA FUNÇÃO: AUTO SAVE SPAWN INTELIGENTE 🌟
getgenv().AutoSaveSpawn = function()
    pcall(function()
        for _, obj in pairs(Workspace:GetDescendants()) do
            local name = string.lower(obj.Name)
            -- Procura qualquer coisa que lembre um NPC ou placa de Spawn
            if name:find("spawn") or name:find("setspawn") or name:find("checkpoint") then
                local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true) or (obj.Parent and obj.Parent:FindFirstChildWhichIsA("ProximityPrompt", true))
                if prompt then
                    local char = LP.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        local hrp = char.HumanoidRootPart
                        local oldCFrame = hrp.CFrame
                        local targetCFrame = obj:IsA("Model") and obj.PrimaryPart and obj.PrimaryPart.CFrame or (obj:IsA("BasePart") and obj.CFrame)
                        
                        if targetCFrame then
                            -- Dá um pulo instantâneo até o botão de spawn, salva e volta
                            hrp.CFrame = targetCFrame
                            task.wait(0.5)
                            if fireproximityprompt then fireproximityprompt(prompt) end
                            task.wait(0.5)
                            hrp.CFrame = oldCFrame
                            return true
                        end
                    end
                end
            end
        end
    end)
end

getgenv().lastTeleportTime = 0
getgenv().SmartIslandTeleport = function(islandName)
    if not islandName or islandName == "Eventos (Timed Bosses)" then return false end
    if tick() - getgenv().lastTeleportTime < 3 then return false end 
    local dest = TeleportMap[islandName] or islandName
    if TeleportRemote then
        getgenv().unfreezeCharacter(LP.Character)
        TeleportRemote:FireServer(dest)
        getgenv().lastTeleportTime = tick()
        getgenv().CurrentTarget = nil
        getgenv().FarmTarget = nil
        task.wait(2) -- Espera 2 segundos o mapa novo carregar
        getgenv().AutoSaveSpawn() -- Tenta salvar o spawn assim que chega na ilha!
        return true
    end
    return false
end

getgenv().getMobList = function(filter)
    local mobs = {"Nenhum", "Todos"}
    local seen = {}
    local npcsFolder = Workspace:FindFirstChild("NPCs")
    if npcsFolder then
        for _, npc in pairs(npcsFolder:GetChildren()) do
            if npc:FindFirstChild("Humanoid") and not npc:GetAttribute("IsTrainingDummy") then
                local baseName = npc.Name:gsub("%d+", "")
                if baseName ~= "" and not seen[baseName] and not baseName:lower():find("boss") then
                    local addToList = false
                    if filter == "Todas" or not filter then addToList = true else
                        local filterData = IslandDataMap[filter]
                        if filterData and filterData.Mobs then
                            for _, prefix in ipairs(filterData.Mobs) do if baseName:find(prefix) then addToList = true break end end
                        end
                    end
                    if addToList then seen[baseName] = true; table.insert(mobs, baseName) end
                end
            end
        end
    end
    return mobs
end

getgenv().getBossList = function(filter)
    local bosses = {"Nenhum"}
    if filter == "Todas" or not filter then
        local allBosses = {"ThiefBoss", "DesertBoss", "MonkeyBoss", "SnowBoss", "PandaMiniBoss", "GojoBoss", "SukunaBoss", "YujiBoss", "JinwooBoss", "AizenBoss", "YamatoBoss", "AlucardBoss", "MadokaBoss", "Rimuru"}
        for _, b in ipairs(allBosses) do table.insert(bosses, b) end
    else
        local filterData = IslandDataMap[filter]
        if filterData and filterData.Bosses then
            for _, b in ipairs(filterData.Bosses) do table.insert(bosses, b) end
        end
    end
    return bosses
end

getgenv().getQuestsForIsland = function(island)
    local quests = {}
    if QuestDataMap[island] then for _, q in ipairs(QuestDataMap[island]) do table.insert(quests, q.Name) end end
    if #quests == 0 then table.insert(quests, "Nenhuma Quest") end
    return quests
end

getgenv().getQuestDataByName = function(island, name)
    if QuestDataMap[island] then
        for _, q in ipairs(QuestDataMap[island]) do if q.Name == name then return q end end
    end
    return nil
end

getgenv().isQuestActive = function(questData)
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return false end
    for _, desc in ipairs(pg:GetDescendants()) do
        if desc:IsA("TextLabel") and desc.Name == "QuestRequirement" then
            if desc.Text:find("/") then
                local obj = desc
                local vis = true
                while obj and obj:IsA("GuiObject") do
                    if not obj.Visible then vis = false break end
                    obj = obj.Parent
                end
                if vis then
                    if not questData then return true end
                    local targetBase = questData.Target:gsub("Boss", ""):gsub("Mini", ""):lower()
                    local uiText = desc.Text:lower()
                    local titleText = ""
                    if desc.Parent then
                        for _, sibling in ipairs(desc.Parent:GetChildren()) do
                            if sibling:IsA("TextLabel") and sibling.Name ~= "QuestRequirement" then titleText = titleText .. " " .. sibling.Text:lower() end
                        end
                    end
                    if uiText:find(targetBase) or titleText:find(targetBase) then
                        local curr, max = desc.Text:match("(%d+)/(%d+)")
                        if curr and max and tonumber(curr) < tonumber(max) then return true end
                    end
                end
            end
        end
    end
    return false
end

getgenv().getValidTarget = function(typeStr, name)
    if name == "Nenhum" or not name then return nil end
    local CurrentTarget = getgenv().CurrentTarget
    if CurrentTarget and CurrentTarget.Parent and CurrentTarget:FindFirstChild("Humanoid") and CurrentTarget.Humanoid.Health > 0 and CurrentTarget:FindFirstChild("HumanoidRootPart") then
        local isStillValid = false
        if typeStr == "Dummy" and (CurrentTarget.Name == "TrainingDummy" or CurrentTarget:GetAttribute("IsTrainingDummy")) then isStillValid = true
        elseif typeStr == "Mob" then
            local isBoss = CurrentTarget.Name:lower():find("boss") or CurrentTarget:GetAttribute("Boss")
            if not isBoss then
                local baseName = CurrentTarget.Name:gsub("%d+", "")
                if name == "Todos" or baseName == name then isStillValid = true end
            end
        elseif typeStr == "Boss" then
            if CurrentTarget.Name:find(name) then isStillValid = true end
        end
        if isStillValid then return CurrentTarget end
    end

    local closest = nil; local minDist = math.huge; local char = LP.Character
    local myPos = char and char:FindFirstChild("HumanoidRootPart") and char.HumanoidRootPart.Position or Vector3.zero
    local npcsFolder = Workspace:FindFirstChild("NPCs")
    
    if typeStr == "Dummy" then
        if not npcsFolder then return nil end
        for _, npc in pairs(npcsFolder:GetChildren()) do if npc.Name == "TrainingDummy" or npc:GetAttribute("IsTrainingDummy") then return npc end end
    elseif typeStr == "Mob" then
        if not npcsFolder then return nil end
        for _, npc in pairs(npcsFolder:GetChildren()) do
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
    getgenv().CurrentTarget = closest
    return closest
end

getgenv().getWeaponList = function()
    local weapons = {"Nenhuma"}; local char = LP.Character; local backpack = LP:FindFirstChild("Backpack")
    if backpack then for _, tool in pairs(backpack:GetChildren()) do if tool:IsA("Tool") and not table.find(weapons, tool.Name) then table.insert(weapons, tool.Name) end end end
    if char then for _, tool in pairs(char:GetChildren()) do if tool:IsA("Tool") and not table.find(weapons, tool.Name) then table.insert(weapons, tool.Name) end end end
    return weapons
end

getgenv().equipWeapon = function()
    local char = LP.Character; if not char then return end
    local backpack = LP:FindFirstChild("Backpack"); if not backpack then return end
    if HubConfig.SelectedWeapon == "Nenhuma" then
        for _, tool in pairs(backpack:GetChildren()) do if tool:IsA("Tool") then tool.Parent = char break end end
    else
        local specificWeapon = backpack:FindFirstChild(HubConfig.SelectedWeapon)
        if specificWeapon and specificWeapon:IsA("Tool") then specificWeapon.Parent = char end
    end
end

getgenv().executeAttackLogic = function(target)
    if not target or not target:FindFirstChild("HumanoidRootPart") or not target:FindFirstChild("Humanoid") or target.Humanoid.Health <= 0 then 
        getgenv().FarmTarget = nil 
        return false 
    end
    
    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
    local hrp = char.HumanoidRootPart; local targetHrp = target.HumanoidRootPart
    
    getgenv().freezeCharacter(char)
    local forcedSafe = target:GetAttribute("Damage") and target:GetAttribute("Damage") > 100000
    local finalPos = HubConfig.AttackPosition
    if forcedSafe and finalPos == "Abaixo" then finalPos = "Acima" end
    
    local pos
    if finalPos == "Atrás" then pos = targetHrp.Position - (targetHrp.CFrame.LookVector * HubConfig.Distance)
    elseif finalPos == "Abaixo" then pos = targetHrp.Position + Vector3.new(0, -HubConfig.Distance, 0)
    else pos = targetHrp.Position + Vector3.new(0, HubConfig.Distance, 0) end
    
    local targetCFrame = CFrame.new(pos, targetHrp.Position)
    local distance = (hrp.Position - pos).Magnitude
    
    -- 🛡️ PROTEÇÃO ANTI-DISCONNECT: Cancela o voo se a distância for maior que 1000 studs
    if distance > 1000 then
        getgenv().FarmTarget = nil
        return false -- Ao retornar false, o Motor de Quest é forçado a reavaliar e usar o Portal!
    elseif distance > 15 then
        TweenService:Create(hrp, TweenInfo.new(distance / HubConfig.TweenSpeed, Enum.EasingStyle.Linear), {CFrame = targetCFrame}):Play()
        getgenv().FarmTarget = nil
    else
        hrp.CFrame = targetCFrame
        hrp.Velocity = Vector3.zero
        getgenv().equipWeapon()
        getgenv().FarmTarget = target
    end
    return true
end

getgenv().TeleportAndCollectFruit = function(child)
    if not HubConfig.FruitSniper then return end
    task.spawn(function()
        task.wait(0.1)
        if not child or not child.Parent then return end
        local lowerName = string.lower(child.Name)
        if (lowerName:find("fruit") or lowerName:find("fruta")) and not lowerName:find("dealer") and not lowerName:find("npc") and not child:FindFirstChild("Humanoid") then
            local prompt = child:FindFirstChildWhichIsA("ProximityPrompt", true) or (child.Parent and child.Parent:FindFirstChildWhichIsA("ProximityPrompt", true))
            local clicker = child:FindFirstChildWhichIsA("ClickDetector", true)
            if prompt or clicker then
                if prompt and not getgenv().isSafePrompt(prompt) then return end
                local pos = nil
                if child:IsA("BasePart") then pos = child.Position
                elseif child:IsA("Model") then
                    pos = child.PrimaryPart and child.PrimaryPart.Position
                    if not pos then local part = child:FindFirstChildWhichIsA("BasePart", true); if part then pos = part.Position end end
                end
                if pos then
                    local char = LP.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        char.HumanoidRootPart.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
                        task.wait(0.5)
                        if prompt and fireproximityprompt then fireproximityprompt(prompt) end
                        if clicker and fireclickdetector then fireclickdetector(clicker) end
                    end
                end
            end
        end
    end)
end
