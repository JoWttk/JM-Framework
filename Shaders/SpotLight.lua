local SpotLight = {}

SpotLight.Radius = 190
SpotLight.Softness = 150
SpotLight.FowardOffset = 55
SpotLight.MaxDarkness = 0.92

local SL

function SpotLight.load()
    if SL then return end

    SL = love.graphics.newShader("engine/Shaders/Templates/SpotLight.glsl")
end

function SpotLight.remove()
    if not SL then return end

    love.graphics.setShader()
    SL:release()
    SL = nil
end

function SpotLight.draw(worldX, worldY, facing, camera)
    if not SL then return end
    if not camera then return end

    facing = facing or 1
    local scale = camera.scale or 1

    local screenX = (worldX + facing * SpotLight.FowardOffset - camera.x) * scale
    local screenY = (worldY - camera.y) * scale

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setShader(SL)

    SL:send("lightPos", { screenX, screenY })
    SL:send("lightRadius", SpotLight.Radius * scale)
    SL:send("lightSoftness", SpotLight.Softness * scale)
    SL:send("maxDarkness", SpotLight.MaxDarkness)

    love.graphics.rectangle("fill", 0, 0, BASE_WIDTH, BASE_HEIGHT)

    love.graphics.setShader()
    love.graphics.setColor(1, 1, 1, 1)
end

return SpotLight