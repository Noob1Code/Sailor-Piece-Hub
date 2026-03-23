local REPO_URL = "https://raw.githubusercontent.com/Noob1Code/Sailor-Piece-Hub/main/SailorPieceHub/"
local moduleCache = {}

getgenv().Import = function(modulePath)
    if moduleCache[modulePath] then return moduleCache[modulePath] end
    
    local url = REPO_URL .. modulePath .. ".lua"
    print("⏳ Importando: " .. modulePath)

    local result
    local success, err = pcall(function()
        result = game:HttpGet(url, true) 
    end)

    if not success or not result or result:find("404: Not Found") then
        error("❌ Erro de Download (Verifique o GitHub): " .. modulePath .. "\nDetalhe: " .. tostring(err))
    end

    local loadedFunc, loadError = loadstring(result)
    if not loadedFunc then
        error("❌ Erro de Sintaxe em: " .. modulePath .. "\nDetalhe: " .. tostring(loadError))
    end

    local moduleData = loadedFunc()
    moduleCache[modulePath] = moduleData
    return moduleData
end

print("🛠️ [Comunidade Hub] Inicializando arquitetura modular...")

if _G.ComunidadeHub_App then
    pcall(function() _G.ComunidadeHub_App:Destroy() end)
    task.wait(0.5)
end

local MainController = Import("controllers/MainController")
_G.ComunidadeHub_App = MainController.new()
_G.ComunidadeHub_App:Init()

print("✅ [Comunidade Hub] Online e Operante!")
