local Grayscale = {}

function Grayscale.applyShader()
    local shader = love.graphics.newShader("engine/Shaders/Templates/Grayscale.glsl")
    shader:send("intensity", 1.0)
    
    love.graphics.setShader(shader)
end

function Grayscale.removeShader()
    love.graphics.setShader()
end

return Grayscale