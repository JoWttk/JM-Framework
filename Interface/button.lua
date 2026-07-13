local UI = require("engine.Interface.UI")

local InterfaceButton = {}

function InterfaceButton:new(x, y, width, height, bgColor, text, textColor, font, fontSize, strokeWidth, strokeColor, onClick, hoverStyle)
    local button = {}
    button.x = x
    button.y = y
    button.width = width
    button.minWidth = width
    button.height = height
    button.bgColor = bgColor or {1, 1, 1}
    button.textColor = textColor or {0, 0, 0}
    button.text = text
    button.strokeWidth = strokeWidth or 0
    button.strokeColor = strokeColor or {0, 0, 0}
    button.onClick = onClick
    button.hoverStyle = hoverStyle or "default"
    button.isHovered = false
    button.visible = true
    button.fontPath = font
    button.fontSize = fontSize or 16

    button._scale   = 1.0
    button._glow    = 0.0 
    button._slideX  = 0.0
    button._shakeX  = 0.0 
    button._shakeT  = 0.0

    function button:draw()
        if not self.visible then return end

        local sw = self.strokeWidth or 0
        local cornerRadius = 8

        local sc = self._scale
        local offX = self._slideX + self._shakeX

        local cx = self.x + self.width / 2
        local cy = self.y + self.height / 2
        local dw = self.width * sc
        local dh = self.height * sc
        local dx = cx - dw / 2 + offX
        local dy = cy - dh / 2

        love.graphics.setColor(0, 0, 0, 0.25)
        love.graphics.rectangle("fill", dx + 4, dy + 4, dw, dh, cornerRadius)

        if self.hoverStyle == "glow" and self._glow > 0.01 then
            local gr, gg, gb = self.strokeColor[1], self.strokeColor[2], self.strokeColor[3]
            for i = 3, 1, -1 do
                local spread = i * 4 * self._glow
                love.graphics.setColor(gr, gg, gb, 0.12 * self._glow)
                love.graphics.rectangle("fill",
                    dx - spread, dy - spread,
                    dw + spread * 2, dh + spread * 2,
                    cornerRadius + spread
                )
            end
        end

        if sw > 0 then
            love.graphics.setColor(
                self.strokeColor[1], self.strokeColor[2], self.strokeColor[3],
                self.strokeColor[4] or 1
            )
            love.graphics.rectangle("fill", dx - sw, dy - sw, dw + sw*2, dh + sw*2, cornerRadius)
        end

        local r, g, b, a = self.bgColor[1], self.bgColor[2], self.bgColor[3], self.bgColor[4] or 1
        local lighten = (self.hoverStyle == "default" or self.hoverStyle == "slide" or self.hoverStyle == "shake")
        if lighten and self.isHovered then
            r, g, b = math.min(1, r*1.15), math.min(1, g*1.15), math.min(1, b*1.15)
        end
        love.graphics.setColor(r, g, b, a)
        love.graphics.rectangle("fill", dx, dy, dw, dh, cornerRadius)

        if self.text and self.text ~= "" then
            love.graphics.setColor(
                self.textColor[1], self.textColor[2], self.textColor[3],
                self.textColor[4] or 1
            )
            local f = UI.getFont(self.fontPath, self.fontSize)
            love.graphics.setFont(f)
            local textY = dy + dh/2 - f:getHeight()/2
            love.graphics.printf(self.text, dx, textY, dw, "center")
        end
    end

    function button:update(mx, my, isPressed)
        if not self.visible then return end

        self.isHovered = mx >= self.x and mx <= self.x + self.width
                      and my >= self.y and my <= self.y + self.height

        local lerp = function(a, b, t) return a + (b - a) * t end
        local dt = love.timer.getDelta()

        if self.hoverStyle == "scale" then
            local target = self.isHovered and 1.07 or 1.0
            self._scale = lerp(self._scale, target, 0.18)

        elseif self.hoverStyle == "glow" then
            local target = self.isHovered and 1.0 or 0.0
            self._glow = lerp(self._glow, target, 0.12)

        elseif self.hoverStyle == "slide" then
            local target = self.isHovered and 6.0 or 0.0
            self._slideX = lerp(self._slideX, target, 0.15)

        elseif self.hoverStyle == "shake" then
            if self.isHovered then
                self._shakeT = self._shakeT + dt * 28
                self._shakeX = math.sin(self._shakeT) * 2.5
            else
                self._shakeX = lerp(self._shakeX, 0, 0.25)
                self._shakeT = 0
            end
        end

        if self.isHovered and isPressed and self.onClick then
            self.onClick()
        end
    end

    function button:setText(newText)
        self.text = newText
    end

    function button:fitToText(padding)
        padding = padding or 16
        local f = UI.getFont(self.fontPath, self.fontSize)
        local textWidth = f:getWidth(self.text or "")
        local newWidth = textWidth + padding * 2
        self.width = self.minWidth and math.max(self.minWidth, newWidth) or newWidth
    end

    function button:setPosition(x, y)
        self.x = x or self.x
        self.y = y or self.y
    end

    function button:centerHorizontally(cx)
        cx = cx or (BASE_WIDTH/2)
        self.x = cx - (self.width / 2)
    end

    function button:updateFont(newSize)
        self.fontSize = newSize
        
        local f = UI.getFont(self.fontPath, self.fontSize)
        love.graphics.setFont(f)
    end

    return button
end

return InterfaceButton