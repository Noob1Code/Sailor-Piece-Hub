-- =========================================================================
-- 🟢 Bootstrapper (Ponto de Entrada)
-- Responsável exclusivamente por carregar e dar a partida na arquitetura.
-- Impede execuções duplicadas (Ghosting) e limpa a memória antes de iniciar.
-- =========================================================================

print("⏳ [Comunidade Hub] Inicializando sistema...")

-- 1. SISTEMA ANTI-FANTASMA (Limpeza de instâncias anteriores)
-- Verifica se o hub já estava rodando e o desliga corretamente.
-- (Usamos _G apenas aqui na raiz para permitir que o usuário re-execute o script sem crashar o jogo)
if _G.ComunidadeHub_App then
    print("🧹 [Comunidade Hub] Limpando versão anterior...")
    pcall(function()
        _G.ComunidadeHub_App:Destroy()
    end)
    _G.ComunidadeHub_App = nil
    task.wait(0.5) -- Pausa breve para garantir que os loops antigos morreram
end

-- 2. IMPORTAÇÃO DO CONTROLADOR PRINCIPAL
-- Atenção: O caminho do require depende de como você compila (Rojo, LuaBundle, etc).
-- Aqui simulamos que todos os arquivos estão dentro de uma pasta na raiz do script.
local success, MainController = pcall(function()
    return require(script.controllers.MainController)
end)

if not success or not MainController then
    warn("❌ [Comunidade Hub] Erro crítico: Arquivos da arquitetura não encontrados ou falha ao compilar.")
    warn(tostring(MainController)) -- Exibe o erro real do require
    return
end

-- 3. INICIALIZAÇÃO DA APLICAÇÃO
pcall(function()
    -- Instancia a orquestração (Isso cria o StateManager, Loops, e Serviços internamente)
    local app = MainController.new()
    
    -- Salva na memória global APENAS para podermos desligar numa futura re-execução
    _G.ComunidadeHub_App = app
    
    -- Dá a partida no motor!
    app:Init()
end)

print("✅ [Comunidade Hub] Bootstrapper finalizado. Hub online.")
