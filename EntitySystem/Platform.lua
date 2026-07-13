local tween = require "engine.Utils.tween"
local Platform = {}

Platform.list = {}
Platform.currentLayer = 1

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

    function platform:setPolygon(bool)
        if bool then
            platform.isCircle = false
            platform.radius = 0

            platform.shape=makeRock(platform.w,platform.h)
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

    table.insert(Platform.list, platform)
    return platform
end

function Platform.changeTexture(platform, newTexturePath)
    local newTexture = love.graphics.newImage(newTexturePath)
    newTexture:setFilter("nearest", "nearest")
    platform.texture = newTexture
end

function Platform.draw()
    local sortedPlatforms = {}
    for _, platform in ipairs(Platform.list) do
        if platform.visible ~= false then
            table.insert(sortedPlatforms, platform)
        end
    end

    table.sort(sortedPlatforms, function(a, b)
        return (a.layer or 1) < (b.layer or 1)
    end)

    for _, platform in ipairs(sortedPlatforms) do
        local a = platform.alpha or 1
        local rotated = (platform.rotation and platform.rotation ~= 0)
        local radius = platform.radius or 0
        local cx, cy = platform.x + platform.w / 2, platform.y + platform.h / 2

        local function stencilFunction()
            if platform.isCircle and platform.radius >= 1 then
                love.graphics.circle("fill", platform.texture:getWidth()/2, platform.texture:getHeight()/2, radius)
            end
        end

        local function detectCircle()
            if platform.isCircle and platform.radius >= 1 then
                return true
            end
        end

        local function makeCircle()
            love.graphics.push()
            love.graphics.translate(platform.x, platform.y)
            love.graphics.stencil(stencilFunction, "replace", 1)
            love.graphics.setStencilTest("greater",0)
            love.graphics.draw(platform.texture, 0,0)
            love.graphics.setStencilTest()
            love.graphics.pop()
        end

        if rotated then
            love.graphics.push()
            love.graphics.translate(cx, cy)
            love.graphics.rotate(platform.rotation)
            love.graphics.translate(-cx, -cy)
        end

        if platform.shape then
            if platform.texture then
                local vertices = {}
                local texW, texH = platform.texture:getDimensions()

                for i = 1, #platform.shape, 2 do
                    local vx = platform.shape[i]
                    local vy = platform.shape[i+1]

                    local u = vx / texW
                    local v = vy / texH

                    table.insert(vertices,{platform.x+vx,platform.y+vy,u,v})
                end

                local mesh = love.graphics.newMesh(vertices, "fan", "dynamic")
                mesh:setTexture(platform.texture)

                if platform.tileTexture then
                    platform.texture:setWrap("repeat", "repeat")
                end

                love.graphics.setColor(1,1,1,a)
                love.graphics.draw(mesh)
            else
                local points = {}

                for i = 1,#platform.shape,2 do
                    table.insert(points,platform.x+platform.shape[i])
                    table.insert(points,platform.y+platform.shape[i+1])
                end
                love.graphics.polygon("fill", points)
            end
        else
            if platform.texture then
                love.graphics.setColor(1, 1, 1, a)

                if platform.tileTexture then
                    platform.texture:setWrap("repeat", "repeat")

                    local texW, texH = platform.texture:getDimensions()
                    local isCirc = detectCircle()

                    if isCirc then
                        makeCircle()
                    else
                        for px = 0, platform.w - 1, texW do
                            for py = 0, platform.h - 1, texH do
                                local drawW = math.min(texW, platform.w - px)
                                local drawH = math.min(texH, platform.h - py)

                                local quad = love.graphics.newQuad(0, 0, drawW, drawH, texW, texH)
                                love.graphics.draw(platform.texture, quad, platform.x + px, platform.y + py)
                            end
                        end
                    end
                else
                    local texW, texH = platform.texture:getDimensions()
                    local scaleX = platform.w / texW
                    local scaleY = platform.h / texH

                    if detectCircle() then
                        makeCircle()
                    else
                        love.graphics.draw(platform.texture, platform.x, platform.y, 0, scaleX, scaleY)
                    end
                end
            else
                local c = platform.color
                love.graphics.setColor(c[1], c[2], c[3], a)

                if platform.isCircle and platform.radius >= 1 then
                    love.graphics.circle("fill", platform.x, platform.y, platform.radius)
                else
                    love.graphics.rectangle("fill", platform.x, platform.y, platform.w, platform.h)
                end
            end

            love.graphics.setColor(1, 1, 1, 1)
            if Platform.debug then
                love.graphics.setColor(0, 1, 0, 0.4)
                love.graphics.rectangle("line", platform.x, platform.y, platform.w, platform.h)
                love.graphics.setColor(1, 1, 1, 1)
            end
        end

        if rotated then
            love.graphics.pop()
        end
    end
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
end

return Platform