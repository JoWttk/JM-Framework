---@class Scene
---@field current table|nil The currently active scene module
---@field scenes table<string, table> Registered scene modules
local Scene = {}
local current = nil
local scenes = {}

local Table = require("engine.Utils.Table")

local activeFade = nil

---Smoothstep interpolation function for fade transitions.
---@param t number Value between 0 and 1
---@return number
local function smoothstep(t)
    return t * t * (3 - 2 * t)
end

---Create a fade-out effect (screen goes to black).
---@param TIME number Duration in seconds
---@param onComplete function|nil Callback when fade completes
---@return table Fade object with update, draw, and isDone methods
local function fadeOut(TIME, onComplete)
    local timer = 0
    local done = false

    return {
        update = function(dt)
            if done then return end
            timer = timer + dt
            if timer >= TIME then
                timer = TIME
                done = true
                if onComplete then onComplete() end
            end
        end,

        draw = function()
            if done then return end
            local t = smoothstep(timer / TIME)
            love.graphics.setColor(0, 0, 0, t)
            love.graphics.rectangle("fill", 0, 0, BASE_WIDTH, BASE_HEIGHT)
            love.graphics.setColor(1, 1, 1, 1)
        end,

        isDone = function() return done end
    }
end

---Create a fade-in effect (screen fades from black to visible).
---@param TIME number Duration in seconds
---@param onComplete function|nil Callback when fade completes
---@return table Fade object with update, draw, and isDone methods
local function fadeIn(TIME, onComplete)
    local timer = 0
    local done = false

    return {
        update = function(dt)
            if done then return end
            timer = timer + dt
            if timer >= TIME then
                timer = TIME
                done = true
                if onComplete then onComplete() end
            end
        end,

        draw = function()
            if done then return end
            local t = smoothstep(timer / TIME)
            local alpha = 1 - t
            love.graphics.setColor(0, 0, 0, alpha)
            love.graphics.rectangle("fill", 0, 0, BASE_WIDTH, BASE_HEIGHT)
            love.graphics.setColor(1, 1, 1, 1)
        end,

        isDone = function() return done end
    }
end

---Register a scene module by name.
---@param name string Scene identifier
---@param scene table Scene module with load/update/draw functions
function Scene.register(name, scene)
    scenes[name] = scene
end

---Get the currently loaded scene module from the global CURRENT_SCENE.
---@return table
function Scene.getCurrentModule()
    return require("scenes." .. CURRENT_SCENE)
end

---Get the currently active scene.
---@return table|nil
function Scene.get()
    return current
end

---Load a scene directly (no transition).
---@param scene string|table Scene name (registered) or scene module
function Scene.load(scene)
    if type(scene) == "string" then
        scene = scenes[scene]
    end

    current = scene
    if current and current.load then
        current.load()
    end
end

---Check if a fade transition is currently active.
---@return boolean
function Scene.isTransitioning()
    return activeFade ~= nil
end

---Perform a fade-out then fade-in transition with a mid-function.
---@param outTime number Fade-out duration in seconds (default 0.35)
---@param midFn function|nil Function to execute between fades
---@param inTime number Fade-in duration in seconds (default 0.35)
---@param endFn function|nil Function to execute after transition completes
function Scene.transition(outTime, midFn, inTime, endFn)
    outTime = outTime or 0.35
    inTime  = inTime or 0.35

    activeFade = fadeOut(outTime, function()
        if midFn then midFn() end

        activeFade = fadeIn(inTime, function()
            activeFade = nil
            if endFn then endFn() end
        end)
    end)
end

---Change to a different scene, optionally with a fade transition.
---@param name string Name of the scene (must be registered)
---@param doFade boolean|nil Whether to use fade transition
---@param callback function|nil Function that runs after the scene change
function Scene.change(name, doFade, callback)
    local scene = scenes[name]
    if not scene then return end

    local Player = require("entities.Player")
    Player.currentCollision = nil

    local nonGame = { Menu = true, Settings = true, UserCreator = true, MapSelector = true, Demo = true }

    local function changeNow()
        if callback then callback() end
        
        current = scene
        OLD_SCENE = CURRENT_SCENE
        CURRENT_SCENE = name

        if CURRENT_SCENE_MODULE then 
            package.loaded[CURRENT_SCENE_MODULE] = nil
        end
        CURRENT_SCENE_MODULE = require("scenes." .. CURRENT_SCENE)

        if current.load then current.load() end
        
        if not nonGame[name] then
            love.audio.play(SOUNDS["game-start"])
        end
    end

    if doFade then
        Scene.transition(0.35, function()
            changeNow()
        end, 0.35)
    else
        changeNow()
    end
end

---Update the current scene and active fade transition.
---@param dt number Delta time in seconds
function Scene.update(dt)
    if current and current.update then
        current.update(dt)
    end

    if activeFade then
        activeFade.update(dt)
    end
end

---Draw the current scene and active fade overlay.
function Scene.draw()
    if current and current.draw then
        current.draw()
    end

    if activeFade then
        activeFade.draw()
    end
end

---Forward key press event to the current scene.
---@param key string The key that was pressed
function Scene.keypressed(key)
    if current and current.keypressed then
        current.keypressed(key)
    end
end

---Forward key release event to the current scene.
---@param key string The key that was released
function Scene.keyreleased(key)
    if current and current.keyreleased then
        current.keyreleased(key)
    end
end

return Scene
