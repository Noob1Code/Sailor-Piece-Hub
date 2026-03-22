-- =====================================================================
-- 🚀 BOOTSTRAPPER (Ponto de Entrada e Injeção de Dependências)
-- Responsabilidade: Inicializar o sistema e limpar instâncias antigas.
-- =====================================================================

if _G.ComunidadeHub_Cleanup then 
    _G.ComunidadeHub_Cleanup() 
end

local function requireModule(path)
    local baseUrl = "https://raw.githubusercontent.com/Noob1Code/Sailor-Piece-Hub/refs/heads/main/Sailor-Piece-Hub/"
    local url = baseUrl .. path .. ".lua"
    
    local success, result = pcall(function()
        local request = game:HttpGet(url)
        local func, syntaxErr = loadstring(request)
        if not func then error("Erro de sintaxe no arquivo " .. path .. ": " .. tostring(syntaxErr)) end
        return func()
    end)
    
    if not success then return warn("❌ Falha crítica ao carregar o módulo [" .. path .. "]\nErro: " .. tostring(result)) end
    return result
end

print("⏳ Iniciando Hub (Arquitetura Modular OOP)...")

-- =====================================================================
-- 🛡️ SISTEMA ANTI-AFK (Global do Cliente)
-- =====================================================================
pcall(function()
    local Players = game:GetService("Players")
    local VirtualUser = game:GetService("VirtualUser")
    Players.LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new())
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

-- =====================================================================
-- ⚙️ INJEÇÃO DE DEPENDÊNCIAS
-- =====================================================================
local Constants = requireModule("Core/Constants")
local Config = requireModule("Core/Config")
if not Constants or not Config then return warn("❌ Falha ao carregar os dados base.") end

local Workspace = game:GetService("Workspace")

-- Instanciação dos Serviços (SRP)
local ItemCache = requireModule("Services/ItemCache").new(Workspace)
local TargetManager = requireModule("Services/TargetManager").new()
local CombatService = requireModule("Services/CombatService").new(Constants, Config)

-- Instanciação da Lógica e UI
local FSM = requireModule("Logic/FSM").new(TargetManager, Config, CombatService, ItemCache, Constants)
local UI = requireModule("UI/Interface").new(Config, FSM, Constants, CombatService)

-- =====================================================================
-- 🔄 MOTOR DE EXECUÇÃO (Loop Central)
-- =====================================================================
local RunService = game:GetService("RunService")
local mainConnection = RunService.Heartbeat:Connect(function(deltaTime)
    if Config.IsRunning then
        FSM:Update(deltaTime)
    end
end)

print("✅ Comunidade Hub V2 carregado com sucesso!")

-- Rotina de Limpeza
_G.ComunidadeHub_Cleanup = function()
    print("🧹 Encerrando instâncias do Hub...")
    if mainConnection then mainConnection:Disconnect() end
    if Config and Config.IsRunning ~= nil then Config.IsRunning = false end
    if FSM and typeof(FSM.Destroy) == "function" then FSM:Destroy() end 
    if UI and typeof(UI.Destroy) == "function" then UI:Destroy() end
    if ItemCache and typeof(ItemCache.Destroy) == "function" then ItemCache:Destroy() end
    if TargetManager and typeof(TargetManager.Destroy) == "function" then TargetManager:Destroy() end
end
