local Dissolve = {}

local shader = love.graphics.newShader("engine/Shaders/Templates/Dissolve.glsl")

Dissolve.shader     = shader
Dissolve.duration   = 0.2
Dissolve.edgeColor  = {1, 1,1}
Dissolve.edgeWidth  = 0.12

local particleImg

local function getParticleImg()
    if particleImg then return particleImg end

    local canvas = love.graphics.newCanvas(4, 4)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.circle("fill", 2, 2, 2)
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1, 1)

    particleImg = love.graphics.newImage(canvas:newImageData())
    return particleImg
end

function Dissolve.begin(entity)
    entity.dissolveProgress = 0

    local ps = love.graphics.newParticleSystem(getParticleImg(), 200)
    ps:setParticleLifetime(0.4, 0.9)
    ps:setEmissionRate(0)
    ps:setSizes(1.4, 0.7, 0.1)
    ps:setLinearAcceleration(-40, -260, 40, -140)
    ps:setSpeed(60, 140)
    ps:setSpread(math.pi * 2)
    ps:setColors(
        Dissolve.edgeColor[1], Dissolve.edgeColor[2], Dissolve.edgeColor[3], 1,
        Dissolve.edgeColor[1], Dissolve.edgeColor[2], Dissolve.edgeColor[3], 0.6,
        Dissolve.edgeColor[1] * 0.6, Dissolve.edgeColor[2] * 0.6, Dissolve.edgeColor[3] * 0.6, 0
    )
    ps:setLinearDamping(0.1, 0.3)

    entity.dissolvePS = ps
end

function Dissolve.update(entity, dt)
    entity.dissolveProgress = entity.dissolveProgress + dt / Dissolve.duration

    if entity.dissolvePS then
        if entity.dissolveProgress < 1 then
            local w = entity.width  or 32
            local h = entity.height or 32

            local burstChance = 3
            for i = 1, burstChance do
                local px = entity.x + math.random() * w
                local py = entity.y + math.random() * h
                entity.dissolvePS:setPosition(px, py)
                entity.dissolvePS:emit(1)
            end
        end

        entity.dissolvePS:update(dt)
    end

    local psAlive = entity.dissolvePS and entity.dissolvePS:getCount() > 0
    return entity.dissolveProgress >= 1 and not psAlive
end

function Dissolve.set(entity)
    shader:send("progress", math.min(entity.dissolveProgress, 1))
    shader:send("edgeColor", Dissolve.edgeColor)
    shader:send("edgeWidth", Dissolve.edgeWidth)
end

function Dissolve.drawParticles(entity)
    if entity.dissolvePS then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(entity.dissolvePS)
    end
end

return Dissolve