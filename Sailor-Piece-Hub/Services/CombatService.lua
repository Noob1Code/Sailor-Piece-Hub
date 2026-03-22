-- =====================================================================
-- ⚔️ SERVICES: CombatService.lua (Motor de Combate e Movimentação)
-- =====================================================================
-- Gerencia os cálculos de posição (Tween, Órbita), equipa armas 
-- e dispara remotes com proteção Anti-Cheat (Rate Limiting).
-- =====================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer

local CombatService = {}
CombatService.__index = CombatService

function CombatService.new(Constants, Config)
    local self = setmetatable({}, CombatService)
    
    self.Constants = Constants
    self.Config = Config
    self.OrbitAngle = 0
    
    -- Controle de Disparos para burlar Anti-Cheat (Rate Limiting)
    self.LastAttackTime = 0
    self.AttackCooldown = 0.2 -- Dispara no máximo 5 vezes por segundo (seguro)
    
    -- Cache dos Remotes (Evita usar FindFirstChild todo frame)
    self.Remotes = {
        Combat = nil,
        Ability = nil
    }
    
    self:LoadRemotes()
    
    return self
end

-- ==========================================
-- 📡 INICIALIZAÇÃO DE REDE (REMOTES)
-- ==========================================

function CombatService:LoadRemotes()
    pcall(function()
        self.Remotes.Combat = ReplicatedStorage:WaitForChild("CombatSystem"):WaitForChild("Remotes"):WaitForChild("RequestHit")
        self.Remotes.Ability = ReplicatedStorage:WaitForChild("AbilitySystem"):WaitForChild("Remotes"):WaitForChild("RequestAbility")
    end)
end

-- ==========================================
-- 🏃 MOVIMENTAÇÃO E FÍSICA
-- ==========================================

function CombatService:SetCharacterFrozen(isFrozen)
    local char = LP.Character
    if not char then return end
    
    local hum = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    
    if hum and hrp then
        if isFrozen then
            hrp.Velocity = Vector3.zero
            hum.PlatformStand = true -- Desativa física de colisão/queda
        else
            hum.PlatformStand = false
        end
    end
end

-- Retorna TRUE se estiver perto o suficiente para atacar, FALSE se ainda estiver viajando
function CombatService:MoveToTarget(targetInstance, customDistance)
    local char = LP.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
    
    local hrp = char.HumanoidRootPart
    local targetHrp = targetInstance:FindFirstChild("HumanoidRootPart")
    
    if not targetHrp then return false end

    -- Congela o personagem para o voo ser perfeito
    self:SetCharacterFrozen(true)
    
    local distanceTarget = customDistance or self.Config.Distance
    local pos = self:CalculateAttackPosition(targetInstance, targetHrp, distanceTarget)
    
    -- Mira sempre para o inimigo
    local targetCFrame = CFrame.new(pos, targetHrp.Position)
    local distance = (hrp.Position - pos).Magnitude
    
    -- Distância de segurança (se bugou e foi pra muito longe)
    if distance > 1000 then
        return false 
    end
    
    -- Se estiver longe, usa Tween para voar suavemente
    if distance > 15 then
        local tempo = distance / math.max(self.Config.TweenSpeed, 50)
        local tween = TweenService:Create(hrp, TweenInfo.new(tempo, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
        tween:Play()
        return false
    else
        -- Se estiver perto, teleporta instantaneamente e trava a mira
        hrp.CFrame = targetCFrame
        hrp.Velocity = Vector3.zero
        return true
    end
end

-- Inteligência de Posicionamento
function CombatService:CalculateAttackPosition(targetInstance, targetHrp, distance)
    local positionType = self.Config.AttackPosition
    
    -- Proteção contra Bosses que dão instakill em área no chão
    local isLethal = targetInstance:GetAttribute("Damage") and targetInstance:GetAttribute("Damage") > 100000
    if isLethal and positionType == "Abaixo" then 
        positionType = "Acima" 
    end

    if positionType == "Orbital" then
        self.OrbitAngle = self.OrbitAngle + math.rad(15)
        return targetHrp.Position + Vector3.new(math.cos(self.OrbitAngle) * distance, 5, math.sin(self.OrbitAngle) * distance)
    elseif positionType == "Atrás" then 
        return targetHrp.Position - (targetHrp.CFrame.LookVector * distance)
    elseif positionType == "Abaixo" then 
        return targetHrp.Position + Vector3.new(0, -distance, 0)
    else 
        -- Acima (Padrão e mais seguro)
        return targetHrp.Position + Vector3.new(0, distance, 0) 
    end
end

-- ==========================================
-- ⚔️ LÓGICA DE ATAQUE
-- ==========================================

function CombatService:EquipWeapon()
    local char = LP.Character
    local backpack = LP:FindFirstChild("Backpack")
    
    if not char or not backpack then return end

    if self.Config.SelectedWeapon == "Nenhuma" then
        -- Pega a primeira arma que achar
        for _, tool in ipairs(backpack:GetChildren()) do 
            if tool:IsA("Tool") then 
                tool.Parent = char 
                break 
            end 
        end
    else
        -- Pega a arma específica
        local specificWeapon = backpack:FindFirstChild(self.Config.SelectedWeapon)
        if specificWeapon and specificWeapon:IsA("Tool") then 
            specificWeapon.Parent = char 
        end
    end
end

function CombatService:ExecuteAttack(targetInstance)
    self:EquipWeapon()
    
    -- RATE LIMITING: Bloqueia ataques muito rápidos que dão kick por exploit
    local currentTime = tick()
    if currentTime - self.LastAttackTime < self.AttackCooldown then
        return -- Sai da função sem atacar se não passou o tempo
    end
    
    self.LastAttackTime = currentTime
    
    pcall(function()
        if self.Remotes.Combat then 
            self.Remotes.Combat:FireServer() 
        end
        
        -- Dispara as habilidades (Z, X, C, V)
        if self.Remotes.Ability then 
            for i = 1, 4 do 
                self.Remotes.Ability:FireServer(i) 
            end 
        end
    end)
end

return CombatService
