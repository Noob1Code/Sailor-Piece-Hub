-- =========================================================================
-- ⚔️ CombatService
-- Responsável puramente pela execução de ações de combate e movimentação.
-- Desacoplado da lógica de decisão (não escolhe alvos, apenas os ataca).
-- =========================================================================

local GameServices = require(script.Parent.Parent.core.GameServices)
local Remotes = require(script.Parent.Parent.core.Remotes)

local CombatService = {}
CombatService.__index = CombatService

-- Construtor injetando o StateManager para ler as configurações de combate
function CombatService.new(stateManager)
    local self = setmetatable({
        _state = stateManager,
        _orbitAngle = 0,
        _currentTween = nil
    }, CombatService)
    return self
end

-- =========================================================================
-- FUNÇÕES UTILITÁRIAS INTERNAS
-- =========================================================================

-- Congela o personagem para evitar que ele caia enquanto ataca no ar
function CombatService:_freezeCharacter(char)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if hrp and hum then 
        hrp.Velocity = Vector3.zero 
        hum.PlatformStand = true 
    end
end

-- Equipa a arma selecionada no StateManager
function CombatService:_equipWeapon()
    local char = GameServices.LocalPlayer.Character
    local backpack = GameServices.LocalPlayer:FindFirstChild("Backpack")
    local selectedWeapon = self._state:Get("SelectedWeapon")

    if not char or not backpack then return end

    if selectedWeapon == "Nenhuma" or not selectedWeapon then
        -- Equipa a primeira ferramenta que achar
        for _, tool in pairs(backpack:GetChildren()) do 
            if tool:IsA("Tool") then tool.Parent = char; break end 
        end
    else
        -- Equipa a ferramenta específica
        local specificWeapon = backpack:FindFirstChild(selectedWeapon)
        if specificWeapon and specificWeapon:IsA("Tool") then 
            specificWeapon.Parent = char 
        end
    end
end

-- =========================================================================
-- MÉTODOS PRINCIPAIS
-- =========================================================================

-- Executa o ataque (Spam de cliques e habilidades)
function CombatService:Attack(target)
    if not target or not target:FindFirstChild("Humanoid") then return false end
    if target.Humanoid.Health <= 0 then return false end

    self:_equipWeapon()

    -- Dispara o ataque básico
    if Remotes.CombatRemote then 
        Remotes.CombatRemote:FireServer() 
    end

    -- Dispara as habilidades (1 ao 4)
    if Remotes.AbilityRemote then 
        for i = 1, 4 do 
            Remotes.AbilityRemote:FireServer(i) 
        end 
    end

    return true
end

-- Movimento orbital ao redor do alvo
function CombatService:OrbitTarget(target, distance)
    local char = GameServices.LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local hrp = char.HumanoidRootPart
    local targetHrp = target:FindFirstChild("HumanoidRootPart")
    if not targetHrp then return end

    self:_freezeCharacter(char)

    -- Aumenta o ângulo para criar o giro (velocidade fixa ou ajustável)
    self._orbitAngle = self._orbitAngle + math.rad(15)
    
    -- Calcula a posição em círculo, levemente acima da cabeça para evitar ataques no chão
    local pos = targetHrp.Position + Vector3.new(
        math.cos(self._orbitAngle) * distance, 
        5, 
        math.sin(self._orbitAngle) * distance
    )

    -- CFrame.new(Posição, OlharPara) garante que sempre mire no alvo
    hrp.CFrame = CFrame.new(pos, targetHrp.Position)
    hrp.Velocity = Vector3.zero
end

-- Movimenta o jogador até a posição ideal de combate (Atrás, Acima, Abaixo, Orbital)
function CombatService:MoveTo(target)
    local char = GameServices.LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
    
    local hrp = char.HumanoidRootPart
    local targetHrp = target:FindFirstChild("HumanoidRootPart")
    if not targetHrp then return false end

    -- Lê configurações atuais do estado
    local distance = self._state:Get("Distance") or 5
    local tweenSpeed = self._state:Get("TweenSpeed") or 150
    local attackPos = self._state:Get("AttackPosition") or "Atrás"

    -- Se for Orbital, delega para a função específica
    if attackPos == "Orbital" then
        self:OrbitTarget(target, distance)
        return true
    end

    self:_freezeCharacter(char)

    -- Proteção contra instakill de Bosses muito fortes
    local forcedSafe = target:GetAttribute("Damage") and target:GetAttribute("Damage") > 100000
    if forcedSafe and attackPos == "Abaixo" then 
        attackPos = "Acima" 
    end

    local pos
    if attackPos == "Atrás" then 
        pos = targetHrp.Position - (targetHrp.CFrame.LookVector * distance)
    elseif attackPos == "Abaixo" then 
        pos = targetHrp.Position + Vector3.new(0, -distance, 0)
    else -- Acima
        pos = targetHrp.Position + Vector3.new(0, distance, 0) 
    end

    -- Cria o CFrame mirando no alvo
    local targetCFrame = CFrame.new(pos, targetHrp.Position)
    local distToPos = (hrp.Position - pos).Magnitude

    -- Se estiver muito longe, cancela para evitar banimentos/erros
    if distToPos > 1000 then
        return false 
    end

    -- Se estiver longe da posição ideal de ataque, usa TweenService
    if distToPos > 15 then
        local timeToArrive = distToPos / tweenSpeed
        local tweenInfo = TweenInfo.new(timeToArrive, Enum.EasingStyle.Linear)
        
        -- Evita criar dezenas de Tweens sobrepostos; cancela o anterior se existir
        if self._currentTween then self._currentTween:Cancel() end
        
        self._currentTween = GameServices.TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
        self._currentTween:Play()
    else
        -- Se já estiver perto (<= 15 studs), apenas "gruda" na posição (Lock-on)
        hrp.CFrame = targetCFrame
        hrp.Velocity = Vector3.zero
    end

    return true
end

return CombatService
