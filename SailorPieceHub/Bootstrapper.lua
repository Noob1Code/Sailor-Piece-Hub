-- =========================================================================
-- 🟢 Bootstrapper (GitHub Loader)
-- Carrega os módulos direto do seu repositório de forma dinâmica e segura.
-- =========================================================================

-- URL base do seu repositório (apontando para a pasta SailorPieceHub)
local REPO_URL = "https://raw.githubusercontent.com/Noob1Code/Sailor-Piece-Hub/main/SailorPieceHub/"

-- Cache para não baixarmos o mesmo arquivo duas vezes na mesma execução
local moduleCache = {}

-- Criamos uma função global de Importação para substituir o "require"
getgenv().Import = function(modulePath)
    -- Se já baixou antes, retorna do cache instantaneamente
    if moduleCache[modulePath] then
        return moduleCache[modulePath]
    end

    local url = REPO_URL .. modulePath .. ".lua"
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)

    if not success or result:find("404: Not Found") then
        error("❌ Erro ao baixar o módulo: " .. modulePath .. "\nVerifique se o nome/pasta está correto no GitHub.")
    end

    -- Compila o texto baixado em código executável
    local loadedFunc, loadError = loadstring(result)
    if not loadedFunc then
        error("❌ Erro de sintaxe (código escrito errado) no módulo: " .. modulePath .. "\nErro: " .. tostring(loadError))
    end

    -- Executa o módulo e guarda o retorno (a tabela da classe) no cache
    local moduleData = loadedFunc()
    moduleCache[modulePath] = moduleData

    return moduleData
end

-- =========================================================================
-- 🚀 INICIALIZAÇÃO
-- =========================================================================
print("⏳ [Comunidade Hub] Iniciando download e montagem da arquitetura...")

-- Limpa a execução anterior (Anti-Fantasma)
if _G.ComunidadeHub_App then
    pcall(function() _G.ComunidadeHub_App:Destroy() end)
    task.wait(0.2)
end

-- Importa o MainController usando a nossa nova função
local MainController = Import("controllers/MainController")

-- Instancia e dá a partida
_G.ComunidadeHub_App = MainController.new()
_G.ComunidadeHub_App:Init()

print("✅ [Comunidade Hub] Totalmente carregado direto do GitHub!")
