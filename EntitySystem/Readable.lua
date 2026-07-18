local Readable = {}
Readable.list = {}
Readable.current = nil
Readable.__index = Readable

local Input = require("engine.Input")
local tweenLib = require("engine.Utils.tween")

function Readable:new(x, y, image, font, text, scale)
    local read = {}
    read.img = image
    read.font = font
    read.text = text
    read.scale = scale or 1

    local scaleX = read.scale + 3
    local scaleY = read.scale

    local imgW = image and image:getWidth() or 0
    local imgH = image and image:getHeight() or 0
    local displayW = imgW * scaleX
    local displayH = imgH * scaleY

    local finalY = y or (BASE_HEIGHT / 2 - displayH / 2)
    local startY = BASE_HEIGHT + displayH

    read.x = x or (BASE_WIDTH / 2 - displayW / 2)
    read.y = startY
    read.alpha = 0

    read.displayW = displayW
    read.displayH = displayH

    read.activeTween = tweenLib.to(read, { y = finalY, alpha = 1 }, 0.6, tweenLib.easing.outQuad)

    local pad = 32
    local maxTextW = math.max(displayW - pad * 2, 10)

    function read:draw()
        if read.img then
            love.graphics.setColor(1, 1, 1, read.alpha)
            love.graphics.draw(read.img, read.x, read.y, 0, scaleX, scaleY)
        end

        if read.font and read.text and read.alpha >= 1 then
            love.graphics.setFont(read.font)
            love.graphics.setColor(0, 0, 0)

            local lineH = read.font:getHeight() * 1.2
            local words = {}
            for w in read.text:gmatch("%S+") do
                table.insert(words, w)
            end

            local lines = {}
            local currentLine = ""
            for _, word in ipairs(words) do
                local testLine = currentLine == "" and word or currentLine .. " " .. word
                local tw = read.font:getWidth(testLine)
                if tw > maxTextW and currentLine ~= "" then
                    table.insert(lines, currentLine)
                    currentLine = word
                else
                    currentLine = testLine
                end
            end
            if currentLine ~= "" then
                table.insert(lines, currentLine)
            end

            local totalTextH = #lines * lineH
            local ty = math.floor(read.y + (displayH - totalTextH) / 2)
            for _, line in ipairs(lines) do
                local lw = read.font:getWidth(line)
                local tx = math.floor(read.x + (displayW - lw) / 2)
                love.graphics.print(line, tx, ty)
                ty = ty + lineH
            end

            love.graphics.setColor(1, 1, 1)
        end

        Readable.current = read
    end

    setmetatable(read, self)
    table.insert(Readable.list, read)
    return read
end

function Readable:update(dt)
    if Input.wasMousePressed(1) then
        print("k")
        Readable:destroy(Readable.current)
        Readable.current = nil
    end
end

function Readable:draw()
    for _, v in ipairs(Readable.list) do
        if v.draw then
            v:draw()
        end
    end
end

function Readable:destroy(read)
    for i, v in ipairs(Readable.list) do
        if v == read then
            if v.activeTween then
                tweenLib.cancel(v.activeTween)
            end
            table.remove(Readable.list, i)
            break
        end
    end
end

function Readable.clear()
    for _, v in ipairs(Readable.list) do
        if v.activeTween then
            tweenLib.cancel(v.activeTween)
        end
    end
    Readable.list = {}
end

return Readable