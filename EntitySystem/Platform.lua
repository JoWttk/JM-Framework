local tween = require "engine.Utils.tween"
local Camera = require "engine.EntitySystem.Camera"
local Platform = {}

Platform.list = {}
Platform.currentLayer = 1

Platform._sortedDirty = true
Platform._sortedList = {}

-- layer 0 = background
-- layer 1 = gameplay
-- layer 1+ = foreground / gameplay / ui

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

function Platform.new(x, y, w, h, color, texture, tag, canCollide, alpha, visible, breakable, breakSide, onBreak, tileTexture, layer, pushable)
    local Player = require("entities.Player")
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

    if texture then
        texture:setFilter("nearest", "nearest")
    end

    --[[
    CanCollide = false/true,
    alpha 0 = invisible, 1 = fully visible,
    visible = true/false,
    breakSide = "bottom" | "top" | "both" | "all"
      - "bottom" = quebra ao tocar de baixo
      - "top" = quebra ao tocar de cima
      - "both" = quebra ao tocar de cima ou de baixo
      - "all" = quebra em qualquer direção (top, bottom, left, right)
    tileTexture = true  -> repete a textura (chao, parede, etc)
                = false -> escala a textura inteira pro tamanho do platform (sprite unico, ex: arvore)
    rotation = radianos, rotaciona em torno do centro do platform (apenas visual, não afeta a colisão AABB)
    pushable = true/false, se a plataforma pode ser empurrada pelo player
    cornerRadiusX/Y = arredondamento visual dos cantos (apenas visual, não afeta a colisão AABB)
    ]]

    function platform:setRotation(ang)
        self.rotation = ang or 0
        return self
    end

    function platform:getRotation()
        return self.rotation
    end

    function platform:setRadius(num)
        if not color and not texture then
            color = { 0,0,0 }
        end

        platform.isCircle = true
        platform.radius = num
    end

    function platform:setCornerRadius(rx, ry)
        self.cornerRadiusX = rx or 0
        self.cornerRadiusY = ry or self.cornerRadiusX
        return self
    end

    function platform:setPolygon(bool)
        if bool then
            platform.isCircle = false
            platform.radius = 0

            platform.shape=makeRock(platform.w,platform.h)
            platform._mesh = nil
            platform._cacheTex = nil
        end
    end

    function platform:setMoveable(bool)
        self.pushable = (bool == nil) and true or bool
        if self.pushable then
            Player.PushEvent:fire()
        end
    end

    function platform:tweenTo(x,y,duration,easingName,onComplete)
        if platform.usedTween then return end
        if platform.activeTween then
            tween.cancel(platform.activeTween)
        end

        local easing = tween.easing[easingName] or tween.easing.linear

        platform.activeTween = tween.to(platform, { x = x, y = y }, duration, easing, function()
            platform.activeTween = nil
            if onComplete then onComplete(platform) end
        end)

        return platform.activeTween
    end

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

    function platform:setPivot(px, py)
        self.pivotX = px
        self.pivotY = py
        return self
    end

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
    
    function platform:setLayer(n)
        platform.layer = n
    end

    function platform:getLayer()
        return platform.layer
    end

    table.insert(Platform.list, platform)
    Platform._sortedDirty = true
    return platform
end

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
                love.graphics.draw(platform.texture, platform.x, platform.y, 0, scaleX, scaleY)
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
        if Platform.debug then
            love.graphics.setColor(0, 1, 0, 0.4)
            if hasCorner then
                love.graphics.rectangle("line", platform.x, platform.y, platform.w, platform.h, platform.cornerRadiusX, platform.cornerRadiusY)
            else
                love.graphics.rectangle("line", platform.x, platform.y, platform.w, platform.h)
            end
            love.graphics.setColor(1, 1, 1, 1)
        end
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

function Platform.destroy(target)
    if type(target) == "number" then
        local platform = Platform.list[target]
        if platform then
            if platform.broken then return end

            if platform.onBreak then
                platform.broken = true
                platform.onBreak(platform) 
            end
            -- table.remove(Platform.list, target)
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
            -- table.remove(Platform.list, i)
            return
        end
    end
end

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

function Platform.clear()
    Platform.list = {}
    Platform._sortedList = {}
    Platform._sortedDirty = true
end

return Platform