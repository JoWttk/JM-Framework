---@class Input
---@field keysDown table<string, boolean> Currently held keys
---@field keysPressed table<string, boolean> Keys pressed this frame
---@field mouseDown table<number, boolean> Currently held mouse buttons
---@field mousePressed table<number, boolean> Mouse buttons pressed this frame
---@field mouseX number Current mouse X position
---@field mouseY number Current mouse Y position
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

---Clears single-frame press state. Called automatically on LOVE update.
function Input.update()
    Input.keysPressed = {}
    Input.mousePressed = {}
end

---Handles key press event and advances dialogues on Enter.
---@param key string The key that was pressed
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

---Handles key release event.
---@param key string The key that was released
function Input.keyreleased(key)
    Input.keysDown[key] = false
end

---Check if a key is currently held down.
---@param key string The key name (e.g. "w", "space", "return")
---@return boolean
function Input.isDown(key)
    return Input.keysDown[key]
end

---Check if a key was pressed this frame (single-shot).
---@param key string The key name
---@return boolean
function Input.wasPressed(key)
    return Input.keysPressed[key]
end

---Handles mouse press event.
---@param x number Mouse X position
---@param y number Mouse Y position
---@param button number Mouse button (1 = left, 2 = right, etc.)
function Input.mousepressed(x, y, button)
    Input.mouseDown[button] = true
    Input.mousePressed[button] = true
    Input.mouseX = x
    Input.mouseY = y
end

---Handles mouse release event.
---@param x number Mouse X position
---@param y number Mouse Y position
---@param button number Mouse button that was released
function Input.mousereleased(x, y, button)
    Input.mouseDown[button] = false
    Input.mouseX = x
    Input.mouseY = y
end

---Handles mouse movement event.
---@param x number New mouse X position
---@param y number New mouse Y position
function Input.mousemoved(x, y)
    Input.mouseX = x
    Input.mouseY = y
end

---Check if a mouse button is currently held down.
---@param button number Mouse button (1 = left, 2 = right)
---@return boolean
function Input.isMouseDown(button)
    return Input.mouseDown[button]
end

---Check if a mouse button was pressed this frame (single-shot).
---@param button number Mouse button
---@return boolean
function Input.wasMousePressed(button)
    return Input.mousePressed[button]
end

---Get current raw mouse position.
---@return number x, number y Mouse X and Y coordinates
function Input.getMousePosition()
    return Input.mouseX, Input.mouseY
end

---Get mouse position converted to canvas coordinates (UI space).
---@return number canvasX, number canvasY
function Input.getCanvasMousePosition()
    return UI.getCanvasCoordinates(Input.mouseX, Input.mouseY)
end

return Input
