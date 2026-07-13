local Camera = {}

Camera.x = 0
Camera.y = 0
Camera.targetX = 0
Camera.targetY = 0
Camera.smoothness = 5
Camera.scale = 1.25
Camera.rotation = 0

Camera._followX = 0
Camera._followY = 0

Camera.bounds = {
    enabled = false,
    minX = 0, minY = 0,
    maxX = 0, maxY = 0
}

Camera.deadzone = {
    enabled = false,
    width = 100, height = 100
}

Camera.shake = {
    duration = 0,
    intensity = 0
}

Camera.shakeOffsetX = 0
Camera.shakeOffsetY = 0

function Camera.load()
    Camera.x = 0
    Camera.y = 0
end

function Camera.onResize()
    Camera.targetX = Camera._followX - BASE_WIDTH  / (2 * Camera.scale)
    Camera.targetY = Camera._followY - BASE_HEIGHT / (1.7 * Camera.scale)
    Camera.x = Camera.targetX
    Camera.y = Camera.targetY
end

function Camera.update(dt)
    local lerp = math.min(1, Camera.smoothness * dt)
    Camera.x = Camera.x + (Camera.targetX - Camera.x) * lerp
    Camera.y = Camera.y + (Camera.targetY - Camera.y) * lerp

    if Camera.bounds.enabled then
        local viewWidth  = BASE_WIDTH  / Camera.scale
        local viewHeight = BASE_HEIGHT / Camera.scale

        if Camera.bounds.minX then
            Camera.x = math.max(Camera.bounds.minX, Camera.x)
        end
        if Camera.bounds.maxX then
            Camera.x = math.min(Camera.x, Camera.bounds.maxX - viewWidth)
        end

        if Camera.bounds.minY then
            Camera.y = math.max(Camera.bounds.minY, Camera.y)
        end
        if Camera.bounds.maxY then
            Camera.y = math.min(Camera.y, Camera.bounds.maxY - viewHeight)
        end
    end
end

function Camera.follow(x, y)
    Camera._followX = x
    Camera._followY = y

    if Camera.deadzone.enabled then
        local centerX = Camera.x + BASE_WIDTH  / (2 * Camera.scale)
        local centerY = Camera.y + BASE_HEIGHT / (1.7 * Camera.scale)

        local dx = x - centerX
        local dy = y - centerY

        if math.abs(dx) > Camera.deadzone.width / 2 then
            Camera.targetX = x - BASE_WIDTH / (2 * Camera.scale)
        end

        if math.abs(dy) > Camera.deadzone.height / 2 then
            Camera.targetY = y - BASE_HEIGHT / (2 * Camera.scale)
        end
    else
        Camera.targetX = x - BASE_WIDTH  / (2 * Camera.scale)
        Camera.targetY = y - BASE_HEIGHT / (1.7 * Camera.scale)
    end
end

function Camera.set()
    love.graphics.push()
    love.graphics.scale(Camera.scale, Camera.scale)
    love.graphics.rotate(Camera.rotation)
    love.graphics.translate(-Camera.x - Camera.shakeOffsetX, -Camera.y - Camera.shakeOffsetY)
end

function Camera.unset()
    love.graphics.pop()
end

function Camera.setBounds(minX, minY, maxX, maxY)
    Camera.bounds.enabled = true
    Camera.bounds.minX = minX
    Camera.bounds.minY = minY 
    Camera.bounds.maxX = maxX
    Camera.bounds.maxY = maxY
end

function Camera.removeBounds()
    Camera.bounds.enabled = false
end

function Camera.setDeadzone(width, height)
    Camera.deadzone.enabled = true
    Camera.deadzone.width = width
    Camera.deadzone.height = height
end

function Camera.removeDeadzone()
    Camera.deadzone.enabled = false
end

function Camera.startShake(duration, intensity)
    Camera.shake.duration = duration
    Camera.shake.intensity = intensity
end

function Camera.updateShake(dt)
    if Camera.shake.duration > 0 then
        Camera.shake.duration = Camera.shake.duration - dt
        Camera.shakeOffsetX = (math.random() - 0.5) * 2 * Camera.shake.intensity
        Camera.shakeOffsetY = (math.random() - 0.5) * 2 * Camera.shake.intensity
    else
        Camera.shakeOffsetX = 0
        Camera.shakeOffsetY = 0
    end
end

function Camera.toWorld(x, y)
    return x + Camera.x, y + Camera.y
end

function Camera.toScreen(x, y)
    return x - Camera.x, y - Camera.y
end

return Camera