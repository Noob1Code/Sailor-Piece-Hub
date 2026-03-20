-- 1. Limpeza de execuções anteriores para evitar loops duplicados (Fantasmas)
if _G.ComunidadeHub_Cleanup then _G.ComunidadeHub_Cleanup() end

-- 2. Inicialização de Variáveis de Controle Global (Necessário para a comunicação das partes)
getgenv().isRunning = true
getgenv().scriptConnections = {}

-- 3. Carregador em Sequência (É OBRIGATÓRIO manter esta exata ordem!)
loadstring(game:HttpGet("https://raw.githubusercontent.com/Noob1Code/Sailor-Piece-Hub/refs/heads/main/1_Dados.lua"))()
task.wait(0.1)

loadstring(game:HttpGet("https://raw.githubusercontent.com/Noob1Code/Sailor-Piece-Hub/refs/heads/main/2_Funcoes.lua"))()
task.wait(0.1)

loadstring(game:HttpGet("https://raw.githubusercontent.com/Noob1Code/Sailor-Piece-Hub/refs/heads/main/3_Loops.lua"))()
task.wait(0.1)

loadstring(game:HttpGet("https://raw.githubusercontent.com/Noob1Code/Sailor-Piece-Hub/refs/heads/main/4_Interface.lua"))()