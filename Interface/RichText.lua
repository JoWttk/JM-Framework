local RichText = {}

local function parse(text)
    local tokens = {}
    local i = 1

    while i <= #text do
        local startPos, endPos = text:find("{.-}", i)

        if startPos then
            if startPos > i then
                table.insert(tokens, {
                    type = "text",
                    value = text:sub(i, startPos - 1)
                })
            end

            local iconName = text:sub(startPos + 1, endPos - 1)

            table.insert(tokens, {
                type = "icon",
                value = iconName
            })

            i = endPos + 1
        else
            table.insert(tokens, {
                type = "text",
                value = text:sub(i)
            })
            break
        end
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

local function getIconImage(name)
    if name == "SPACE" then
        return KEY_ICONS_EXTRA
    end
    
    return KEY_ICONS
end

function RichText.draw(text, x, y, scale, iconScale)
    scale = scale or 1
    iconScale = iconScale or scale

    local font = love.graphics.getFont()
    local tokens = parse(text)
    local posX = x

    for _, token in ipairs(tokens) do
        if token.type == "text" then
            love.graphics.print(token.value, posX, y, 0, scale, scale)
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