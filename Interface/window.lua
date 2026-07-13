local RichText = require("engine.Interface.RichText")

local Window = {
    active = false,
    fullText = "",
    onComplete = nil,
    
    bgColor = {0, 0, 0, 0.8},
    borderColor = {1, 1, 1},
    textColor = {1, 1, 1},
    borderWidth = 2,
    
    font = nil,
    iconScale = 1,
    
    offsetX = 0,
    offsetY = -50,
    paddingX = 8,
    paddingY = 6,
    minWidth = 80,
    maxWidth = 280
}

function Window.loadFont()
    if not Window.font then
        Window.font = love.graphics.newFont("assets/fonts/PixeloidSans-Bold.ttf", 12)
    end
end

function Window.show(text, callback)
    Window.loadFont()
    Window.active = true
    Window.fullText = text
    Window.onComplete = callback
end

function Window.close()
    Window.active = false
    Window.fullText = ""
    Window.onComplete = nil
end

function Window.update(dt)
    --
end

local function calculateTextSize(text, maxWidth)
    if not Window.font then Window.loadFont() end
    
    local lines = 1
    local maxLineWidth = 0
    local currentLineWidth = 0
    
    local function splitWords(str)
        local parts = {}
        local pos = 1
        while pos <= #str do
            local startPos, endPos = str:find("%S+", pos)
            if not startPos then
                table.insert(parts, str:sub(pos))
                break
            end
            if startPos > pos then
                table.insert(parts, str:sub(pos, startPos - 1))
            end
            local word = str:sub(startPos, endPos)
            local nextSpace = str:match("(%s*)", endPos + 1)
            if nextSpace then
                table.insert(parts, word .. nextSpace)
                pos = endPos + 1 + #nextSpace
            else
                table.insert(parts, word)
                pos = endPos + 1
            end
        end
        return parts
    end
    
    for _, word in ipairs(splitWords(text)) do
        local wordWidth = Window.font:getWidth(word)
        if currentLineWidth + wordWidth > maxWidth and currentLineWidth > 0 then
            maxLineWidth = math.max(maxLineWidth, currentLineWidth)
            currentLineWidth = wordWidth
            lines = lines + 1
        else
            currentLineWidth = currentLineWidth + wordWidth
        end
    end
    maxLineWidth = math.max(maxLineWidth, currentLineWidth)
    
    local textHeight = lines * (Window.font:getHeight() * 1.5)
    
    return maxLineWidth, textHeight
end

function Window.getTextSize()
    if not Window.font then Window.loadFont() end
    local maxWidth = Window.maxWidth - Window.paddingX * 2
    
    return calculateTextSize(Window.fullText, maxWidth)
end

function Window.draw()
    if not Window.active then return end

    local Player = require("entities.Player")
    Window.loadFont()

    local previousFont = love.graphics.getFont()
    if Window.font then love.graphics.setFont(Window.font) end

    local maxContentWidth = Window.maxWidth - Window.paddingX * 2
    local lineHeight = Window.font:getHeight() * 1.5

    local contentWidth, numLines = RichText.measureWrapped(
        Window.fullText,
        0,         
        maxContentWidth,
        1,
        Window.iconScale
    )

    local contentHeight = numLines * lineHeight

    local width  = math.max(Window.minWidth, contentWidth + Window.paddingX * 2)
    local height = contentHeight + Window.paddingY * 2

    local x = Player.getX() + Window.offsetX - width / 2
    local y = Player.getY() + Window.offsetY

    love.graphics.setColor(Window.bgColor)
    love.graphics.rectangle("fill", x, y, width, height)

    love.graphics.setColor(Window.borderColor)
    love.graphics.setLineWidth(Window.borderWidth)
    love.graphics.rectangle("line", x, y, width, height)

    love.graphics.setColor(Window.textColor)
    RichText.drawWrapped(
        Window.fullText,
        x + Window.paddingX,
        y + Window.paddingY,
        width - Window.paddingX * 2,
        lineHeight,
        1,
        Window.iconScale
    )

    love.graphics.setFont(previousFont)
end

function Window.config(cfg)
    if cfg.offsetX then Window.offsetX = cfg.offsetX end
    if cfg.offsetY then Window.offsetY = cfg.offsetY end
    if cfg.paddingX then Window.paddingX = cfg.paddingX end
    if cfg.paddingY then Window.paddingY = cfg.paddingY end
    if cfg.padding then Window.paddingX = cfg.padding; Window.paddingY = cfg.padding end
    if cfg.minWidth then Window.minWidth = cfg.minWidth end
    if cfg.maxWidth then Window.maxWidth = cfg.maxWidth end
    if cfg.bgColor then Window.bgColor = cfg.bgColor end
    if cfg.borderColor then Window.borderColor = cfg.borderColor end
    if cfg.textColor then Window.textColor = cfg.textColor end
    if cfg.borderWidth then Window.borderWidth = cfg.borderWidth end
    if cfg.iconScale then Window.iconScale = cfg.iconScale end
    if cfg.fontSize then
        Window.font = love.graphics.newFont("assets/fonts/PressStart2P-Regular.ttf", cfg.fontSize)
    end
end

function Window.isActive()
    return Window.active
end

return Window