local Tween = {}
Tween.list = {}

local function lerp(a, b, t)
    return a + (b - a) * t
end

Tween.easing = {
    linear = function(t) return t end,
    quadIn = function(t) return t * t end,
    quadOut = function(t) return 1 - (1 - t) * (1 - t) end,
    quadInOut = function(t)
        if t < 0.5 then return 2 * t * t end
        return 1 - ((-2 * t + 2) ^ 2) / 2
    end,
    cubicIn = function(t) return t * t * t end,
    cubicOut = function(t) return 1 - (1 - t) ^ 3 end,
    cubicInOut = function(t)
        if t < 0.5 then return 4 * t * t * t end
        return 1 - ((-2 * t + 2) ^ 3) / 2
    end,
    backOut = function(t)
        local c1 = 1.70158
        local c3 = c1 + 1
        return 1 + c3 * (t - 1) ^ 3 + c1 * (t - 1) ^ 2
    end,
    elasticOut = function(t)
        if t == 0 then return 0 end
        if t == 1 then return 1 end
        local c4 = (2 * math.pi) / 3
        return 2 ^ (-10 * t) * math.sin((t * 10 - 0.75) * c4) + 1
    end,
}

function Tween.new(target, props, duration, easing, onComplete)
    local from = {}
    for k in pairs(props) do
        from[k] = target[k]
    end

    local t = {
        target = target,
        from = from,
        to = props,
        duration = duration,
        elapsed = 0,
        easing = easing or Tween.easing.linear,
        onComplete = onComplete,
        done = false,
        delay = 0,
    }

    table.insert(Tween.list, t)
    return t
end

function Tween.delayed(target, props, duration, easing, delay, onComplete)
    local t = Tween.new(target, props, duration, easing, onComplete)
    t.delay = delay or 0
    t.started = false
    return t
end

function Tween.to(target, props, duration, easing, onComplete)
    return Tween.new(target, props, duration, easing, onComplete)
end

function Tween.cancel(t)
    t.done = true
end

function Tween.clear()
    Tween.list = {}
end

function Tween.update(dt)
    for i = #Tween.list, 1, -1 do
        local t = Tween.list[i]

        if t.done then
            table.remove(Tween.list, i)
        else
            if t.delay and t.delay > 0 then
                t.delay = t.delay - dt
            else
                t.elapsed = t.elapsed + dt
                local progress = math.min(t.elapsed / t.duration, 1)
                local eased = t.easing(progress)

                for k, toVal in pairs(t.to) do
                    t.target[k] = lerp(t.from[k], toVal, eased)
                end

                if progress >= 1 then
                    t.done = true
                    if t.onComplete then t.onComplete() end
                    table.remove(Tween.list, i)
                end
            end
        end
    end
end

function Tween.image(image, props, duration, easing, onComplete)
    local state = {
        x = props.x and (props.startX or image.x or 0) or nil,
    }

    if not image.x then image.x = 0 end
    if not image.y then image.y = 0 end
    if not image.scaleX then image.scaleX = 1 end
    if not image.scaleY then image.scaleY = 1 end
    if not image.rotation then image.rotation = 0 end
    if not image.alpha then image.alpha = 1 end

    return Tween.new(image, props, duration, easing, onComplete)
end

function Tween.fadeIn(image, duration, easing, onComplete)
    image.alpha = 0
    return Tween.new(image, { alpha = 1 }, duration, easing, onComplete)
end

function Tween.fadeOut(image, duration, easing, onComplete)
    return Tween.new(image, { alpha = 0 }, duration, easing, onComplete)
end

function Tween.scaleTo(image, sx, sy, duration, easing, onComplete)
    return Tween.new(image, { scaleX = sx, scaleY = sy or sx }, duration, easing, onComplete)
end

function Tween.moveTo(image, x, y, duration, easing, onComplete)
    return Tween.new(image, { x = x, y = y }, duration, easing, onComplete)
end

function Tween.drawImage(img, texture, ox, oy)
    love.graphics.setColor(1, 1, 1, img.alpha or 1)
    love.graphics.draw(
        texture,
        img.x or 0,
        img.y or 0,
        img.rotation or 0,
        img.scaleX or 1,
        img.scaleY or 1,
        ox or 0,
        oy or 0
    )
    love.graphics.setColor(1, 1, 1, 1)
end

return Tween
-- thanks, claude