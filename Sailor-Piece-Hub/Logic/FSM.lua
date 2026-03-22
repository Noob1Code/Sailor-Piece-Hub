-- =====================================================================
-- 🧠 LOGIC: FSM.lua (Máquina de Estados Finita)
-- =====================================================================
-- Elimina Race Conditions garantindo que o bot faça apenas UMA
-- ação principal por vez (Busca -> Navegação -> Combate/Coleta).
-- =====================================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer

local FSM = {}
FSM.__index = FSM

function FSM.new(TargetManager, Config, CombatService, ItemCache)
    local self = setmetatable({}, FSM)
    
    self.TargetManager = TargetManager
    self.Config = Config
    self.CombatService = CombatService
    self.ItemCache = ItemCache
    
    self.State = "IDLE"
    
    -- Timers para tarefas secundárias (Background tasks)
    self.LastBackgroundTick = 0
    
    return self
end

-- ==========================================
-- 🔄 MOTOR PRINCIPAL (Chamado via Heartbeat)
-- ==========================================

function FSM:Update(deltaTime)
    -- Tarefas que não afetam a movimentação (ex: Upar Status)
    self:HandleBackgroundTasks()

    -- Máquina de Estados Principal
    if self.State == "IDLE" then
        self:State_IDLE()
    elseif self.State == "SEARCHING" then
        self:State_SEARCHING()
    elseif self.State == "NAVIGATING" then
        self:State_NAVIGATING()
    elseif self.State == "ATTACKING" then
        self:State_ATTACKING()
    elseif self.State == "COLLECTING" then
        self:State_COLLECTING()
    end
end

-- ==========================================
-- 🚥 ESTADOS DA MÁQUINA
-- ==========================================

function FSM:State_IDLE()
    -- Se qualquer modo de farm/coleta estiver ligado, sai da inércia
    if self.Config.AutoFarm or self.Config.AutoBoss or self.Config.AutoQuest or 
       self.Config.AutoCollect.Fruits or self.Config.AutoCollect.Chests or self.Config.FruitSniper then
        self.State = "SEARCHING"
    end
    
    -- Se não tem nada ligado, garante que o personagem está descongelado
    self.CombatService:SetCharacterFrozen(false)
end

function FSM:State_SEARCHING()
    -- 1. PRIORIDADE MÁXIMA: Coleta de Itens (Sniper/AutoCollect)
    -- Usa o ItemCache (O(1)) para achar itens no mapa imediatamente
    if self.Config.FruitSniper or self.Config.AutoCollect.Fruits then
        local fruits = self.ItemCache:GetItems("Fruits")
        if #fruits > 0 then
            self.TargetManager:SetInteractionTarget(fruits[1].Instance)
            self.State = "NAVIGATING"
            return
        end
    end
    
    if self.Config.AutoCollect.Chests then
        local chests = self.ItemCache:GetItems("Chests")
        if #chests > 0 then
            self.TargetManager:SetInteractionTarget(chests[1].Instance)
            self.State = "NAVIGATING"
            return
        end
    end

    -- 2. PRIORIDADE ALTA: Auto Boss e Auto Summon
    if self.Config.AutoBoss and #self.Config.SelectedBosses > 0 then
        local boss = self:FindMobByList(self.Config.SelectedBosses, true)
        if boss then
            self.TargetManager:SetTarget(boss)
            self.State = "NAVIGATING"
            return
        end
    end

    -- 3. PRIORIDADE MÉDIA: Auto Quest / Auto Farm Mob
    if self.Config.AutoFarm and self.Config.SelectedMob ~= "Nenhum" then
        local mob = self:FindMobByList({self.Config.SelectedMob}, false)
        if mob then
            self.TargetManager:SetTarget(mob)
            self.State = "NAVIGATING"
            return
        end
    end
    
    -- Se não achou NADA, volta a descansar
    self.State = "IDLE"
end

function FSM:State_NAVIGATING()
    local combatTarget = self.TargetManager:GetTarget()
    local interactTarget = self.TargetManager:GetInteractionTarget()
    
    -- Se o alvo sumiu ou morreu enquanto voávamos, volta a procurar
    if not combatTarget and not interactTarget then
        self.State = "SEARCHING"
        return
    end
    
    if combatTarget then
        -- MoveToTarget retorna TRUE se chegou na distância de ataque
        local isCloseEnough = self.CombatService:MoveToTarget(combatTarget)
        if isCloseEnough then
            self.State = "ATTACKING"
        end
        
    elseif interactTarget then
        -- Se for um item/NPC pacífico, chega bem perto (Distância 1.5)
        local isCloseEnough = self.CombatService:MoveToTarget(interactTarget, 1.5)
        if isCloseEnough then
            self.State = "COLLECTING"
        end
    end
end

function FSM:State_ATTACKING()
    local combatTarget = self.TargetManager:GetTarget()
    
    -- Valida se o alvo ainda está vivo e na memória
    if not combatTarget then
        self.State = "SEARCHING"
        return
    end
    
    -- Continua orbitando/mirando
    local isStillClose = self.CombatService:MoveToTarget(combatTarget)
    if not isStillClose then
        -- Se o alvo foi arremessado longe, volta a navegar
        self.State = "NAVIGATING"
        return
    end
    
    -- Dispara o motor de combate (Rate-Limited)
    self.CombatService:ExecuteAttack(combatTarget)
end

function FSM:State_COLLECTING()
    local item = self.TargetManager:GetInteractionTarget()
    
    if not item then
        self.State = "SEARCHING"
        return
    end
    
    -- Mantém o boneco colado no item
    self.CombatService:MoveToTarget(item, 1.5)
    
    -- Tenta pegar o item
    local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
    local clicker = item:FindFirstChildWhichIsA("ClickDetector", true)
    
    if prompt and fireproximityprompt then
        fireproximityprompt(prompt)
    elseif clicker and fireclickdetector then
        fireclickdetector(clicker)
    end
    
    -- Aguarda o jogo deletar o item, o TargetManager vai limpar a variável 
    -- automaticamente via AncestryChanged e o próximo frame voltará pra SEARCHING.
end

-- ==========================================
-- 🔍 FUNÇÕES AUXILIARES DE BUSCA
-- ==========================================

-- Função otimizada para buscar Mobs ou Bosses na pasta de NPCs do jogo
function FSM:FindMobByList(nameList, isBossCheck)
    local npcsFolder = Workspace:FindFirstChild("NPCs")
    if not npcsFolder then return nil end
    
    local myPos = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") 
                  and LP.Character.HumanoidRootPart.Position or Vector3.zero
                  
    local closestTarget = nil
    local minDist = math.huge
    
    for _, npc in ipairs(npcsFolder:GetChildren()) do
        local hum = npc:FindFirstChild("Humanoid")
        local hrp = npc:FindFirstChild("HumanoidRootPart")
        
        if hum and hum.Health > 0 and hrp then
            local npcName = npc.Name:gsub("%d+", "") -- Tira números do nome
            
            for _, targetName in ipairs(nameList) do
                if targetName == "Todos" or npcName:find(targetName) then
                    local dist = (myPos - hrp.Position).Magnitude
                    if dist < minDist then
                        minDist = dist
                        closestTarget = npc
                    end
                end
            end
        end
    end
    
    return closestTarget
end

-- ==========================================
-- ⚙️ TAREFAS DE BACKGROUND (Não interferem no voo)
-- ==========================================

function FSM:HandleBackgroundTasks()
    local now = tick()
    -- Roda a cada 1 segundo (Economiza CPU)
    if now - self.LastBackgroundTick < 1 then return end
    self.LastBackgroundTick = now
    
    -- Exemplo: Auto Status (Igual você tinha, mas agora seguro)
    if self.Config.AutoStats then
        local data = LP:FindFirstChild("Data")
        if data and data:FindFirstChild("StatPoints") and data.StatPoints.Value > 0 then
            local allocateRemote = game:GetService("ReplicatedStorage"):FindFirstChild("AllocateStat", true)
            if allocateRemote and #self.Config.SelectedStats > 0 then
                local points = math.floor(data.StatPoints.Value / #self.Config.SelectedStats)
                if points > 0 then
                    for _, stat in ipairs(self.Config.SelectedStats) do
                        allocateRemote:FireServer(stat, points)
                    end
                end
            end
        end
    end
    
    -- Adicionar AutoReroll, Baús do inventário, etc, aqui.
end

return FSM
