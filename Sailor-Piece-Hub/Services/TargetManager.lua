-- =====================================================================
-- 🎯 SERVICES: TargetManager.lua (Gerenciador de Alvos e Memória)
-- =====================================================================
-- Responsável por manter a referência do alvo atual e limpá-la 
-- automaticamente (Garbage Collection) quando o NPC morre ou some.
-- =====================================================================

local TargetManager = {}
TargetManager.__index = TargetManager

-- Construtor da Classe
function TargetManager.new()
    local self = setmetatable({}, TargetManager)
    
    self.CurrentTarget = nil
    self.InteractionTarget = nil -- Para NPCs de Quest/Summon
    
    -- Guarda as conexões dos eventos para podermos desconectá-las depois
    self._targetConnection = nil
    self._interactionConnection = nil
    
    return self
end

-- ==========================================
-- ⚔️ ALVOS DE COMBATE (Mobs/Bosses)
-- ==========================================

-- Define um novo alvo de combate com proteção de memória
function TargetManager:SetTarget(targetInstance)
    -- 1. Se já havia um alvo antes, limpa o monitoramento dele
    if self._targetConnection then
        self._targetConnection:Disconnect()
        self._targetConnection = nil
    end

    self.CurrentTarget = targetInstance

    -- 2. Se o novo alvo for válido, inicia o monitoramento
    if targetInstance then
        -- AncestryChanged dispara no exato momento em que o objeto é movido ou destruído
        self._targetConnection = targetInstance.AncestryChanged:Connect(function(_, newParent)
            if not newParent then
                -- O objeto foi deletado do mapa! Limpa a referência imediatamente.
                self:ClearTarget()
            end
        end)
    end
end

-- Retorna o alvo atual validando se ele ainda está vivo
function TargetManager:GetTarget()
    local target = self.CurrentTarget
    
    -- Validação extra de segurança: verifica se o Humanoid ainda existe e está vivo
    if target and target:FindFirstChild("Humanoid") and target.Humanoid.Health > 0 then
        return target
    end
    
    -- Se o alvo estiver morto (mas o corpo ainda não sumiu), nós o limpamos
    if target then
        self:ClearTarget()
    end
    
    return nil
end

-- Força a limpeza do alvo atual
function TargetManager:ClearTarget()
    self.CurrentTarget = nil
    if self._targetConnection then
        self._targetConnection:Disconnect()
        self._targetConnection = nil
    end
end

-- ==========================================
-- 🗣️ ALVOS DE INTERAÇÃO (NPCs de Quest, etc)
-- ==========================================

-- Define um NPC pacífico para interagir (Pegar Quest, Comprar, etc)
function TargetManager:SetInteractionTarget(npcInstance)
    if self._interactionConnection then
        self._interactionConnection:Disconnect()
        self._interactionConnection = nil
    end

    self.InteractionTarget = npcInstance

    if npcInstance then
        self._interactionConnection = npcInstance.AncestryChanged:Connect(function(_, newParent)
            if not newParent then
                self:ClearInteractionTarget()
            end
        end)
    end
end

function TargetManager:GetInteractionTarget()
    return self.InteractionTarget
end

function TargetManager:ClearInteractionTarget()
    self.InteractionTarget = nil
    if self._interactionConnection then
        self._interactionConnection:Disconnect()
        self._interactionConnection = nil
    end
end

-- ==========================================
-- 🧹 LIMPEZA TOTAL (Teardown)
-- ==========================================

-- Chamado pelo Bootstrapper quando o Hub é fechado
function TargetManager:Destroy()
    self:ClearTarget()
    self:ClearInteractionTarget()
end

return TargetManager
