local tween = require "engine.Utils.tween"
local Camera = require "engine.EntitySystem.Camera"

---@class Platform
---@field x number Position X of the platform
---@field y number Position Y of the platform
---@field w number Width of the platform
---@field h number Height of the platform
---@field color table Color of the platform (RGB)
---@field texture love.Image|nil Texture of the platform
---@field tag string Identification tag
---@field canCollide boolean Whether collision is enabled
---@field alpha number Opacity (0-1)
---@field visible boolean Whether the platform is visible
---@field breakable boolean Whether the platform is destructible
---@field breakSide "all" | "top" | "bottom" | "both" | nil Break direction side
---@field onBreak function Callback executed on break
---@field tileTexture boolean Whether texture repeats in tile pattern
---@field layer number Rendering layer
---@field pushable boolean Whether the platform can be pushed
---@field broken boolean Whether the platform is already broken
---@field rotation number Current rotation angle
---@field cornerRadiusX number X radius for rounded corners
---@field cornerRadiusY number Y radius for rounded corners
---@field isCircle boolean Whether the platform is a circle
---@field radius number Radius when shape is a circle
---@field shape table|nil Polygon point list
---@field onTouch function|nil Touch event callback
---@field setRotation function
---@field setPolygon function
---@field setCornerRadius function
---@field tweenTo function
---@field setCollision function
---@field getCollision function
local Platform = {}

Platform.list = {}
Platform.currentLayer = 1

Platform._sortedDirty = true
Platform._sortedList = {}

local OutlineShader = love.graphics.newShader("engine/Shaders/Templates/Outline.glsl")

function Platform.setLayer(layer)
    Platform.currentLayer = layer or 1
end

function Platform.getLayer()
    return Platform.currentLayer
end

local function makeRock(w, h)
    local pts = {}
    local sides = love.math.random(7,10)
    local baseAngle = (2*math.pi) / sides

    for i = 0, sides - 1 do
        local angleJitter =(love.math.random() - 0.5)*baseAngle*0.4
        local angle = baseAngle * i + angleJitter

        local r = 0.75+love.math.random()* 0.35

        table.insert(pts,w/2+math.cos(angle)*(w/2)*r)
        table.insert(pts,h/2+math.sin(angle)*(h/2)*r)
    end

    return pts
end

local function rebuildTileQuadCache(platform, texW, texH)
    local quads = {}
    for py = 0, platform.h - 1, texH do
        for px = 0, platform.w - 1, texW do
            local drawW = math.min(texW, platform.w - px)
            local drawH = math.min(texH, platform.h - py)
            quads[#quads + 1] = {
                quad = love.graphics.newQuad(0, 0, drawW, drawH, texW, texH),
                x = px,
                y = py,
            }
        end
    end
    return quads
end

local function rebuildMeshCache(platform, texture)
    local vertices = {}
    local texW, texH = texture:getDimensions()

    for i = 1, #platform.shape, 2 do
        local vx = platform.shape[i]
        local vy = platform.shape[i + 1]
        local u = vx / texW
        local v = vy / texH
        vertices[#vertices + 1] = { vx, vy, u, v }
    end

    local mesh = love.graphics.newMesh(vertices, "fan", "static")
    mesh:setTexture(texture)
    return mesh
end

local function ensureCache(platform)
    local texture = platform.texture

    if platform.shape then
        if texture and platform._cacheTex ~= texture then
            platform._mesh = rebuildMeshCache(platform, texture)
            platform._cacheTex = texture
            if platform.tileTexture then
                texture:setWrap("repeat", "repeat")
            end
        end
        return
    end

    if texture and platform.tileTexture and not platform.isCircle then
        local texW, texH = texture:getDimensions()

        if platform._cacheTex ~= texture or platform._cacheW ~= platform.w or platform._cacheH ~= platform.h then
            texture:setWrap("repeat", "repeat")
            platform._quads = rebuildTileQuadCache(platform, texW, texH)
            platform._cacheTex = texture
            platform._cacheW = platform.w
            platform._cacheH = platform.h
        end
    end
end

---@param x number X position of the platform
---@param y number Y position of the platform
---@param w number Width of the platform
---@param h number Height of the platform
---@param color table | nil Color of the platform
---@param texture love.Image | nil (Optional) Texture of the platform
---@param tag string | nil
---@param canCollide boolean
---@param alpha number Transparency of the platform
---@param visible boolean
---@param breakable boolean
---@param breakSide "all" | "top" | "bottom" | "both" | nil
---@param onBreak function | nil
---@param tileTexture boolean If texture is larger than image, it scales or repeat
---@param layer number
---@param pushable boolean
---@return Platform
function Platform.new(x, y, w, h, color, texture, tag, canCollide, alpha, visible, breakable, breakSide, onBreak, tileTexture, layer, pushable)
    local platform = {
        x = x,
        y = y,
        w = w,
        h = h,
        color = color or { 0.3, 0.3, 0.3 },
        texture = texture,
        tag = tag or "platform",
        canCollide = (canCollide == nil) and true or canCollide,
        alpha = (alpha == nil) and 1 or alpha,
        visible = (visible == nil) and true or visible,
        breakable = (breakable == nil) and false or breakable,
        breakSide = breakSide or "bottom",
        onBreak = onBreak,
        tileTexture = (tileTexture == nil) and false or tileTexture,
        layer = layer or Platform.currentLayer,
        broken = false,
        rotation = 0,
        pushable = (pushable == nil) and false or pushable,
        cornerRadiusX = 0,
        cornerRadiusY = 0,
    }

    platform.isCircle = false
    platform.radius = 0
    platform.shape = nil
    platform.onTouch = nil

    if texture then
        texture:setFilter("nearest", "nearest")
    end
    
    ---@param ang number platform rotation angle
    function platform:setRotation(ang)
        self.rotation = ang or 0
        return self
    end

    function platform:getRotation()
        return self.rotation
    end

    ---@param num number
    function platform:setRadius(num)
        if not color and not texture then
            color = { 0,0,0 }
        end

        platform.isCircle = true
        platform.radius = num
    end

    ---@param rx number X corner radius
    ---@param ry number Y corner radius
    function platform:setCornerRadius(rx, ry)
        self.cornerRadiusX = rx or 0
        self.cornerRadiusY = ry or self.cornerRadiusX
        return self
    end

    ---@param bool boolean active/deative polygon
    function platform:setPolygon(bool)
        if bool then
            platform.isCircle = false
            platform.radius = 0

            platform.shape=makeRock(platform.w,platform.h)
            platform._mesh = nil
            platform._cacheTex = nil
        end
    end

    ---@param bool boolean active/deactive if platform is moveable
    function platform:setMoveable(bool)
        self.pushable = (bool == nil) and true or bool
        if self.pushable then
            Player.PushEvent:fire()
        end
    end

    ---@param mode "full" | "x" | "y" | nil 
    ---@param side "left" | "right" | "top" | "bottom" | nil 
    function platform:setCollision(mode, side)
        self.collisionMode = mode or "full"
        self.collisionSide = side
        return self
    end

    function platform:getCollisionRect()
        local x, y, w, h = self.x, self.y, self.w, self.h

        if self.collisionMode == "x" then
            w = w / 2
            if self.collisionSide == "right" then
                x = x + w
            end
        elseif self.collisionMode == "y" then
            h = h / 1.75
            if self.collisionSide == "bottom" then
                y = y + h
            end
        end

        return x, y, w, h
    end

    ---@param x number desired X pos
    ---@param y number desired Y pos
    ---@param duration number duration of the tween
    ---@param easingName string "linear" | "quadIn" | "quadOut" | "quadInOut" | "cubicIn" | "cubicOut" | "cubicInOut" | "backOut" | "elasticOut"
    ---@param onComplete function function that will run after tween is compelte
    ---@param looped boolean if loop will runs in loop
    function platform:tweenTo(x, y, duration, easingName, onComplete, looped)
        if platform.usedTween then return end
        if platform.activeTween then
            tween.cancel(platform.activeTween)
        end

        local easing = tween.easing[easingName] or tween.easing.linear
        local startX, startY = platform.x, platform.y

        local function run(tx, ty)
            platform.activeTween = tween.to(platform, { x = tx, y = ty }, duration, easing, function()
                platform.activeTween = nil
                if onComplete then onComplete(platform) end

                if looped then
                    if tx == x and ty == y then
                        run(startX, startY)
                    else
                        run(x, y)
                    end
                end
            end)
        end

        run(x, y)

        return platform.activeTween
    end

    ---@param w number desired width
    ---@param h number desired height
    ---@param dur number duration of the tween
    ---@param easingName "linear" | "quadIn" | "quadOut" | "quadInOut" | "cubicIn" | "cubicOut" | "cubicInOut" | "backOut" | "elasticOut"
    ---@param looped boolean if loop will runs in loop
    function platform:tweenSize(w, h, dur, easingName, looped)
        if platform.activeSizeTween then
            tween.cancel(platform.activeSizeTween)
        end

        local easing = tween.easing[easingName] or tween.easing.linear
        local startW, startH = platform.w, platform.h

        platform.activeSizeTween = tween.to(platform, { w = w, h = h }, dur, easing, function()
            platform.activeSizeTween = nil

            if looped then
                platform.activeSizeTween = tween.to(platform, { w = startW, h = startH }, dur, easing, function()
                    platform.activeSizeTween = nil
                    platform:tweenSize(w, h, dur, easingName, looped)
                end)
            end
        end)

        return platform.activeSizeTween
    end

    ---@param px number
    ---@param py number
    function platform:setPivot(px, py)
        self.pivotX = px
        self.pivotY = py
        return self
    end

    ---@param targetRotation number Desired rotation of the tween
    ---@param duration number Duration of the tween
    ---@param easingName "linear" | "quadIn" | "quadOut" | "quadInOut" | "cubicIn" | "cubicOut" | "cubicInOut" | "backOut" | "elasticOut"
    ---@param onComplete function function that will runs after the tween
    function platform:tweenRotation(targetRotation, duration, easingName, onComplete)
        if platform.activeRotationTween then
            tween.cancel(platform.activeRotationTween)
        end

        local easing = tween.easing[easingName] or tween.easing.linear

        platform.activeRotationTween = tween.to(platform, { rotation = targetRotation }, duration, easing, function()
            platform.activeRotationTween = nil
            if onComplete then onComplete(platform) end
        end)

        return platform.activeRotationTween
    end
    
    ---@param n number Platform layer
    function platform:setLayer(n)
        platform.layer = n
    end

    function platform:getLayer()
        return platform.layer
    end

    ---@param color table Platform stroke color
    function platform:setStroke(color)
        self.stroke = true
        local c = color or {1, 1, 1, 1}
        self.strokeColor = { c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1 }
        return self
    end

    table.insert(Platform.list, platform)
    Platform._sortedDirty = true
    return platform
end

--- @param platform Platform
---@param newTexturePath string
function Platform.changeTexture(platform, newTexturePath)
    local newTexture = love.graphics.newImage(newTexturePath)
    newTexture:setFilter("nearest", "nearest")
    platform.texture = newTexture
end

local function stencilFunctionFor(platform, radius)
    love.graphics.circle("fill", platform.texture:getWidth() / 2, platform.texture:getHeight() / 2, radius)
end

local function drawCircleTexture(platform, radius)
    love.graphics.push()
    love.graphics.translate(platform.x, platform.y)
    love.graphics.stencil(function() stencilFunctionFor(platform, radius) end, "replace", 1)
    love.graphics.setStencilTest("greater", 0)
    love.graphics.draw(platform.texture, 0, 0)
    love.graphics.setStencilTest()
    love.graphics.pop()
end

local function stencilRoundedRectFor(platform, rx, ry)
    love.graphics.rectangle("fill", 0, 0, platform.w, platform.h, rx, ry)
end

local function drawRoundedTexture(platform, rx, ry)
    love.graphics.push()
    love.graphics.translate(platform.x, platform.y)
    love.graphics.stencil(function() stencilRoundedRectFor(platform, rx, ry) end, "replace", 1)
    love.graphics.setStencilTest("greater", 0)

    if platform.tileTexture then
        for _, q in ipairs(platform._quads) do
            love.graphics.draw(platform.texture, q.quad, q.x, q.y)
        end
    else
        local texW, texH = platform.texture:getDimensions()
        local scaleX = platform.w / texW
        local scaleY = platform.h / texH
        love.graphics.draw(platform.texture, 0, 0, 0, scaleX, scaleY)
    end

    love.graphics.setStencilTest()
    love.graphics.pop()
end

local function drawSinglePlatform(platform)
    ensureCache(platform)

    local a = platform.alpha or 1
    local rotated = (platform.rotation and platform.rotation ~= 0)
    local radius = platform.radius or 0
    local cx, cy = platform.x + platform.w / 2, platform.y + platform.h / 2
    local isCirc = platform.isCircle and platform.radius >= 1
    local hasCorner = ((platform.cornerRadiusX or 0) > 0 or (platform.cornerRadiusY or 0) > 0)

    local ox, oy = cx, cy
    if platform.pivotX then
        ox, oy = platform.x + platform.pivotX, platform.y + platform.pivotY
    end

    if rotated then
        love.graphics.push()
        love.graphics.translate(ox, oy)
        love.graphics.rotate(platform.rotation)
        love.graphics.translate(-ox, -oy)
    end

    if platform.shape then
        if platform.texture and platform._mesh then
            love.graphics.setColor(1, 1, 1, a)
            love.graphics.push()
            love.graphics.translate(platform.x, platform.y)
            love.graphics.draw(platform._mesh)
            love.graphics.pop()
        else
            local points = {}
            for i = 1, #platform.shape, 2 do
                points[#points + 1] = platform.x + platform.shape[i]
                points[#points + 1] = platform.y + platform.shape[i+1]
            end
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.polygon("fill", points)
        end
    else
        if platform.texture then
            love.graphics.setColor(1, 1, 1, a)

            if isCirc then
                drawCircleTexture(platform, radius)
            elseif hasCorner then
                drawRoundedTexture(platform, platform.cornerRadiusX, platform.cornerRadiusY)
            elseif platform.tileTexture then
                love.graphics.push()
                love.graphics.translate(platform.x, platform.y)
                for _, q in ipairs(platform._quads) do
                    love.graphics.draw(platform.texture, q.quad, q.x, q.y)
                end
                love.graphics.pop()
            else
                local texW, texH = platform.texture:getDimensions()
                local scaleX = platform.w / texW
                local scaleY = platform.h / texH

                if platform.stroke then
                    OutlineShader:send("texSize", { texW, texH })
                    OutlineShader:send("outlineColor", platform.strokeColor)
                    love.graphics.setShader(OutlineShader)
                end

                love.graphics.draw(platform.texture, platform.x, platform.y, 0, scaleX, scaleY)

                if platform.stroke then
                    love.graphics.setShader()
                end
            end
        else
            local c = platform.color
            love.graphics.setColor(c[1], c[2], c[3], a)

            if isCirc then
                love.graphics.circle("fill", platform.x, platform.y, platform.radius)
            elseif hasCorner then
                love.graphics.rectangle("fill", platform.x, platform.y, platform.w, platform.h, platform.cornerRadiusX, platform.cornerRadiusY)
            else
                love.graphics.rectangle("fill", platform.x, platform.y, platform.w, platform.h)
            end
        end

        love.graphics.setColor(1, 1, 1, 1)
    end

    if rotated then
        love.graphics.pop()
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function Platform.draw()
    if Platform._sortedDirty then
        local sortedPlatforms = {}
        for _, platform in ipairs(Platform.list) do
            sortedPlatforms[#sortedPlatforms + 1] = platform
        end

        table.sort(sortedPlatforms, function(a, b)
            return (a.layer or 1) < (b.layer or 1)
        end)

        Platform._sortedList = sortedPlatforms
        Platform._sortedDirty = false
    end

    local viewX, viewY, viewW, viewH = 0, 0, math.huge, math.huge
    if Camera then
        local scale = Camera.scale or 1
        viewX = Camera.x or 0
        viewY = Camera.y or 0
        viewW = BASE_WIDTH and (BASE_WIDTH / scale) or math.huge
        viewH = BASE_HEIGHT and (BASE_HEIGHT / scale) or math.huge
    end
    local margin = 64
    local minX, minY = viewX - margin, viewY - margin
    local maxX, maxY = viewX + viewW + margin, viewY + viewH + margin

    for _, platform in ipairs(Platform._sortedList) do
        if platform.visible ~= false
        and platform.x < maxX and platform.x + platform.w > minX
        and platform.y < maxY and platform.y + platform.h > minY then
            drawSinglePlatform(platform)
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function Platform.drawPlatform(target)
    local platform = target

    if type(target) == "string" then
        platform = Platform.getPlatformByTag(target)
    end

    if not platform or platform.visible == false then return end

    drawSinglePlatform(platform)
end

---@param target number | "Platform"
function Platform.destroy(target)
    if type(target) == "number" then
        local platform = Platform.list[target]
        if platform then
            if platform.broken then return end

            if platform.onBreak then
                platform.broken = true
                platform.onBreak(platform) 
            end
        end
        return
    end

    for i, platform in ipairs(Platform.list) do
        if platform == target then
            if platform.broken then return end
            
            if platform.onBreak then
                platform.broken = true
                platform.onBreak(platform) 
            end
            return
        end
    end
end

---@param tag Platform | string
function Platform.getPlatformByTag(tag)
    if type(tag) ~= "string" then
        return
    end

    for _, platform in ipairs(Platform.list) do
        if platform.tag == tag then
            return platform
        end
    end

    return nil
end

---Returns the bounding box (minX, minY, maxX, maxY) of all platforms
function Platform.getBounds()
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge

    for _, p in ipairs(Platform.list) do
        minX = math.min(minX, p.x)
        minY = math.min(minY, p.y)
        maxX = math.max(maxX, p.x + p.w)
        maxY = math.max(maxY, p.y + p.h)
    end

    return minX, minY, maxX, maxY
end

function Platform.clear()
    Platform.list = {}
    Platform._sortedList = {}
    Platform._sortedDirty = true
end

return Platform