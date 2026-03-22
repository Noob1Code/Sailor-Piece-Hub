-- =========================================================================
-- 🛠️ GameServices
-- Centraliza todas as chamadas de serviços nativos do Roblox.
-- Evita uso de getgenv() e otimiza a performance evitando múltiplas chamadas
-- repetitivas a game:GetService() espalhadas pelo código.
-- =========================================================================

local GameServices = {
    -- Serviços Essenciais
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Workspace = game:GetService("Workspace"),
    CoreGui = game:GetService("CoreGui"),
    
    -- Serviços de Loop e Animação
    RunService = game:GetService("RunService"),
    TweenService = game:GetService("TweenService"),
    
    -- Serviços de Input e Automação
    UserInputService = game:GetService("UserInputService"),
    VirtualUser = game:GetService("VirtualUser"),
    
    -- Serviços de Dados
    HttpService = game:GetService("HttpService")
}

-- Resolve o LocalPlayer de forma estática para facilitar o acesso global
GameServices.LocalPlayer = GameServices.Players.LocalPlayer

-- Congela a tabela para evitar que algum módulo sobrescreva um serviço acidentalmente
-- (Opcional, mas é uma excelente prática de arquitetura)
table.freeze(GameServices)

return GameServices
