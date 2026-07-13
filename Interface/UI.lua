local UI = {}

UI.baseWidth = BASE_WIDTH
UI.baseHeight = BASE_HEIGHT
UI.scale = 1
UI.fontCache = {}

function UI.init(baseW, baseH)
    UI.baseWidth = baseW or UI.baseWidth
    UI.baseHeight = baseH or UI.baseHeight
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    UI.scale = math.min(w / UI.baseWidth, h / UI.baseHeight)
    UI.fontCache = {}
end

function UI.getScale()
    return UI.scale
end

function UI.px(v)
    return (v or 0) * UI.scale
end

function UI.getFont(path, size)
    local scaledSize = size or 12
    local key = tostring(path or "default") .. ":" .. tostring(scaledSize)
    if UI.fontCache[key] then return UI.fontCache[key] end

    local f
    if path and path ~= "" then
        f = love.graphics.newFont(path, scaledSize)
    else
        f = love.graphics.newFont(scaledSize)
    end

    UI.fontCache[key] = f
    return f
end

function UI.getCanvasCoordinates(windowX, windowY)
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    local scaleX = w / UI.baseWidth
    local scaleY = h / UI.baseHeight
    local scale = math.min(scaleX, scaleY)
    
    local drawWidth = UI.baseWidth * scale
    local drawHeight = UI.baseHeight * scale
    local offsetX = (w - drawWidth) / 2
    local offsetY = (h - drawHeight) / 2
    
    local canvasX = (windowX - offsetX) / scale
    local canvasY = (windowY - offsetY) / scale
    
    return canvasX, canvasY
end

return UI
