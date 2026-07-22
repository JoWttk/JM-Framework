local InterfaceText = {}

---@param x number
---@param y number
---@param font string
---@param fontSize number
---@param textColor table
---@param textStroke number
---@param textStrokeColor table | nil
---@param transparency number
function InterfaceText:new(x, y, font, fontSize, text, textColor, textStroke, textStrokeColor, transparency)
    local textObj = {}
    textObj.x = x
    textObj.y = y
    textObj.text = tostring(text)
    textObj.textColor = textColor or {1, 1, 1}
    textObj.textStroke = textStroke or 0
    textObj.textStrokeColor = textStrokeColor or {0, 0, 0}
    textObj.fontPath = font
    textObj.fontSize = fontSize or 16
    textObj.transparency = transparency or 1

    function textObj:draw()
        local font = UI.getFont(self.fontPath, self.fontSize)
        love.graphics.setFont(font)

        if self.textStroke and self.textStroke > 0 then
            local strokeColor = {self.textStrokeColor[1], self.textStrokeColor[2], self.textStrokeColor[3], self.transparency}
            love.graphics.setColor(strokeColor)

            local r = self.textStroke
            local steps = math.max(8, math.floor(r * 2))

            for i = 1, steps do
                local ang = (i / steps) * math.pi * 2
                local dx = math.floor(math.cos(ang) * r + 0.5)
                local dy = math.floor(math.sin(ang) * r + 0.5)
                RichText.draw(self.text, self.x + dx, self.y + dy, 1, nil, nil, strokeColor)
            end
        end

        local r = self.textColor[1]
        local g = self.textColor[2]
        local b = self.textColor[3]
        local a = self.transparency

        love.graphics.setColor(r, g, b, a)
        RichText.draw(self.text, self.x, self.y, 1)
        love.graphics.setColor(1, 1, 1, 1)
    end

    function textObj:setText(newText)
        self.text = tostring(newText)
    end

    function textObj:getText()
        return self.text
    end

    function textObj:getFontSize()
        return self.fontSize
    end

    function textObj:setFontSize(newSize)
        self.fontSize = newSize
    end

    function textObj:centerAt(cx)
        local font = UI.getFont(self.fontPath, self.fontSize)
        love.graphics.setFont(font)
        local w = RichText.measure(self.text or "", 1)
        self.x = (cx or (BASE_WIDTH/2)) - (w / 2)
    end

    return textObj
end

return InterfaceText