local Vec2 = {}

function Vec2.new(x, y)
    return { x = x or 0, y = y or 0 }
end

function Vec2.add(a, b)
    return { x = a.x + b.x, y = a.y + b.y }
end

function Vec2.sub(a, b)
    return { x = a.x - b.x, y = a.y - b.y }
end

function Vec2.mul(a, s)
    return { x = a.x * s, y = a.y * s }
end

function Vec2.len(a)
    return math.sqrt(a.x * a.x + a.y * a.y)
end

function Vec2.norm(a)
    local l = Vec2.len(a)
    if l == 0 then return { x = 0, y = 0 } end
    return { x = a.x / l, y = a.y / l }
end

function Vec2.lerp(a, b, t)
    return {
        x = a.x + (b.x - a.x) * t,
        y = a.y + (b.y - a.y) * t
    }
end

return Vec2