-- =========================================================================
-- 🧰 TweenUtil
-- =========================================================================

local GameServices = Import("core/GameServices")

local TweenUtil = {}
local _activeTweens = setmetatable({}, { __mode = "k" })

function TweenUtil.StopTween(object)
    if not object then return end
    local currentTween = _activeTweens[object]
    if currentTween then
        pcall(function() currentTween:Cancel() end)
        _activeTweens[object] = nil
    end
end

function TweenUtil.TweenTo(object, goal, duration, easingStyle, easingDirection)
    if not object or not goal then return nil end

    duration = duration or 1
    easingStyle = easingStyle or Enum.EasingStyle.Linear
    easingDirection = easingDirection or Enum.EasingDirection.Out

    TweenUtil.StopTween(object)

    local success, result = pcall(function()
        local tweenInfo = TweenInfo.new(duration, easingStyle, easingDirection)
        local tween = GameServices.TweenService:Create(object, tweenInfo, goal)
        
        _activeTweens[object] = tween

        tween.Completed:Connect(function()
            if _activeTweens[object] == tween then _activeTweens[object] = nil end
        end)

        tween:Play()
        return tween
    end)

    if success then return result else warn("[TweenUtil] Falha:", result) return nil end
end

function TweenUtil.MoveToPosition(character, position, speed)
    if not character or not position then return nil end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    speed = speed or 150
    local distance = (hrp.Position - position).Magnitude
    local duration = distance / speed
    if duration < 0.1 then duration = 0.1 end

    local goal = {CFrame = CFrame.new(position)}
    return TweenUtil.TweenTo(hrp, goal, duration)
end

return TweenUtil
