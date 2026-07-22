local ScreenshotTaken = {
    isVisible = false
}

local WIDTH = 260
local HEIGHT = 64
local MARGIN = 16
local VISIBLE_TIME = 3
local ANIM_DURATION = 0.35

local box = { x = 0, y = 0 }
local titleText, button
local built = false
local isVisible = false
local hideTimer = 0
local currentFolder = nil
local wasMouseDown = false

---Removes any pending tweens already controlling this target,
---avoiding a "fight" with a previous animation (e.g. show() called twice quickly).
local function cancelTweensFor(target)
    for i = #Tween.list, 1, -1 do
        if Tween.list[i].target == target then
            table.remove(Tween.list, i)
        end
    end
end

local function refreshLayout()
    box.x = BASE_WIDTH - WIDTH - MARGIN
end

local function build()
    if built then return end
    built = true

    refreshLayout()
    box.y = BASE_HEIGHT + 10

    titleText = Text:new(
        box.x + 16, box.y + 12,
        "assets/fonts/PressStart2P-Regular.ttf", 9,
        "Screenshot Taken",
        {1, 1, 1}, 2, {0, 0, 0}
    )

    button = Button:new(
        box.x + WIDTH - 76, box.y + HEIGHT - 40,
        60, 26,
        {0.85, 0.45, 0.15}, "Open",
        {1, 1, 1}, "assets/fonts/PressStart2P-Regular.ttf", 8,
        2, {0, 0, 0},
        function() ScreenshotTaken.openFolder() end,
        "scale"
    )
end

---Shows the toast. `folder` is the path the "Open" button will open
---(default: "Screenshots" folder inside LÖVE's save directory).
function ScreenshotTaken.show(folder)
    build()
    refreshLayout()

    currentFolder = folder or (love.filesystem.getSaveDirectory() .. "/Screenshots")

    cancelTweensFor(box)
    Tween.to(box, { y = BASE_HEIGHT - HEIGHT - MARGIN }, ANIM_DURATION, Tween.easing.backOut)

    isVisible = true
    hideTimer = VISIBLE_TIME
end

function ScreenshotTaken.hide()
    if not built or not isVisible then return end
    isVisible = false

    cancelTweensFor(box)
    Tween.to(box, { y = BASE_HEIGHT + 10 }, ANIM_DURATION, Tween.easing.quadIn)
end

function ScreenshotTaken.openFolder()
    if not currentFolder then return end
    love.system.openURL("file://" .. currentFolder)
end

---@param dt number
---@param mx number|nil Mouse X position, in the same coordinate space used by the other buttons (base resolution)
---@param my number|nil Mouse Y position
---@param mouseDown boolean|nil Whether the mouse button is currently pressed
function ScreenshotTaken.update(dt, mx, my, mouseDown)
    if not built then return end

    titleText.x = box.x + 16
    titleText.y = box.y + 12
    button:setPosition(box.x + WIDTH - 76, box.y + HEIGHT - 40)

    if isVisible then
        hideTimer = hideTimer - dt
        if hideTimer <= 0 then
            ScreenshotTaken.hide()
        end
    end

    if mx and my then
        local justPressed = mouseDown and not wasMouseDown
        button:update(mx, my, justPressed)
        wasMouseDown = mouseDown or false
    end

    ScreenshotTaken.isVisible = isVisible
end

function ScreenshotTaken.draw()
    if not built then return end
    if box.y >= BASE_HEIGHT + 5 then return end

    love.graphics.setColor(0.13, 0.1, 0.14, 0.95)
    love.graphics.rectangle("fill", box.x, box.y, WIDTH, HEIGHT, 8)

    love.graphics.setColor(1, 1, 1, 0.15)
    love.graphics.rectangle("line", box.x, box.y, WIDTH, HEIGHT, 8)

    titleText:draw()
    button:draw()

    love.graphics.setColor(1, 1, 1, 1)
end

return ScreenshotTaken