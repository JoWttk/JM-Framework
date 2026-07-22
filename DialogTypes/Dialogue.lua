local Dialogue = {
    active = false,
    steps = {},
    index = 1,
    queue = {},

    speaker = "",
    portrait = nil,
    fullText = "",
    displayedText = "",

    choices = nil,
    selectedChoice = 1,

    onComplete = nil,

    x = nil,
    y = nil,
    width = 560,
    minHeight = 130,
    maxHeight = 320,
    padding = 16,
    cornerRadius = 16,
    bottomMargin = 30,
    letterSpacing = 2,

    portraitSize = 64,
    portraitGap = 16,

    lines = {},
    lineChars = {},
    lineLens = {},
    totalChars = 0,
    lineHeight = 0,
    boxW = 0,
    boxH = 0,

    bgColor = {0, 0, 0, 0.9},
    borderColor = {1, 1, 1},
    textColor = {1, 1, 1},
    speakerColor = {1, 0.85, 0.3},
    choiceColor = {0.8, 0.8, 0.8},
    choiceSelectedColor = {1, 1, 0.4},
    borderWidth = 3,

    showIndicator = true,
    indicatorText = "▼",
    indicatorBlink = true,
    indicatorTimer = 0,

    font = nil,
    speakerFont = nil,
    iconScale = 1.6,

    textSpeed = 0.03,
    textTimer = 0,
    currentChar = 0,
    isTyping = false,
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

local function textWidthLS(font, str, ls)
    local chars = getUTF8Chars(str)
    local w = 0
    for i = 1, #chars do
        w = w + font:getWidth(chars[i])
        if i < #chars then w = w + ls end
    end
    return w
end

local function wrapText(font, text, maxW, ls)
    local lines = {}
    local maxLineW = 0
    for paragraph in (text .. "\n"):gmatch("(.-)\n") do
        if paragraph == "" then
            table.insert(lines, "")
        else
            local current = nil
            for word in paragraph:gmatch("%S+") do
                local candidate = current and (current .. " " .. word) or word
                local w = textWidthLS(font, candidate, ls)
                if current and w > maxW then
                    table.insert(lines, current)
                    maxLineW = math.max(maxLineW, textWidthLS(font, current, ls))
                    current = word
                else
                    current = candidate
                end
            end
            if current then
                table.insert(lines, current)
                maxLineW = math.max(maxLineW, textWidthLS(font, current, ls))
            end
        end
    end
    return lines, maxLineW
end

local function drawSpacedText(font, str, x, y, ls, color)
    love.graphics.setColor(color)
    local chars = getUTF8Chars(str)
    local cx = x
    for _, c in ipairs(chars) do
        love.graphics.print(c, cx, y)
        cx = cx + font:getWidth(c) + ls
    end
    return cx - x
end

local function computeLayout()
    local font = Dialogue.font
    local ls = Dialogue.letterSpacing or 0
    local hasPortrait = Dialogue.portrait ~= nil
    local reserveW = hasPortrait and (Dialogue.portraitSize + Dialogue.portraitGap) or 0
    local availW = Dialogue.width - Dialogue.padding * 2 - reserveW

    local lines = wrapText(font, Dialogue.fullText, availW, ls)

    Dialogue.lines = lines
    Dialogue.lineChars = {}
    Dialogue.lineLens = {}
    local total = 0
    for i, line in ipairs(lines) do
        local chars = getUTF8Chars(line)
        Dialogue.lineChars[i] = chars
        Dialogue.lineLens[i] = #chars
        total = total + #chars
    end
    Dialogue.totalChars = total

    Dialogue.lineHeight = font:getHeight() * 1.2
    local textBlockH = #lines * Dialogue.lineHeight

    local speakerH = 0
    if Dialogue.speaker and Dialogue.speaker ~= "" then
        speakerH = Dialogue.speakerFont:getHeight() + 4
    end

    local bottomReserve
    if Dialogue.choices then
        bottomReserve = font:getHeight() + Dialogue.padding + 6
    elseif Dialogue.showIndicator then
        bottomReserve = 28
    else
        bottomReserve = 0
    end

    local contentH = textBlockH + speakerH + Dialogue.padding * 2 + bottomReserve
    if hasPortrait then
        contentH = math.max(contentH, Dialogue.portraitSize + Dialogue.padding * 2 + bottomReserve)
    end

    Dialogue.boxW = Dialogue.width
    Dialogue.boxH = math.max(Dialogue.minHeight, math.min(Dialogue.maxHeight, contentH))
end

function Dialogue.loadFont()
    if not Dialogue.font then
        Dialogue.font = love.graphics.newFont("assets/fonts/PressStart2P-Regular.ttf", 12)
    end
    if not Dialogue.speakerFont then
        Dialogue.speakerFont = love.graphics.newFont("assets/fonts/PressStart2P-Regular.ttf", 12)
    end
end

local function normalizeStep(step)
    if type(step) == "string" then
        return { text = step }
    end
    return step
end

local function loadStep(step)
    step = normalizeStep(step)
    Dialogue.fullText = step.text or ""
    Dialogue.speaker = step.speaker or ""
    Dialogue.portrait = step.portrait
    Dialogue.choices = step.choices
    Dialogue.selectedChoice = 1
    Dialogue.displayedText = ""
    Dialogue.currentChar = 0
    Dialogue.isTyping = true
    computeLayout()
end

function Dialogue.show(text, opts)
    opts = opts or {}
    Dialogue.loadFont()
    Dialogue.active = true
    Dialogue.steps = { {
        text = text,
        speaker = opts.speaker,
        portrait = opts.portrait,
        choices = opts.choices,
    } }
    Dialogue.index = 1
    Dialogue.onComplete = opts.onComplete
    loadStep(Dialogue.steps[1])
end

function Dialogue.showSequence(stepList, opts)
    opts = opts or {}
    Dialogue.loadFont()
    Dialogue.active = true
    Dialogue.steps = stepList
    Dialogue.index = 1
    Dialogue.onComplete = opts.onComplete
    loadStep(Dialogue.steps[1])
end

function Dialogue.enqueue(stepList, opts)
    table.insert(Dialogue.queue, { steps = stepList, opts = opts or {} })
end

function Dialogue.isActive()
    return Dialogue.active
end

function Dialogue.isChoosing()
    return Dialogue.active and Dialogue.choices ~= nil and not Dialogue.isTyping
end

function Dialogue.advance()
    if not Dialogue.active then return end

    if Dialogue.isTyping then
        Dialogue.currentChar = Dialogue.totalChars
        Dialogue.isTyping = false
        return
    end

    if Dialogue.choices then
        Dialogue.confirmChoice()
        return
    end

    Dialogue.index = Dialogue.index + 1

    if Dialogue.index <= #Dialogue.steps then
        loadStep(Dialogue.steps[Dialogue.index])
    else
        Dialogue.finish()
    end
end

function Dialogue.confirmChoice()
    if not Dialogue.choices then return end
    local choice = Dialogue.choices[Dialogue.selectedChoice]
    if not choice then return end

    if choice.callback then
        choice.callback()
    end

    if choice.next then
        Dialogue.showSequence(choice.next, { onComplete = Dialogue.onComplete })
    else
        Dialogue.finish()
    end
end

function Dialogue.moveSelection(dir)
    if not Dialogue.choices then return end
    Dialogue.selectedChoice = Dialogue.selectedChoice + dir
    if Dialogue.selectedChoice < 1 then
        Dialogue.selectedChoice = #Dialogue.choices
    elseif Dialogue.selectedChoice > #Dialogue.choices then
        Dialogue.selectedChoice = 1
    end
end

function Dialogue.finish()
    if Dialogue.onComplete then
        Dialogue.onComplete()
    end

    if #Dialogue.queue > 0 then
        local nextEntry = table.remove(Dialogue.queue, 1)
        Dialogue.showSequence(nextEntry.steps, nextEntry.opts)
    else
        Dialogue.close()
    end
end

function Dialogue.close()
    Dialogue.active = false
    Dialogue.steps = {}
    Dialogue.index = 1
    Dialogue.onComplete = nil
    Dialogue.displayedText = ""
    Dialogue.fullText = ""
    Dialogue.isTyping = false
    Dialogue.choices = nil
    Dialogue.selectedChoice = 1
    Dialogue.speaker = ""
    Dialogue.portrait = nil
    Dialogue.lines = {}
    Dialogue.totalChars = 0
end

function Dialogue.skip()
    Dialogue.queue = {}
    Dialogue.finish()
end

function Dialogue.update(dt)
    if not Dialogue.active then return end

    if Dialogue.indicatorBlink then
        Dialogue.indicatorTimer = Dialogue.indicatorTimer + dt
    end

    if Dialogue.isTyping then
        Dialogue.textTimer = Dialogue.textTimer + dt
        if Dialogue.textTimer >= Dialogue.textSpeed then
            Dialogue.textTimer = 0
            Dialogue.currentChar = Dialogue.currentChar + 1
            if Dialogue.currentChar <= Dialogue.totalChars then
                if SOUNDS["dialog"] and SOUNDS["dialog"]:isPlaying() then
                    love.audio.stop(SOUNDS["dialog"])
                end
                if SOUNDS["dialog"] then love.audio.play(SOUNDS["dialog"]) end
            else
                Dialogue.currentChar = Dialogue.totalChars
                Dialogue.isTyping = false
            end
        end
        return
    end

    if Dialogue.choices then
        if Input.wasPressed("left") or Input.wasPressed("a") then
            Dialogue.moveSelection(-1)
        elseif Input.wasPressed("right") or Input.wasPressed("d") then
            Dialogue.moveSelection(1)
        end

        if Input.wasPressed("f") or Input.wasPressed("return") then
            Dialogue.confirmChoice()
        end
    else
        if Input.wasPressed("f") then
            Dialogue.advance()
        end
    end
end

function Dialogue.draw()
    if not Dialogue.active then return end

    local previousFont = love.graphics.getFont()
    if Dialogue.font then love.graphics.setFont(Dialogue.font) end

    local sw, sh = BASE_WIDTH, BASE_HEIGHT

    local boxW = Dialogue.boxW
    local boxH = Dialogue.boxH
    local boxX = Dialogue.x or (sw - boxW) / 2
    local boxY = Dialogue.y or (sh - boxH - Dialogue.bottomMargin)

    local r = Dialogue.cornerRadius or 0

    love.graphics.setColor(Dialogue.bgColor)
    love.graphics.rectangle("fill", boxX, boxY, boxW, boxH, r, r)

    love.graphics.setColor(Dialogue.borderColor)
    love.graphics.setLineWidth(Dialogue.borderWidth)
    love.graphics.rectangle("line", boxX, boxY, boxW, boxH, r, r)

    local textX = boxX + Dialogue.padding
    local textY = boxY + Dialogue.padding
    local ls = Dialogue.letterSpacing or 0

    if Dialogue.portrait then
        local pSize = Dialogue.portraitSize
        local pw, ph = Dialogue.portrait:getWidth(), Dialogue.portrait:getHeight()
        local scale = pSize / math.max(pw, ph)

        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", textX, textY, pSize, pSize)

        local drawScale = scale * 0.8
        love.graphics.draw(Dialogue.portrait, textX + (pSize - pw * drawScale) / 2, textY + (pSize - ph * drawScale) / 2, 0, drawScale, drawScale)

        textX = textX + pSize + Dialogue.portraitGap
    end

    if Dialogue.speaker and Dialogue.speaker ~= "" then
        drawSpacedText(Dialogue.speakerFont, Dialogue.speaker, textX, textY, ls, Dialogue.speakerColor)
        textY = textY + Dialogue.speakerFont:getHeight() + 4
    end

    local accumulated = 0
    for i, line in ipairs(Dialogue.lines) do
        local len = Dialogue.lineLens[i]
        local show
        if Dialogue.isTyping then
            show = math.max(0, math.min(len, Dialogue.currentChar - accumulated))
        else
            show = len
        end

        if show > 0 then
            local substr = table.concat(Dialogue.lineChars[i], "", 1, show)
            drawSpacedText(Dialogue.font, substr, textX, textY, ls, Dialogue.textColor)
        end

        accumulated = accumulated + len
        textY = textY + Dialogue.lineHeight

        if Dialogue.isTyping and show < len then break end
    end

    if Dialogue.choices and not Dialogue.isTyping then
        local rowH = Dialogue.font:getHeight() + Dialogue.padding
        local dividerY = boxY + boxH - rowH - 6

        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.line(boxX + Dialogue.padding, dividerY, boxX + boxW - Dialogue.padding, dividerY)

        local gap = 28
        local labels, widths, totalW = {}, {}, 0
        for i, choice in ipairs(Dialogue.choices) do
            local selected = (i == Dialogue.selectedChoice)
            labels[i] = selected and ("< " .. choice.text .. " >") or choice.text
            widths[i] = textWidthLS(Dialogue.font, labels[i], ls)
            totalW = totalW + widths[i]
        end
        totalW = totalW + gap * (#Dialogue.choices - 1)

        local cx = boxX + (boxW - totalW) / 2
        local cy = dividerY + (rowH - Dialogue.font:getHeight()) / 2

        for i, choice in ipairs(Dialogue.choices) do
            local selected = (i == Dialogue.selectedChoice)
            local color = selected and Dialogue.choiceSelectedColor or Dialogue.choiceColor
            drawSpacedText(Dialogue.font, labels[i], cx, cy, ls, color)
            cx = cx + widths[i] + gap
        end
    elseif Dialogue.showIndicator and not Dialogue.isTyping then
        local alpha = Dialogue.indicatorBlink and (math.sin(Dialogue.indicatorTimer * 4) * 0.5 + 0.5) or 1
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.printf(Dialogue.indicatorText, boxX, boxY + boxH - 24, boxW - Dialogue.padding, "right")
    end

    love.graphics.setFont(previousFont)
    love.graphics.setColor(1, 1, 1, 1)
end

function Dialogue.config(cfg)
    for k, v in pairs(cfg) do
        Dialogue[k] = v
    end
    if Dialogue.active then
        computeLayout()
    end
end

return Dialogue