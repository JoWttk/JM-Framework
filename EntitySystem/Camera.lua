---@class Camera
---@field x number | nil Current camera X position
---@field y number | nil Current camera Y position
---@field targetX number Target X position for smooth movement
---@field targetY number Target Y position for smooth movement
---@field smoothness number Lerp smoothness factor
---@field scale number Camera zoom scale
---@field rotation number Camera rotation angle
---@field _followX number Internal tracked X follow position
---@field _followY number Internal tracked Y follow position
---@field bounds { enabled: boolean, minX: number | nil, minY: number | nil, maxX: number, maxY: number | nil } Camera movement boundaries
---@field deadzone { enabled: boolean, width: number, height: number } Deadzone for camera follow
---@field shake { duration: number, intensity: number } Screen shake parameters
---@field shakeOffsetX number Current X shake offset
---@field shakeOffsetY number Current Y shake offset
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

Camera.mapView = false
Camera.savedScale = nil
Camera.savedBoundsEnabled = nil

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

---Reset camera position to origin
function Camera.load()
    Camera.x = 0
    Camera.y = 0
end

---Recalculate camera target on window resize
function Camera.onResize()
    Camera.targetX = Camera._followX - BASE_WIDTH  / (2 * Camera.scale)
    Camera.targetY = Camera._followY - BASE_HEIGHT / (1.7 * Camera.scale)
    Camera.x = Camera.targetX
    Camera.y = Camera.targetY
end

---Update camera position with smooth lerp
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

---Set the camera to follow a position
---@param x number Target X position
---@param y number Target Y position
function Camera.follow(x, y)
    Camera._followX = x
    Camera._followY = y

    if Camera.mapView then return end

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

---Apply camera transform for rendering
function Camera.set()
    love.graphics.push()
    love.graphics.scale(Camera.scale, Camera.scale)
    love.graphics.rotate(Camera.rotation)
    love.graphics.translate(-Camera.x - Camera.shakeOffsetX, -Camera.y - Camera.shakeOffsetY)
end

---Remove camera transform
function Camera.unset()
    love.graphics.pop()
end

---Set camera movement boundaries
---@param minX number | nil Minimum X bound
---@param minY number | nil Minimum Y bound
---@param maxX number Maximum X bound
---@param maxY number | nil Maximum Y bound
function Camera.setBounds(minX, minY, maxX, maxY)
    Camera.bounds.enabled = true
    Camera.bounds.minX = minX
    Camera.bounds.minY = minY 
    Camera.bounds.maxX = maxX
    Camera.bounds.maxY = maxY
end

---Remove camera movement boundaries
function Camera.removeBounds()
    Camera.bounds.enabled = false
end

---Set camera deadzone for follow
---@param width number Deadzone width
---@param height number Deadzone height
function Camera.setDeadzone(width, height)
    Camera.deadzone.enabled = true
    Camera.deadzone.width = width
    Camera.deadzone.height = height
end

---Remove camera deadzone
function Camera.removeDeadzone()
    Camera.deadzone.enabled = false
end

---Start screen shake effect
---@param duration number Shake duration in seconds
---@param intensity number Shake intensity
function Camera.startShake(duration, intensity)
    Camera.shake.duration = duration
    Camera.shake.intensity = intensity
end

---Update screen shake effect
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

---Convert screen coordinates to world coordinates
---@param x number Screen X
---@param y number Screen Y
---@return number worldX
---@return number worldY
function Camera.toWorld(x, y)
    return x + Camera.x, y + Camera.y
end

---Convert world coordinates to screen coordinates
---@param x number World X
---@param y number World Y
---@return number screenX
---@return number screenY
function Camera.toScreen(x, y)
    return x - Camera.x, y - Camera.y
end

---Zoom out to show the whole map area
function Camera.showFullMap(minX, minY, maxX, maxY, padding)
    padding = padding or 50
    minX = minX - padding
    minY = minY - padding
    maxX = maxX + padding
    maxY = maxY + padding

    local w = maxX - minX
    local h = maxY - minY

    if not Camera.mapView then
        Camera.savedScale = Camera.scale
        Camera.savedBoundsEnabled = Camera.bounds.enabled
    end

    Camera.mapView = true
    Camera.bounds.enabled = false

    local scaleX = BASE_WIDTH / w
    local scaleY = BASE_HEIGHT / h
    Camera.scale = math.min(scaleX, scaleY)

    Camera.targetX = minX + w / 2 - BASE_WIDTH / (2 * Camera.scale)
    Camera.targetY = minY + h / 2 - BASE_HEIGHT / (2 * Camera.scale)
end

---Return camera to normal follow mode
function Camera.hideFullMap()
    if not Camera.mapView then return end

    Camera.mapView = false
    Camera.scale = Camera.savedScale or Camera.scale
    Camera.bounds.enabled = Camera.savedBoundsEnabled

    Camera.follow(Camera._followX, Camera._followY)
end

return Camera