local Blackout = {}

Blackout.shader = love.graphics.newShader("engine/Shaders/Templates/Blackout.glsl")
Blackout.active = false
Blackout.radius = 1.5
Blackout.maxRadius = 1.5
Blackout.minRadius = 0
Blackout.closeSpeed = 0.5
Blackout.openSpeed = 1.2

function Blackout.close()
    Blackout.active = true
end

function Blackout.open()
    Blackout.active = false
end

function Blackout.update(dt)
    if Blackout.active then
        Blackout.radius = math.max(Blackout.radius - Blackout.closeSpeed * dt, Blackout.minRadius)
    else
        Blackout.radius = math.min(Blackout.radius + Blackout.openSpeed * dt, Blackout.maxRadius)
    end
end

function Blackout.apply()
    local w, h = love.graphics.getDimensions()
    Blackout.shader:send("radius", Blackout.radius)
    Blackout.shader:send("center", {0.5, 0.5})
    Blackout.shader:send("aspect", w / h)
    love.graphics.setShader(Blackout.shader)
end

function Blackout.unset()
    love.graphics.setShader()
end

function Blackout.isFullyClosed()
    return Blackout.radius <= Blackout.minRadius
end

return Blackout