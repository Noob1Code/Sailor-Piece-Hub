-- =========================================================================
-- 🗺️ TeleportService
-- Gerencia as viagens entre ilhas, salvar spawn e banco de dados de Mobs/Bosses.
-- =========================================================================

local GameServices = Import("core/GameServices")
local Remotes = Import("core/Remotes")
local TweenUtil = Import("utils/TweenUtil")

local TeleportService = {}
TeleportService.__index = TeleportService

-- Banco de Dados de Ilhas EXATO do seu jogo original
local IslandData = {
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

function TeleportService.new()
    local self = setmetatable({
        _lastTeleport = 0,
        _isSavingSpawn = false -- Flag para evitar que o farm ataque enquanto salvamos o spawn
    }, TeleportService)
    return self
end

-- =========================================================================
-- BANCO DE DADOS (GETTERS)
-- =========================================================================

function TeleportService:GetIslands()
    local list = {}
    for island, _ in pairs(IslandData) do
        table.insert(list, island)
    end
    table.sort(list)
    return list
end

function TeleportService:GetMobsFromIsland(islandName)
    if IslandData[islandName] and IslandData[islandName].Mobs then
        if #IslandData[islandName].Mobs > 0 then
            return IslandData[islandName].Mobs
        end
    end
    return {"Nenhum"}
end

function TeleportService:GetIslandByMob(mobName)
    for island, data in pairs(IslandData) do
        if table.find(data.Mobs, mobName) then
            return island
        end
    end
    return nil
end

function TeleportService:GetIslandByBoss(bossName)
    for island, data in pairs(IslandData) do
        if table.find(data.Bosses, bossName) then
            return island
        end
    end
    return nil
end

-- =========================================================================
-- CONTROLE DE VIAGEM E SPAWN
-- =========================================================================

-- Diz aos outros serviços se o jogador está ocupado salvando o spawn
function TeleportService:IsSavingSpawn()
    return self._isSavingSpawn
end

function TeleportService:TeleportToIsland(islandName)
    if not islandName then return end
    
    if tick() - self._lastTeleport > 4 then
        if Remotes.TeleportRemote then
            Remotes.TeleportRemote:FireServer(islandName)
            self._lastTeleport = tick()
            print("🗺️ Viajando para a ilha: " .. islandName)
        end
    end
end

-- Lógica convertida do AutoSaveSpawn original (Assíncrona para não travar o Hub)
function TeleportService:SaveSpawn(tweenSpeed)
    if self._isSavingSpawn then return end

    local char = GameServices.LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = char.HumanoidRootPart
    local myPos = hrp.Position

    local closestPrompt = nil
    local targetPart = nil
    local minDist = math.huge

    -- Busca o cristal de spawn mais próximo (Baseado na sua lógica original)
    for _, obj in pairs(GameServices.Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local actionText = string.lower(obj.ActionText)
            local promptName = obj.Name
            
            -- Reconhece tanto o Checkpoint padrão do Roblox quanto os SpawnPointCrystals do seu jogo
            if promptName == "CheckpointPrompt" or actionText == "set spawn" or obj.Parent.Name:find("SpawnPointCrystal") then
                local part = obj.Parent
                if part and part:IsA("BasePart") then
                    local dist = (part.Position - myPos).Magnitude
                    if dist < minDist and dist < 800 then
                        minDist = dist
                        closestPrompt = obj
                        targetPart = part
                    end
                end
            end
        end
    end

    if closestPrompt and targetPart then
        self._isSavingSpawn = true
        print("🚩 Iniciando AutoSaveSpawn...")

        -- Voa até o cristal
        local targetPos = targetPart.Position + Vector3.new(0, 3, 0)
        local tween = TweenUtil.MoveToPosition(char, targetPos, tweenSpeed or 150)
        
        if tween then
            -- Quando a animação terminar, clica no botão (Tudo em background sem travar)
            tween.Completed:Connect(function()
                task.wait(0.2)
                if fireproximityprompt then 
                    fireproximityprompt(closestPrompt)
                    task.wait(0.2)
                    fireproximityprompt(closestPrompt)
                end
                print("✅ Spawn Salvo!")
                self._isSavingSpawn = false
            end)
        else
            -- Fallback se o Tween falhar
            hrp.CFrame = CFrame.new(targetPos)
            task.wait(0.5)
            if fireproximityprompt then 
                fireproximityprompt(closestPrompt)
                task.wait(0.2)
                fireproximityprompt(closestPrompt)
            end
            print("✅ Spawn Salvo (TP Direto)!")
            self._isSavingSpawn = false
        end
    else
        -- print("⚠️ Nenhum Cristal de Spawn encontrado num raio de 800 studs.")
    end
end

return TeleportService
