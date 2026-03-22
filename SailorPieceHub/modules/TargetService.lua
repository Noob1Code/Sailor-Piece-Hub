-- =========================================================================
-- 🎯 TargetService
-- Responsável por rastrear, validar e armazenar em cache o alvo atual.
-- Reduz a necessidade de varrer o Workspace (otimização de performance).
-- =========================================================================

local GameServices = require(script.Parent.Parent.core.GameServices)

local TargetService = {}
TargetService.__index = TargetService

function TargetService.new()
    local self = setmetatable({
        _currentTarget = nil
    }, TargetService)
    return self
end

-- =========================================================================
-- MÉTODOS DE CONTROLE DE ESTADO
-- =========================================================================

-- Valida se um modelo ainda é um alvo atacável (está vivo e no mapa)
function TargetService:_isValid(target)
    if not target or not target.Parent then return false end
    
    local hum = target:FindFirstChild("Humanoid")
    local hrp = target:FindFirstChild("HumanoidRootPart")
    
    return (hum and hrp and hum.Health > 0)
end

-- Retorna o alvo atual. Se ele morreu ou sumiu, limpa o cache e retorna nil.
function TargetService:GetTarget()
    if self:_isValid(self._currentTarget) then
        return self._currentTarget
    else
        self._currentTarget = nil
        return nil
    end
end

-- Define um novo alvo manualmente
function TargetService:SetTarget(target)
    if self:_isValid(target) then
        self._currentTarget = target
    end
end

-- Limpa o alvo atual
function TargetService:ClearTarget()
    self._currentTarget = nil
end

-- =========================================================================
-- MÉTODOS DE BUSCA (Queries)
-- =========================================================================

-- Pega a posição do jogador de forma segura para calcular distâncias
function TargetService:_getMyPosition()
    local char = GameServices.LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    return hrp and hrp.Position or Vector3.zero
end

-- Encontra o mob mais próximo pelo nome (ou "Todos")
function TargetService:FindNearestMob(mobName)
    -- Se o alvo atual ainda é válido e é o mob que queremos, mantém ele (Cache Hit)
    if self:GetTarget() then
        local currentNameBase = self._currentTarget.Name:gsub("%d+", "")
        if mobName == "Todos" or currentNameBase == mobName then
            return self._currentTarget
        end
    end

    local npcsFolder = GameServices.Workspace:FindFirstChild("NPCs")
    if not npcsFolder then return nil end

    local myPos = self:_getMyPosition()
    local closestMob = nil
    local minDist = math.huge

    for _, npc in pairs(npcsFolder:GetChildren()) do
        if self:_isValid(npc) and not npc:GetAttribute("IsTrainingDummy") then
            local isBoss = npc.Name:lower():find("boss") or npc:GetAttribute("Boss")
            
            if not isBoss then
                local baseName = npc.Name:gsub("%d+", "")
                if mobName == "Todos" or baseName == mobName then
                    local dist = (myPos - npc.HumanoidRootPart.Position).Magnitude
                    if dist < minDist then
                        minDist = dist
                        closestMob = npc
                    end
                end
            end
        end
    end

    self._currentTarget = closestMob
    return closestMob
end

-- Encontra o Boss mais próximo pelo nome
function TargetService:FindNearestBoss(bossName)
    if not bossName or bossName == "Nenhum" then return nil end

    -- Verifica o cache primeiro
    if self:GetTarget() and self._currentTarget.Name:find(bossName) then
        return self._currentTarget
    end

    local myPos = self:_getMyPosition()
    local closestBoss = nil
    local minDist = math.huge

    -- Procura nos locais de spawn comuns
    for _, obj in pairs(GameServices.Workspace:GetChildren()) do
        if obj.Name:find("BossSpawn_") or obj.Name:find("TimedBoss") or obj.Name == "NPCs" then
            for _, boss in pairs(obj:GetChildren()) do
                if self:_isValid(boss) then
                    local isRecognizedBoss = boss:GetAttribute("Boss") or boss:GetAttribute("_IsTimedBoss") or boss.Name:lower():find("boss")
                    
                    if isRecognizedBoss and boss.Name:find(bossName) then
                        local dist = (myPos - boss.HumanoidRootPart.Position).Magnitude
                        if dist < minDist then
                            minDist = dist
                            closestBoss = boss
                        end
                    end
                end
            end
        end
    end

    self._currentTarget = closestBoss
    return closestBoss
end

return TargetService
