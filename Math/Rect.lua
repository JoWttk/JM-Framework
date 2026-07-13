local Rect = {}

function Rect.new(x, y, w, h)
    return { x = x or 0, y = y or 0, w = w or 0, h = h or 0 }
end

function Rect.intersects(a, b)
    return a.x < b.x + b.w and
           a.x + a.w > b.x and
           a.y < b.y + b.h and
           a.y + a.h > b.y
end

function Rect.containsPoint(r, px, py)
    return px >= r.x and px <= r.x + r.w and py >= r.y and py <= r.y + r.h
end

function Rect.resolve(a, b)
    local axc = a.x + a.w * 0.5
    local ayc = a.y + a.h * 0.5
    local bxc = b.x + b.w * 0.5
    local byc = b.y + b.h * 0.5

    local dx = axc - bxc
    local dy = ayc - byc

    local px = (a.w * 0.5 + b.w * 0.5) - math.abs(dx)
    local py = (a.h * 0.5 + b.h * 0.5) - math.abs(dy)

    if px <= 0 or py <= 0 then
        return 0, 0, 0, 0
    end

    if px < py then
        local sx = dx < 0 and -1 or 1
        return px * sx, 0, sx, 0
    else
        local sy = dy < 0 and -1 or 1
        return 0, py * sy, 0, sy
    end
end

return Rect