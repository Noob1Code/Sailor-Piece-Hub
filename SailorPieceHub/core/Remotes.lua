-- =========================================================================
-- 📡 Remotes
-- =========================================================================

local GameServices = Import("core/GameServices")
local RS = GameServices.ReplicatedStorage

local Remotes = {
    CombatRemote = nil, AbilityRemote = nil, TeleportRemote = nil,
    AllocateStatRemote = nil, ResetStatsRemote = nil, UseItemRemote = nil,
    TitleEquipRemote = nil, DisplayTitleEquipRemote = nil, TraitRerollRemote = nil,
    RerollSingleStatRemote = nil, HakiArmamentoRemote = nil, HakiObservacaoRemote = nil, SummonBossRemote = nil
}

pcall(function()
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

    local remoteEvents = RS:WaitForChild("RemoteEvents", 5)
    if remoteEvents then
        Remotes.HakiArmamentoRemote = remoteEvents:WaitForChild("HakiRemote", 3)
        Remotes.HakiObservacaoRemote = remoteEvents:WaitForChild("ObservationHakiRemote", 3)
    end

    Remotes.SummonBossRemote = RS:FindFirstChild("RequestSummonBoss", true)
    if not Remotes.SummonBossRemote then
        local generalRemotes = RS:WaitForChild("Remotes", 5)
        if generalRemotes then Remotes.SummonBossRemote = generalRemotes:WaitForChild("RequestSummonBoss", 3) end
    end

    Remotes.TeleportRemote = RS:FindFirstChild("TeleportToPortal", true)
    Remotes.AllocateStatRemote = RS:FindFirstChild("AllocateStat", true)
    Remotes.ResetStatsRemote = RS:FindFirstChild("ResetStats", true)
    Remotes.UseItemRemote = RS:FindFirstChild("UseItem", true)
    Remotes.TitleEquipRemote = RS:FindFirstChild("TitleEquip", true)
    Remotes.DisplayTitleEquipRemote = RS:FindFirstChild("DisplayTitleEquip", true)
    Remotes.TraitRerollRemote = RS:FindFirstChild("TraitReroll", true)
    Remotes.RerollSingleStatRemote = RS:FindFirstChild("RerollSingleStat", true)
end)

table.freeze(Remotes)
return Remotes
