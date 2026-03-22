-- =====================================================================
-- 🚀 BOOTSTRAPPER (Substitui o "Sailor Pice hub.lua")
-- =====================================================================

-- 1. Limpeza de execuções anteriores (Previne sobreposição de UIs e Loops)
if _G.ComunidadeHub_Cleanup then 
    _G.ComunidadeHub_Cleanup() 
end

-- 2. Sistema Avançado de Carregamento de Módulos (Require remoto)
local function requireModule(path)
    -- URL base do repositório (ajuste se mudar o nome do repo/branch)
    local baseUrl = "https://raw.githubusercontent.com/Noob1Code/Sailor-Piece-Hub/refs/heads/main/Sailor-Piece-Hub/"
    local url = baseUrl .. path .. ".lua"
    
    local success, result = pcall(function()
        local request = game:HttpGet(url)
        local func, syntaxErr = loadstring(request)
        if not func then
            error("Erro de sintaxe no arquivo " .. path .. ": " .. tostring(syntaxErr))
        end
        return func()
    end)
    
    if not success then
        warn("❌ Falha crítica ao carregar o módulo [" .. path .. "]\nErro: " .. tostring(result))
        return nil
    end
    
    return result
end

print("⏳ Iniciando Hub (Arquitetura Modular)...")

-- =====================================================================
-- ⚙️ INJEÇÃO DE DEPENDÊNCIAS
-- =====================================================================

-- 3. Nível 1: Dados Puros e Estado
local Constants = requireModule("Core/Constants")
local Config = requireModule("Core/Config")

if not Constants or not Config then
    return warn("❌ Falha ao carregar os dados base. Execução abortada.")
end

-- 4. Nível 2: Serviços Essenciais e Gerenciamento de Memória
local Workspace = game:GetService("Workspace")

local ItemCache = requireModule("Services/ItemCache").new(Workspace)
local TargetManager = requireModule("Services/TargetManager").new()
local CombatService = requireModule("Services/CombatService").new(Constants, Config)

-- 5. Nível 3: Lógica Central (Cérebro) e Interface Visual
local FSM = requireModule("Logic/FSM").new(TargetManager, Config, CombatService, ItemCache, Constants)
local UI = requireModule("UI/Interface").new(Config, FSM, Constants)

-- =====================================================================
-- 🔄 MOTOR DE EXECUÇÃO
-- =====================================================================

-- 6. Loop Único Centralizado (Substitui todos os 'while wait()' soltos)
local RunService = game:GetService("RunService")
local mainConnection = RunService.Heartbeat:Connect(function(deltaTime)
    if Config.IsRunning then
        FSM:Update(deltaTime)
    end
end)

print("✅ Comunidade Hub carregado com sucesso!")

-- =====================================================================
-- 🧹 ROTINA DE DESLIGAMENTO SEGURO
-- =====================================================================

-- 7. Função de Limpeza (Teardown) chamada ao re-executar ou fechar a UI
_G.ComunidadeHub_Cleanup = function()
    print("🧹 Encerrando instâncias anteriores do Hub...")
    if mainConnection then mainConnection:Disconnect() end
    if Config and Config.IsRunning ~= nil then Config.IsRunning = false end
    if FSM and typeof(FSM.Destroy) == "function" then FSM:Destroy() end 
    if UI and typeof(UI.Destroy) == "function" then UI:Destroy() end
    if ItemCache and typeof(ItemCache.Destroy) == "function" then ItemCache:Destroy() end
    if TargetManager and typeof(TargetManager.Destroy) == "function" then TargetManager:Destroy() end
end
