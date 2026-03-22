-- =========================================================================
-- 📡 Remotes
-- Mapeia e armazena todos os RemoteEvents e RemoteFunctions do jogo.
-- Centraliza a comunicação com o servidor e previne erros se um remote falhar.
-- =========================================================================

local GameServices = require(script.Parent.GameServices)
local RS = GameServices.ReplicatedStorage

local Remotes = {
    -- Inicializamos todos como nil para referência visual clara
    CombatRemote = nil,
    AbilityRemote = nil,
    TeleportRemote = nil,
    AllocateStatRemote = nil,
    ResetStatsRemote = nil,
    UseItemRemote = nil,
    TitleEquipRemote = nil,
    DisplayTitleEquipRemote = nil,
    TraitRerollRemote = nil,
    RerollSingleStatRemote = nil,
    HakiArmamentoRemote = nil,
    HakiObservacaoRemote = nil,
    SummonBossRemote = nil
}

-- Usamos pcall para evitar que o carregamento do Hub seja abortado caso um Remote mude de lugar
pcall(function()
    -- ⚔️ Sistemas de Combate (Com timeout de 5 segundos para não travar o script)
    local combatSys = RS:WaitForChild("CombatSystem", 5)
    if combatSys then
        local remotes = combatSys:WaitForChild("Remotes", 3)
        if remotes then Remotes.CombatRemote = remotes:WaitForChild("RequestHit", 3) end
    end

    local abilitySys = RS:WaitForChild("AbilitySystem", 5)
    if abilitySys then
        local remotes = abilitySys:WaitForChild("Remotes", 3)
        if remotes then Remotes.AbilityRemote = remotes:WaitForChild("RequestAbility", 3) end
    end

    -- 🛡️ Haki
    local remoteEvents = RS:WaitForChild("RemoteEvents", 5)
    if remoteEvents then
        Remotes.HakiArmamentoRemote = remoteEvents:WaitForChild("HakiRemote", 3)
        Remotes.HakiObservacaoRemote = remoteEvents:WaitForChild("ObservationHakiRemote", 3)
    end

    -- 👑 Invocação de Boss (Tentativa dupla baseada no sistema original)
    Remotes.SummonBossRemote = RS:FindFirstChild("RequestSummonBoss", true)
    if not Remotes.SummonBossRemote then
        local generalRemotes = RS:WaitForChild("Remotes", 5)
        if generalRemotes then
            Remotes.SummonBossRemote = generalRemotes:WaitForChild("RequestSummonBoss", 3)
        end
    end

    -- 📦 Outros Remotes Gerais (Busca recursiva profunda)
    Remotes.TeleportRemote = RS:FindFirstChild("TeleportToPortal", true)
    Remotes.AllocateStatRemote = RS:FindFirstChild("AllocateStat", true)
    Remotes.ResetStatsRemote = RS:FindFirstChild("ResetStats", true)
    Remotes.UseItemRemote = RS:FindFirstChild("UseItem", true)
    Remotes.TitleEquipRemote = RS:FindFirstChild("TitleEquip", true)
    Remotes.DisplayTitleEquipRemote = RS:FindFirstChild("DisplayTitleEquip", true)
    Remotes.TraitRerollRemote = RS:FindFirstChild("TraitReroll", true)
    Remotes.RerollSingleStatRemote = RS:FindFirstChild("RerollSingleStat", true)
end)

-- Congela a tabela para que nenhum módulo substitua os remotes acidentalmente durante o jogo
table.freeze(Remotes)

return Remotes
