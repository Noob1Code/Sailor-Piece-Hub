local REPO_URL = "https://raw.githubusercontent.com/Noob1Code/Sailor-Piece-Hub/main/SailorPieceHub/"
local moduleCache = {}

getgenv().Import = function(modulePath)
    if moduleCache[modulePath] then
        return moduleCache[modulePath]
    end
    
    local url = REPO_URL .. modulePath .. ".lua?t=" .. tostring(tick())
    
    print("⏳ Importando módulo: " .. modulePath)

    local success, result = pcall(function()
        return game:HttpGet(url)
    end)

    if not success or result:find("404: Not Found") then
        error("❌ Erro 404: Arquivo não encontrado no GitHub -> " .. modulePath)
    end

    local loadedFunc, loadError = loadstring(result)
    if not loadedFunc then
        error("❌ Erro de Sintaxe no arquivo " .. modulePath .. " -> " .. tostring(loadError))
    end

    local moduleData = loadedFunc()
    moduleCache[modulePath] = moduleData

    return moduleData
end

print("🛠️ [Comunidade Hub] Iniciando Bootstrapper Seguro...")

if _G.ComunidadeHub_App then
    pcall(function() _G.ComunidadeHub_App:Destroy() end)
    task.wait(0.5)
end

local MainController = Import("controllers/MainController")

_G.ComunidadeHub_App = MainController.new()
_G.ComunidadeHub_App:Init()

print("✅ [Comunidade Hub] Online e Operante!")
