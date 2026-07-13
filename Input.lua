local Input = {
    keysDown = {},
    keysPressed = {},
    mouseDown = {},
    mousePressed = {},
    mouseX = 0,
    mouseY = 0
}

local SimpleD = require("engine.DialogTypes.SimpleDialogue")
local UI = require("engine.Interface.UI")

function Input.update()
    Input.keysPressed = {}
    Input.mousePressed = {}
end

function Input.keypressed(key)
    Input.keysDown[key] = true
    Input.keysPressed[key] = true
    
    local Dialogue = require("engine.DialogTypes.Dialogue")
    if key == "return" and SimpleD.isActive() then
        SimpleD.advance()
    elseif key == "return" and Dialogue.isActive() then
        Dialogue.advance()
    end
end

function Input.keyreleased(key)
    Input.keysDown[key] = false
end

function Input.isDown(key)
    return Input.keysDown[key]
end

function Input.wasPressed(key)
    return Input.keysPressed[key]
end

function Input.mousepressed(x, y, button)
    Input.mouseDown[button] = true
    Input.mousePressed[button] = true
    Input.mouseX = x
    Input.mouseY = y
end

function Input.mousereleased(x, y, button)
    Input.mouseDown[button] = false
    Input.mouseX = x
    Input.mouseY = y
end

function Input.mousemoved(x, y)
    Input.mouseX = x
    Input.mouseY = y
end

function Input.isMouseDown(button)
    return Input.mouseDown[button]
end

function Input.wasMousePressed(button)
    return Input.mousePressed[button]
end

function Input.getMousePosition()
    return Input.mouseX, Input.mouseY
end

function Input.getCanvasMousePosition()
    return UI.getCanvasCoordinates(Input.mouseX, Input.mouseY)
end

return Input