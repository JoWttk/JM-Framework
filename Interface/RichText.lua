local RichText = {}

---Parse text into tokens supporting {icon}, [color=#RRGGBB]text[/color], and plain text.
---@param text string The input text to parse
---@return table[] List of tokens with type, value, and optional color fields
local function parse(text)
    local tokens = {}
    local i = 1

    while i <= #text do
        local colorStart, colorEnd = text:find("%[color=#[%x][%x][%x][%x][%x][%x]%]", i)
        if colorStart and colorStart == i then
            local colorHex = text:sub(colorStart + 7, colorEnd - 1)
            local closeTag = text:find("%[/color%]", colorEnd + 1)
            if closeTag then
                local content = text:sub(colorEnd + 1, closeTag - 1)
                table.insert(tokens, {
                    type = "colored",
                    value = content,
                    color = colorHex
                })
                i = closeTag + 8
                goto continue
            end
        end

        local startPos, endPos = text:find("{.-}", i)

        if startPos and startPos == i then
            local iconName = text:sub(startPos + 1, endPos - 1)
            table.insert(tokens, {
                type = "icon",
                value = iconName
            })
            i = endPos + 1
        else
            local nextSpecial = #text + 1
            local nextColor = text:find("%[color=#[%x][%x][%x][%x][%x][%x]%]", i)
            local nextIcon = text:find("{", i)
            if nextColor then nextSpecial = math.min(nextSpecial, nextColor) end
            if nextIcon then nextSpecial = math.min(nextSpecial, nextIcon) end

            table.insert(tokens, {
                type = "text",
                value = text:sub(i, nextSpecial - 1)
            })
            i = nextSpecial
        end

        ::continue::
    end

    return tokens
end

local function splitWords(text)
    local parts = {}
    local pos = 1

    while pos <= #text do
        local startPos, endPos = text:find("%S+", pos)

        if not startPos then
            table.insert(parts, text:sub(pos))
            break
        end

        if startPos > pos then
            table.insert(parts, text:sub(pos, startPos - 1))
        end

        local word = text:sub(startPos, endPos)
        local nextSpace = text:match("(%s*)", endPos + 1)
        if nextSpace then
            table.insert(parts, word .. nextSpace)
            pos = endPos + 1 + #nextSpace
        else
            table.insert(parts, word)
            pos = endPos + 1
        end
    end

    if #parts == 0 then
        table.insert(parts, "")
    end

    return parts
end

---Convert hex color string (#RRGGBB) to RGB values (0-1).
---@param hex string Hex color like "FF0000" or "#FF0000"
---@return number r, number g, number b
local function hexToRGB(hex)
    hex = hex:gsub("#", "")
    local r = tonumber(hex:sub(1, 2), 16) / 255
    local g = tonumber(hex:sub(3, 4), 16) / 255
    local b = tonumber(hex:sub(5, 6), 16) / 255
    return r, g, b
end

local function getIconImage(name)
    if name == "SPACE" then
        return KEY_ICONS_EXTRA
    end
    
    return KEY_ICONS
end

---Calculate the total width of a parsed text string (excluding color markup).
---@param text string The text to measure
---@param scale number Font scale
---@param iconScale number Icon scale
---@return number width
function RichText.measure(text, scale, iconScale)
    scale = scale or 1
    iconScale = iconScale or scale
    local font = love.graphics.getFont()
    local tokens = parse(text)
    local w = 0

    for _, token in ipairs(tokens) do
        if token.type == "text" or token.type == "colored" then
            w = w + font:getWidth(token.value) * scale
        elseif token.type == "icon" then
            local quad = ICONS[token.value]
            if quad then
                local _, _, iconW = quad:getViewport()
                w = w + iconW * iconScale + 2
            else
                w = w + font:getWidth("{" .. token.value .. "}") * scale
            end
        end
    end

    return w
end

---Draw rich text at the given position.
---@param text string Text with optional {icon} and [color=#RRGGBB]text[/color] tags
---@param x number X position (left edge, or center if halign="center")
---@param y number Y position
---@param scale number|nil Font scale (default 1)
---@param iconScale number|nil Icon scale (default = scale)
---@param halign string|nil Horizontal alignment: "left" (default), "center", "right"
function RichText.draw(text, x, y, scale, iconScale, halign)
    x = x or 0
    y = y or 0
    scale = scale or 1
    iconScale = iconScale or scale

    local font = love.graphics.getFont()
    local tokens = parse(text)

    if halign == "center" then
        x = x - RichText.measure(text, scale, iconScale) / 2
    elseif halign == "right" then
        x = x - RichText.measure(text, scale, iconScale)
    end

    local posX = x

    for _, token in ipairs(tokens) do
        if token.type == "text" then
            love.graphics.print(token.value, posX, y, 0, scale, scale)
            posX = posX + font:getWidth(token.value) * scale

        elseif token.type == "colored" then
            local r, g, b = hexToRGB(token.color)
            love.graphics.setColor(r, g, b)
            love.graphics.print(token.value, posX, y, 0, scale, scale)
            love.graphics.setColor(1, 1, 1)
            posX = posX + font:getWidth(token.value) * scale

        elseif token.type == "icon" then
            local quad = ICONS[token.value]

            if quad then
                local iconImage = getIconImage(token.value)
                local _, _, w, h = quad:getViewport()
                local iconY = y + (font:getHeight() - h * iconScale) * 0.5

                love.graphics.draw(iconImage, quad, posX, iconY, 0, iconScale, iconScale)
                posX = posX + w * iconScale + 2
            else
                local txt = "{" .. token.value .. "}"
                love.graphics.print(txt, posX, y, 0, scale, scale)
                posX = posX + font:getWidth(txt) * scale
            end
        end
    end
end

function RichText.drawWrapped(text, x, y, maxWidth, lineHeight, scale, iconScale)
    scale = scale or 1
    iconScale = iconScale or scale
    local font = love.graphics.getFont()
    lineHeight = lineHeight or font:getHeight() * scale

    local function addWrappedLine(lineTokens, currentY)
        local posX = x
        for _, token in ipairs(lineTokens) do
            if token.type == "text" then
                love.graphics.print(token.value, posX, currentY, 0, scale, scale)
                posX = posX + token.width
            elseif token.type == "colored" then
                local r, g, b = hexToRGB(token.color)
                love.graphics.setColor(r, g, b)
                love.graphics.print(token.value, posX, currentY, 0, scale, scale)
                love.graphics.setColor(1, 1, 1)
                posX = posX + font:getWidth(token.value) * scale
            else
                local quad = ICONS[token.value]
                if quad then
                    local iconImage = getIconImage(token.value)
                    local _, _, w, h = quad:getViewport()
                    local iconY = currentY + (font:getHeight() - h * iconScale) * 0.5
                    love.graphics.draw(iconImage, quad, posX, iconY, 0, iconScale, iconScale)
                    posX = posX + w * iconScale + 2
                else
                    local txt = "{" .. token.value .. "}"
                    love.graphics.print(txt, posX, currentY, 0, scale, scale)
                    posX = posX + font:getWidth(txt) * scale
                end
            end
        end
    end

    local function wrapLine(rawLine)
        local tokens = parse(rawLine)
        local wrapped = {}
        local currentLine = {}
        local posX = x

        for _, token in ipairs(tokens) do
            if token.type == "text" then
                for _, segment in ipairs(splitWords(token.value)) do
                    local width = font:getWidth(segment) * scale
                    if posX + width > x + maxWidth and #currentLine > 0 then
                        table.insert(wrapped, currentLine)
                        currentLine = {}
                        posX = x
                    end
                    table.insert(currentLine, {type = "text", value = segment, width = width})
                    posX = posX + width
                end
            elseif token.type == "colored" then
                local width = font:getWidth(token.value) * scale
                if posX + width > x + maxWidth and #currentLine > 0 then
                    table.insert(wrapped, currentLine)
                    currentLine = {}
                    posX = x
                end
                table.insert(currentLine, token)
                posX = posX + width
            else
                local quad = ICONS[token.value]
                local iconWidth
                if quad then
                    local _, _, w, h = quad:getViewport()
                    iconWidth = w * iconScale + 2
                else
                    iconWidth = font:getWidth("{" .. token.value .. "}") * scale
                end

                if posX + iconWidth > x + maxWidth and #currentLine > 0 then
                    table.insert(wrapped, currentLine)
                    currentLine = {}
                    posX = x
                end

                table.insert(currentLine, token)
                posX = posX + iconWidth
            end
        end

        if #currentLine > 0 then
            table.insert(wrapped, currentLine)
        end

        return wrapped
    end

    local start = 1
    while true do
        local nextNewline = text:find("\n", start, true)
        local rawLine
        if nextNewline then
            rawLine = text:sub(start, nextNewline - 1)
        else
            rawLine = text:sub(start)
        end

        for _, lineTokens in ipairs(wrapLine(rawLine)) do
            addWrappedLine(lineTokens, y)
            y = y + lineHeight
        end

        if not nextNewline then
            break
        end
        start = nextNewline + 1
    end
end

function RichText.measureWrapped(text, x, maxWidth, scale, iconScale)
    scale = scale or 1
    iconScale = iconScale or scale
    local font = love.graphics.getFont()

    local totalLines = 0
    local maxLineWidth = 0

    local function measureLine(rawLine)
        local tokens = parse(rawLine)
        local currentLine = {}
        local posX = x
        local lineStartX = x

        local function commitLine()
            local lineWidth = posX - lineStartX
            if lineWidth > maxLineWidth then maxLineWidth = lineWidth end
            totalLines = totalLines + 1
            currentLine = {}
            posX = x
        end

        for _, token in ipairs(tokens) do
            if token.type == "text" then
                for _, segment in ipairs(splitWords(token.value)) do
                    local width = font:getWidth(segment) * scale
                    if posX + width > x + maxWidth and #currentLine > 0 then
                        commitLine()
                    end
                    table.insert(currentLine, true)
                    posX = posX + width
                end
            elseif token.type == "colored" then
                local width = font:getWidth(token.value) * scale
                if posX + width > x + maxWidth and #currentLine > 0 then
                    commitLine()
                end
                table.insert(currentLine, true)
                posX = posX + width
            else
                local quad = ICONS[token.value]
                local iconWidth
                if quad then
                    local _, _, w, _ = quad:getViewport()
                    iconWidth = w * iconScale + 2
                else
                    iconWidth = font:getWidth("{" .. token.value .. "}") * scale
                end

                if posX + iconWidth > x + maxWidth and #currentLine > 0 then
                    commitLine()
                end
                table.insert(currentLine, true)
                posX = posX + iconWidth
            end
        end

        if #currentLine > 0 then
            commitLine()
        end
    end

    local start = 1
    while true do
        local nextNewline = text:find("\n", start, true)
        local rawLine = nextNewline and text:sub(start, nextNewline - 1) or text:sub(start)
        measureLine(rawLine)
        if not nextNewline then break end
        start = nextNewline + 1
    end

    return maxLineWidth, totalLines
end

return RichText