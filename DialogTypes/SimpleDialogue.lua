local SimpleD = {
    active = false,
    fullText = "",
    displayedText = "",

    dialogues = {},
    index = 1,
    queue = {},
    onComplete = nil,

    x = nil,
    y = nil,
    width = 640,
    minHeight = 70,
    maxHeight = 220,
    padding = 14,
    bottomMargin = 30,
    letterSpacing = 2,

    lines = {},
    lineUnits = {},
    lineLens = {},
    totalChars = 0,
    lineHeight = 0,
    boxW = 0,
    boxH = 0,

    bgColor = {0, 0, 0, 0.9},
    borderColor = {1, 1, 1},
    textColor = {1, 1, 1},
    borderWidth = 3,

    showIndicator = true,
    indicatorText = "▼",
    indicatorBlink = true,
    indicatorTimer = 0,

    font = nil,
    iconScale = 1.6,

    textSpeed = 0.05,
    textTimer = 0,
    currentChar = 0,
    isTyping = false
}

local function getUTF8Chars(str)
    local chars = {}
    local i = 1
    while i <= #str do
        local byte = string.byte(str, i)
        local charLen = 1
        if byte >= 240 then charLen = 4
        elseif byte >= 224 then charLen = 3
        elseif byte >= 192 then charLen = 2
        end
        table.insert(chars, string.sub(str, i, i + charLen - 1))
        i = i + charLen
    end
    return chars
end

local function getIconImage(name)
    if name == "SPACE" then
        return KEY_ICONS_EXTRA
    end
    return KEY_ICONS
end

local function getIconWH(name, iconScale)
    local quad = ICONS[name]
    if not quad then return nil end
    local _, _, w, h = quad:getViewport()
    return w * iconScale, h * iconScale
end

local function tokenizeUnits(font, str, iconScale)
    local units = {}
    local i = 1
    local len = #str

    while i <= len do
        local s, e = str:find("{.-}", i)

        if s == i and e then
            local iconName = str:sub(i + 1, e - 1)
            local w, h = getIconWH(iconName, iconScale)

            if w then
                table.insert(units, { kind = "icon", name = iconName, w = w, h = h })
            else
                local raw = str:sub(i, e)
                for _, c in ipairs(getUTF8Chars(raw)) do
                    table.insert(units, { kind = "char", char = c, w = font:getWidth(c) })
                end
            end

            i = e + 1
        else
            local nextBrace = str:find("{.-}", i)
            local chunk
            if nextBrace then
                chunk = str:sub(i, nextBrace - 1)
                i = nextBrace
            else
                chunk = str:sub(i)
                i = len + 1
            end

            for _, c in ipairs(getUTF8Chars(chunk)) do
                table.insert(units, { kind = "char", char = c, w = font:getWidth(c) })
            end
        end
    end

    return units
end

local function unitsWidth(units, ls)
    local w = 0
    for i, u in ipairs(units) do
        w = w + u.w
        if i < #units then w = w + ls end
    end
    return w
end

local function drawUnits(units, x, y, ls, color, font, lineHeight, iconScale, limit)
    love.graphics.setColor(color)
    local cx = x
    local n = limit or #units

    for i = 1, n do
        local u = units[i]
        if u.kind == "char" then
            love.graphics.setColor(color)
            love.graphics.print(u.char, cx, y)
            cx = cx + u.w + ls
        else
            love.graphics.setColor(1, 1, 1, 1)
            local img = getIconImage(u.name)
            local quad = ICONS[u.name]
            local iconY = y + (font:getHeight() - u.h) * 0.5
            love.graphics.draw(img, quad, cx, iconY, 0, iconScale, iconScale)
            cx = cx + u.w + ls
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

local function wrapText(font, text, maxW, ls, iconScale)
    local lines = {}

    for paragraph in (text .. "\n"):gmatch("(.-)\n") do
        if paragraph == "" then
            table.insert(lines, "")
        else
            local current = nil
            for word in paragraph:gmatch("%S+") do
                local candidate = current and (current .. " " .. word) or word
                local units = tokenizeUnits(font, candidate, iconScale)
                local w = unitsWidth(units, ls)

                if current and w > maxW then
                    table.insert(lines, current)
                    current = word
                else
                    current = candidate
                end
            end
            if current then
                table.insert(lines, current)
            end
        end
    end

    return lines
end

local function computeLayout()
    local font = SimpleD.font
    local ls = SimpleD.letterSpacing or 0
    local iconScale = SimpleD.iconScale
    local availW = SimpleD.width - SimpleD.padding * 2

    local lines = wrapText(font, SimpleD.fullText, availW, ls, iconScale)

    SimpleD.lines = lines
    SimpleD.lineUnits = {}
    SimpleD.lineLens = {}
    local total = 0
    for i, line in ipairs(lines) do
        local units = tokenizeUnits(font, line, iconScale)
        SimpleD.lineUnits[i] = units
        SimpleD.lineLens[i] = #units
        total = total + #units
    end
    SimpleD.totalChars = total

    SimpleD.lineHeight = font:getHeight() * 1.2
    local textBlockH = #lines * SimpleD.lineHeight

    local bottomReserve = SimpleD.showIndicator and 28 or 0
    local contentH = textBlockH + SimpleD.padding * 2 + bottomReserve

    SimpleD.boxW = SimpleD.width
    SimpleD.boxH = math.max(SimpleD.minHeight, math.min(SimpleD.maxHeight, contentH))
end

function SimpleD.loadFont()
    if not SimpleD.font then
        SimpleD.font = love.graphics.newFont("assets/fonts/PressStart2P-Regular.ttf", 12)
    end
end

local function loadCurrent(text, callback)
    SimpleD.fullText = text or ""
    SimpleD.displayedText = ""
    SimpleD.currentChar = 0
    SimpleD.isTyping = true
    SimpleD.onComplete = callback
    computeLayout()
end

function SimpleD.show(text, callback)
    SimpleD.loadFont()
    SimpleD.active = true
    SimpleD.dialogues = { text }
    SimpleD.index = 1
    loadCurrent(text, callback)
end

function SimpleD.showSequence(dialogueList, callback)
    SimpleD.loadFont()
    SimpleD.active = true
    SimpleD.dialogues = dialogueList
    SimpleD.index = 1
    loadCurrent(dialogueList[1], callback)
end

function SimpleD.enqueue(dialogueList, callback)
    table.insert(SimpleD.queue, {
        dialogues = type(dialogueList) == "table" and dialogueList or { dialogueList },
        callback = callback
    })
end

function SimpleD.advance()
    if not SimpleD.active then return end

    if SimpleD.isTyping then
        SimpleD.currentChar = SimpleD.totalChars
        SimpleD.isTyping = false
        return
    end

    SimpleD.index = SimpleD.index + 1

    if SimpleD.index <= #SimpleD.dialogues then
        loadCurrent(SimpleD.dialogues[SimpleD.index], SimpleD.onComplete)
    else
        SimpleD.finish()
    end
end

function SimpleD.finish()
    if SimpleD.onComplete then
        SimpleD.onComplete()
    end

    if #SimpleD.queue > 0 then
        local nextEntry = table.remove(SimpleD.queue, 1)
        SimpleD.showSequence(nextEntry.dialogues, nextEntry.callback)
    else
        SimpleD.close()
    end
end

function SimpleD.close()
    SimpleD.active = false
    SimpleD.dialogues = {}
    SimpleD.index = 1
    SimpleD.onComplete = nil
    SimpleD.displayedText = ""
    SimpleD.fullText = ""
    SimpleD.isTyping = false
    SimpleD.lines = {}
    SimpleD.lineUnits = {}
    SimpleD.totalChars = 0
end

function SimpleD.isActive()
    return SimpleD.active
end

function SimpleD.skip()
    SimpleD.queue = {}
    SimpleD.finish()
end

function SimpleD.update(dt)
    if not SimpleD.active then return end

    if SimpleD.indicatorBlink then
        SimpleD.indicatorTimer = SimpleD.indicatorTimer + dt
    end

    if SimpleD.isTyping then
        SimpleD.textTimer = SimpleD.textTimer + dt

        if SimpleD.textTimer >= SimpleD.textSpeed then
            SimpleD.textTimer = 0
            SimpleD.currentChar = SimpleD.currentChar + 1

            if SimpleD.currentChar <= SimpleD.totalChars then
                if SOUNDS["dialog"] and SOUNDS["dialog"]:isPlaying() then
                    love.audio.stop(SOUNDS["dialog"])
                end
                if SOUNDS["dialog"] then love.audio.play(SOUNDS["dialog"]) end
            else
                SimpleD.currentChar = SimpleD.totalChars
                SimpleD.isTyping = false
            end
        end
    end
end

function SimpleD.draw()
    if not SimpleD.active then return end

    local previousFont = love.graphics.getFont()
    if SimpleD.font then
        love.graphics.setFont(SimpleD.font)
    end

    local sw, sh = BASE_WIDTH, BASE_HEIGHT

    local boxW = SimpleD.boxW
    local boxH = SimpleD.boxH
    local boxX = SimpleD.x or (sw - boxW) / 2
    local boxY = SimpleD.y or (sh - boxH - SimpleD.bottomMargin)

    love.graphics.setColor(SimpleD.bgColor)
    love.graphics.rectangle("fill", boxX, boxY, boxW, boxH)

    love.graphics.setColor(SimpleD.borderColor)
    love.graphics.setLineWidth(SimpleD.borderWidth)
    love.graphics.rectangle("line", boxX, boxY, boxW, boxH)

    local textX = boxX + SimpleD.padding
    local textY = boxY + SimpleD.padding
    local ls = SimpleD.letterSpacing or 0

    local accumulated = 0
    for i, units in ipairs(SimpleD.lineUnits) do
        local len = SimpleD.lineLens[i]
        local show
        if SimpleD.isTyping then
            show = math.max(0, math.min(len, SimpleD.currentChar - accumulated))
        else
            show = len
        end

        if show > 0 then
            drawUnits(units, textX, textY, ls, SimpleD.textColor, SimpleD.font, SimpleD.lineHeight, SimpleD.iconScale, show)
        end

        accumulated = accumulated + len
        textY = textY + SimpleD.lineHeight

        if SimpleD.isTyping and show < len then break end
    end

    if SimpleD.showIndicator and not SimpleD.isTyping then
        local alpha = SimpleD.indicatorBlink and (math.sin(SimpleD.indicatorTimer * 4) * 0.5 + 0.5) or 1
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.printf(
            SimpleD.indicatorText,
            boxX,
            boxY + boxH - 24,
            boxW,
            "center"
        )
    end

    love.graphics.setFont(previousFont)
    love.graphics.setColor(1, 1, 1, 1)
end

function SimpleD.config(cfg)
    for k, v in pairs(cfg) do
        if k == "fontSize" then
            SimpleD.font = love.graphics.newFont("assets/fonts/PressStart2P-Regular.ttf", v)
        else
            SimpleD[k] = v
        end
    end
    if SimpleD.active then
        computeLayout()
    end
end

return SimpleD