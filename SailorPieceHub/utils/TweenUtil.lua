-- =========================================================================
-- 🧰 TweenUtil
-- Coleção de funções puras para movimentação suave.
-- Desacoplado de regras de negócio. Evita sobreposição de Tweens.
-- =========================================================================

local GameServices = require(script.Parent.Parent.core.GameServices)

local TweenUtil = {}

-- Tabela com chaves fracas (weak keys) para evitar Memory Leaks.
-- Se o objeto for destruído pelo jogo, ele some desta tabela automaticamente.
local _activeTweens = setmetatable({}, { __mode = "k" })

-- =========================================================================
-- FUNÇÕES DE CONTROLE
-- =========================================================================

-- Para e limpa qualquer Tween ativo em um objeto
-- @param object (Instance): A peça ou modelo que está sendo animado
function TweenUtil.StopTween(object)
    if not object then return end

    local currentTween = _activeTweens[object]
    if currentTween then
        pcall(function()
            currentTween:Cancel()
        end)
        _activeTweens[object] = nil
    end
end

-- =========================================================================
-- FUNÇÕES DE ANIMAÇÃO
-- =========================================================================

-- Move qualquer objeto suavemente para um objetivo (CFrame, Position, Color, etc)
-- @param object (Instance): O objeto a ser animado
-- @param goal (table): Dicionário com as propriedades finais (ex: {CFrame = CFrame.new(...)})
-- @param duration (number): Tempo em segundos
-- @param easingStyle (Enum.EasingStyle): Estilo da curva de animação (Padrão: Linear)
-- @param easingDirection (Enum.EasingDirection): Direção da curva (Padrão: Out)
-- @return Tween: O objeto Tween criado
function TweenUtil.TweenTo(object, goal, duration, easingStyle, easingDirection)
    if not object or not goal then return nil end

    -- Define valores padrão caso não sejam enviados
    duration = duration or 1
    easingStyle = easingStyle or Enum.EasingStyle.Linear
    easingDirection = easingDirection or Enum.EasingDirection.Out

    -- Para o tween anterior do mesmo objeto para evitar conflitos (glitches)
    TweenUtil.StopTween(object)

    local success, result = pcall(function()
        local tweenInfo = TweenInfo.new(duration, easingStyle, easingDirection)
        local tween = GameServices.TweenService:Create(object, tweenInfo, goal)
        
        -- Armazena no cache de Tweens ativos
        _activeTweens[object] = tween

        -- Limpa do cache automaticamente quando terminar
        tween.Completed:Connect(function()
            if _activeTweens[object] == tween then
                _activeTweens[object] = nil
            end
        end)

        tween:Play()
        return tween
    end)

    if success then
        return result
    else
        warn("[TweenUtil] Falha ao criar Tween:", result)
        return nil
    end
end

-- Utilitário específico para mover Personagens (Calcula a velocidade automaticamente)
-- @param character (Model): O modelo do personagem (ex: LocalPlayer.Character)
-- @param position (Vector3): Posição final desejada
-- @param speed (number): Velocidade em Studs por Segundo (ex: 150)
-- @return Tween: O objeto Tween criado
function TweenUtil.MoveToPosition(character, position, speed)
    if not character or not position then return nil end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    speed = speed or 150

    -- Calcula o tempo necessário com base na distância e velocidade
    local distance = (hrp.Position - position).Magnitude
    local duration = distance / speed

    -- Previne tempos zerados ou negativos que quebram o TweenService
    if duration < 0.1 then 
        duration = 0.1 
    end

    -- Cria o alvo usando CFrame (mais seguro que alterar a Position diretamente)
    local goal = {CFrame = CFrame.new(position)}

    return TweenUtil.TweenTo(hrp, goal, duration)
end

return TweenUtil
