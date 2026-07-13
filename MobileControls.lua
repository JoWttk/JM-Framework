local MobileControls = {
    active = false,
    controlMode = "buttons",

    joystickX = 120,
    joystickY = BASE_HEIGHT - 140,
    joystickRadius = 60,
    joystickInnerRadius = 25,
    joystickThumbX = 0,
    joystickThumbY = 0,
    joystickActive = false,
    joystickTouchId = nil,

    leftBtn = { cx = 70, cy = BASE_HEIGHT - 100, radius = 35, pressed = false, touchId = nil },
    rightBtn = { cx = 160, cy = BASE_HEIGHT - 100, radius = 35, pressed = false, touchId = nil },

    buttons = {},
    buttonVisible = {},
    moveDir = 0,
    jumpPressed = false,
    attackPressed = false,
    dashPressed = false,
    interactPressed = false,
    skipPressed = false,

    _jumpConsumed = false,
    _attackConsumed = false,
    _dashConsumed = false,
    _interactConsumed = false,
    _skipConsumed = false,
    _skipHeld = false,
    _interactHeld = false,
}

local ButtonDefs = {
    {
        id = "jump",
        label = "JUMP",
        x = BASE_WIDTH - 90,
        y = BASE_HEIGHT - 160,
        radius = 42,
        color = {0.2, 0.7, 0.3, 0.6},
        textColor = {1, 1, 1},
    },
    {
        id = "attack",
        label = "ATK",
        x = BASE_WIDTH - 170,
        y = BASE_HEIGHT - 90,
        radius = 34,
        color = {0.8, 0.2, 0.2, 0.6},
        textColor = {1, 1, 1},
    },
    {
        id = "dash",
        label = "DASH",
        x = BASE_WIDTH - 60,
        y = BASE_HEIGHT - 60,
        radius = 30,
        color = {0.2, 0.3, 0.8, 0.6},
        textColor = {1, 1, 1},
    },
    {
        id = "interact",
        label = "ACT",
        x = BASE_WIDTH - 250,
        y = BASE_HEIGHT - 160,
        radius = 34,
        color = {1.0, 0.6, 0.1, 0.6},
        textColor = {1, 1, 1},
    },
    {
        id = "skip",
        label = "SKIP",
        x = BASE_WIDTH - 250,
        y = BASE_HEIGHT - 70,
        radius = 32,
        color = {0.5, 0.2, 0.2, 0.6},
        textColor = {1, 1, 1},
    },
}

local function dist(x1, y1, x2, y2)
    return math.sqrt((x2-x1)^2 + (y2-y1)^2)
end

local _font

function MobileControls.init()
    if not IS_MOBILE then return end
    local screenH = love.graphics.getHeight()
    local baseFontSize = 12
    local scaledFontSize = math.floor(baseFontSize * (screenH / 580))
    scaledFontSize = math.max(10, math.min(16, scaledFontSize))
    _font = love.graphics.newFont("assets/fonts/PressStart2P-Regular.ttf", scaledFontSize)

    MobileControls.buttons = {}
    for _, def in ipairs(ButtonDefs) do
        MobileControls.buttons[def.id] = {
            id = def.id,
            label = def.label,
            cx = def.x,
            cy = def.y,
            radius = def.radius,
            color = def.color,
            textColor = def.textColor,
            pressed = false,
        }
    end

    MobileControls.joystickX = 120
    MobileControls.joystickY = 580 - 140
    MobileControls.joystickRadius = 60
    MobileControls.joystickInnerRadius = 25
    MobileControls.leftBtn.cx = 70
    MobileControls.leftBtn.cy = 580 - 100
    MobileControls.leftBtn.radius = 35
    MobileControls.rightBtn.cx = 160
    MobileControls.rightBtn.cy = 580 - 100
    MobileControls.rightBtn.radius = 35
    MobileControls.active = true

    MobileControls.buttonVisible = {
        jump = true,
        interact = true,
        attack = true,
        dash = true,
        skip = false,
    }
end

function MobileControls.showButton(id, visible)
    if MobileControls.buttonVisible[id] ~= nil then
        MobileControls.buttonVisible[id] = visible
        if not visible and MobileControls.buttons[id] then
            MobileControls.buttons[id].pressed = false
        end
    end
end

function MobileControls.setMode(mode)
    if mode == "analog" or mode == "buttons" then
        MobileControls.controlMode = mode
    end
end

function MobileControls.toggleMode()
    if MobileControls.controlMode == "analog" then
        MobileControls.controlMode = "buttons"
    else
        MobileControls.controlMode = "analog"
    end
end

function MobileControls.mousepressed(x, y, button)
    if not IS_MOBILE or not MobileControls.active then return false end
    if button ~= 1 then return false end
    return MobileControls.touchpressed(0, x, y)
end

function MobileControls.mousemoved(x, y)
    if not IS_MOBILE or not MobileControls.active then return end
    if MobileControls.joystickActive then
        MobileControls.touchmoved(MobileControls.joystickTouchId or 0, x, y)
    end
end

function MobileControls.mousereleased(x, y, button)
    if not IS_MOBILE or not MobileControls.active then return false end
    if button ~= 1 then return false end
    return MobileControls.touchreleased(MobileControls.joystickTouchId or 0, x, y)
end

function MobileControls.touchpressed(id, x, y)
    if not IS_MOBILE or not MobileControls.active then return false end
    local cx, cy = MobileControls:_screenToCanvas(x, y)

    if MobileControls.controlMode == "analog" then
        local jd = dist(cx, cy, MobileControls.joystickX, MobileControls.joystickY)
        if jd < MobileControls.joystickRadius + 20 then
            MobileControls.joystickActive = true
            MobileControls.joystickTouchId = id
            local dx = x - MobileControls.joystickX
            local dy = y - MobileControls.joystickY
            local d = math.sqrt(dx*dx + dy*dy)
            local maxDist = MobileControls.joystickRadius - MobileControls.joystickInnerRadius
            if d > maxDist and d > 0 then
                dx = dx / d * maxDist
                dy = dy / d * maxDist
            end
            MobileControls.joystickThumbX = dx
            MobileControls.joystickThumbY = dy
            return true
        end
    else
        if dist(cx, cy, MobileControls.leftBtn.cx, MobileControls.leftBtn.cy) < MobileControls.leftBtn.radius then
            MobileControls.leftBtn.pressed = true
            MobileControls.leftBtn.touchId = id
            return true
        end

        if dist(cx, cy, MobileControls.rightBtn.cx, MobileControls.rightBtn.cy) < MobileControls.rightBtn.radius then
            MobileControls.rightBtn.pressed = true
            MobileControls.rightBtn.touchId = id
            return true
        end
    end

    for _, btn in pairs(MobileControls.buttons) do
        if not MobileControls.buttonVisible[btn.id] then
            btn.pressed = false
        else
            if dist(cx, cy, btn.cx, btn.cy) < btn.radius then
                btn.pressed = true
                if btn.id == "jump" then
                    MobileControls.jumpPressed = true
                    MobileControls._jumpConsumed = false
                elseif btn.id == "attack" then
                    MobileControls.attackPressed = true
                    MobileControls._attackConsumed = false
                elseif btn.id == "dash" then
                    MobileControls.dashPressed = true
                    MobileControls._dashConsumed = false
                elseif btn.id == "interact" then
                    MobileControls.interactPressed = true
                    MobileControls._interactConsumed = false
                elseif btn.id == "skip" then
                    MobileControls.skipPressed = true
                    MobileControls._skipConsumed = false
                end
                return true
            end
        end
    end

    return false
end

function MobileControls.touchmoved(id, x, y)
    if not IS_MOBILE or not MobileControls.active then return false end
    local cx, cy = MobileControls:_screenToCanvas(x, y)

    if MobileControls.controlMode == "analog" then
        if MobileControls.joystickActive and MobileControls.joystickTouchId == id then
            local dx = cx - MobileControls.joystickX
            local dy = cy - MobileControls.joystickY
            local d = math.sqrt(dx*dx + dy*dy)
            local maxDist = MobileControls.joystickRadius - MobileControls.joystickInnerRadius
            if d > maxDist and d > 0 then
                dx = dx / d * maxDist
                dy = dy / d * maxDist
            end
            MobileControls.joystickThumbX = dx
            MobileControls.joystickThumbY = dy
            return true
        end
    else
        if MobileControls.leftBtn.pressed and MobileControls.leftBtn.touchId == id then
            if dist(cx, cy, MobileControls.leftBtn.cx, MobileControls.leftBtn.cy) >= MobileControls.leftBtn.radius + 10 then
                MobileControls.leftBtn.pressed = false
                MobileControls.leftBtn.touchId = nil
            end
            return true
        end
        if MobileControls.rightBtn.pressed and MobileControls.rightBtn.touchId == id then
            if dist(cx, cy, MobileControls.rightBtn.cx, MobileControls.rightBtn.cy) >= MobileControls.rightBtn.radius + 10 then
                MobileControls.rightBtn.pressed = false
                MobileControls.rightBtn.touchId = nil
            end
            return true
        end
    end

    for _, btn in pairs(MobileControls.buttons) do
        if btn.pressed then
            if dist(cx, cy, btn.cx, btn.cy) >= btn.radius + 10 then
                btn.pressed = false
            end
        end
    end

    return false
end

function MobileControls.touchreleased(id, x, y)
    if not IS_MOBILE or not MobileControls.active then return false end

    if MobileControls.controlMode == "analog" then
        if MobileControls.joystickActive and MobileControls.joystickTouchId == id then
            MobileControls.joystickActive = false
            MobileControls.joystickTouchId = nil
            MobileControls.joystickThumbX = 0
            MobileControls.joystickThumbY = 0
            return true
        end
    else
        if MobileControls.leftBtn.pressed and MobileControls.leftBtn.touchId == id then
            MobileControls.leftBtn.pressed = false
            MobileControls.leftBtn.touchId = nil
            return true
        end
        if MobileControls.rightBtn.pressed and MobileControls.rightBtn.touchId == id then
            MobileControls.rightBtn.pressed = false
            MobileControls.rightBtn.touchId = nil
            return true
        end
    end

    for _, btn in pairs(MobileControls.buttons) do
        if btn.pressed then
            btn.pressed = false
            return true
        end
    end

    return false
end

function MobileControls.update(dt)
    if not IS_MOBILE or not MobileControls.active then return end

    if MobileControls.controlMode == "analog" then
        local threshold = 15
        if MobileControls.joystickActive then
            if MobileControls.joystickThumbX > threshold then
                MobileControls.moveDir = 1
            elseif MobileControls.joystickThumbX < -threshold then
                MobileControls.moveDir = -1
            else
                MobileControls.moveDir = 0
            end
        else
            MobileControls.moveDir = 0
        end
    else
        local left = MobileControls.leftBtn.pressed
        local right = MobileControls.rightBtn.pressed
        if left and not right then
            MobileControls.moveDir = -1
        elseif right and not left then
            MobileControls.moveDir = 1
        else
            MobileControls.moveDir = 0
        end
    end
end

function MobileControls.wasJumpPressed()
    if not IS_MOBILE then return false end
    if MobileControls.jumpPressed and not MobileControls._jumpConsumed then
        MobileControls._jumpConsumed = true
        return true
    end
    return false
end

function MobileControls.wasAttackPressed()
    if not IS_MOBILE then return false end
    if MobileControls.attackPressed and not MobileControls._attackConsumed then
        MobileControls._attackConsumed = true
        return true
    end
    return false
end

function MobileControls.wasDashPressed()
    if not IS_MOBILE then return false end
    if MobileControls.dashPressed and not MobileControls._dashConsumed then
        MobileControls._dashConsumed = true
        return true
    end
    return false
end

function MobileControls.wasInteractPressed()
    if not IS_MOBILE then return false end
    if MobileControls.interactPressed and not MobileControls._interactConsumed then
        MobileControls._interactConsumed = true
        return true
    end
    return false
end

function MobileControls.wasSkipPressed()
    if not IS_MOBILE then return false end
    if MobileControls.skipPressed and not MobileControls._skipConsumed then
        MobileControls._skipConsumed = true
        return true
    end
    return false
end

function MobileControls.getMoveDir()
    if not IS_MOBILE then return 0 end
    return MobileControls.moveDir
end

function MobileControls.injectInput(Input, Scene)
    if not IS_MOBILE or not MobileControls.active then return end

    if MobileControls.wasInteractPressed() then
        local SimpleD = require("engine.DialogTypes.SimpleDialogue")
        if SimpleD.isActive() then
            Input.keypressed("return")
        else
            Input.keypressed("space")
        end
    end

    local skipBtn = MobileControls.buttons["skip"]
    if skipBtn and skipBtn.pressed then
        if not MobileControls._skipHeld then
            MobileControls._skipHeld = true
            Input.keypressed("backspace")
            if Scene and Scene.keypressed then
                Scene.keypressed("backspace")
            end
        end
    else
        if MobileControls._skipHeld then
            MobileControls._skipHeld = false
            Input.keyreleased("backspace")
            if Scene and Scene.keyreleased then
                Scene.keyreleased("backspace")
            end
        end
    end
end

function MobileControls:_screenToCanvas(sx, sy)
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    local scaleX = w / BASE_WIDTH
    local scaleY = h / BASE_HEIGHT
    local scale = math.min(scaleX, scaleY)
    local drawWidth = BASE_WIDTH * scale
    local drawHeight = BASE_HEIGHT * scale
    local offsetX = (w - drawWidth) / 2
    local offsetY = (h - drawHeight) / 2
    
    return (sx - offsetX) / scale, (sy - offsetY) / scale
end

function MobileControls.draw()
    if not IS_MOBILE or not MobileControls.active then return end
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    local scaleX = w / BASE_WIDTH
    local scaleY = h / BASE_HEIGHT
    local scale = math.min(scaleX, scaleY)
    local drawWidth = BASE_WIDTH * scale
    local drawHeight = BASE_HEIGHT * scale
    local offsetX = (w - drawWidth) / 2
    local offsetY = (h - drawHeight) / 2

    local function toScreen(cx, cy)
        return offsetX + cx * scale, offsetY + cy * scale
    end

    if MobileControls.controlMode == "analog" then
        local sx, sy = toScreen(MobileControls.joystickX, MobileControls.joystickY)
        love.graphics.setColor(0.2, 0.2, 0.2, 0.4)
        love.graphics.circle("fill", sx, sy, MobileControls.joystickRadius * scale)

        love.graphics.setColor(0.4, 0.4, 0.4, 0.3)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", sx, sy, MobileControls.joystickRadius * scale)

        local tx = MobileControls.joystickX + MobileControls.joystickThumbX
        local ty = MobileControls.joystickY + MobileControls.joystickThumbY
        local stx, sty = toScreen(tx, ty)

        love.graphics.setColor(0.6, 0.7, 0.9, 0.5)
        love.graphics.circle("fill", stx, sty, MobileControls.joystickInnerRadius * scale)

        love.graphics.setColor(0.7, 0.8, 1.0, 0.4)
        love.graphics.setLineWidth(1)
        love.graphics.circle("line", stx, sty, MobileControls.joystickInnerRadius * scale)
    else
        local lx, ly = toScreen(MobileControls.leftBtn.cx, MobileControls.leftBtn.cy)
        local lr, lg, lb = 0.3, 0.3, 0.3
        if MobileControls.leftBtn.pressed then
            lr, lg, lb = 0.5, 0.5, 0.5
        end
        love.graphics.setColor(lr, lg, lb, 0.5)
        love.graphics.circle("fill", lx, ly, MobileControls.leftBtn.radius * scale)
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.setLineWidth(1)
        love.graphics.circle("line", lx, ly, MobileControls.leftBtn.radius * scale)
        if _font then
            love.graphics.setFont(_font)
            love.graphics.setColor(1, 1, 1, 0.8)
            love.graphics.print("<", lx - 8 * scale, ly - _font:getHeight() / 2)
        end

        local rx, ry = toScreen(MobileControls.rightBtn.cx, MobileControls.rightBtn.cy)
        local rr, rg, rb = 0.3, 0.3, 0.3
        if MobileControls.rightBtn.pressed then
            rr, rg, rb = 0.5, 0.5, 0.5
        end
        love.graphics.setColor(rr, rg, rb, 0.5)
        love.graphics.circle("fill", rx, ry, MobileControls.rightBtn.radius * scale)
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.setLineWidth(1)
        love.graphics.circle("line", rx, ry, MobileControls.rightBtn.radius * scale)
        if _font then
            love.graphics.setFont(_font)
            love.graphics.setColor(1, 1, 1, 0.8)
            love.graphics.print(">", rx - 8 * scale, ry - _font:getHeight() / 2)
        end
    end

    for _, btn in pairs(MobileControls.buttons) do
        if MobileControls.buttonVisible[btn.id] then
            local bx, by = toScreen(btn.cx, btn.cy)
            local r, g, b, a = btn.color[1], btn.color[2], btn.color[3], btn.color[4]
            if btn.pressed then
                r = math.min(1, r + 0.2)
                g = math.min(1, g + 0.2)
                b = math.min(1, b + 0.2)
                a = math.min(1, a + 0.2)
            end
            love.graphics.setColor(r, g, b, a)
            love.graphics.circle("fill", bx, by, btn.radius * scale)

            love.graphics.setColor(1, 1, 1, 0.3)
            love.graphics.setLineWidth(1)
            love.graphics.circle("line", bx, by, btn.radius * scale)

            if _font then
                love.graphics.setFont(_font)
                local tw = _font:getWidth(btn.label)
                love.graphics.setColor(btn.textColor[1], btn.textColor[2], btn.textColor[3], 0.9)
                love.graphics.print(btn.label, bx - (tw / 2) * scale, by - (_font:getHeight() / 2) * scale)
            end
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return MobileControls