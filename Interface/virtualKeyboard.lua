local VirtualKeyboard = {}
VirtualKeyboard.__index = VirtualKeyboard

local function clamp(v, a, b)
    if v < a then return a end
    if v > b then return b end
    return v
end

local LAYOUT = {
    { "A","B","C","D","E","F","G","H","I","J" },
    { "K","L","M","N","O","P","Q","R","S","T" },
    { "U","V","W","X","Y","Z","0","1","2","3" },
    { "4","5","6","7","8","9" },
    { "BACKSPACE" }
}

function VirtualKeyboard.new(opts)
    opts = opts or {}
    local self = setmetatable({}, VirtualKeyboard)

    self.layout = LAYOUT
    self.maxLen = opts.maxLen or 12
    self.text = opts.text or ""
    self.active = false

    self.row = 1
    self.col = 1

    self.keyW = 48
    self.keyH = 36
    self.gap = 8

    self._repeatDelay = 0.22
    self._repeatRate = 0.07
    self._held = { up=false, down=false, left=false, right=false }
    self._tHeld = { up=0, down=0, left=0, right=0 }

    self.keys = {}
    self:_recalc()

    return self
end

function VirtualKeyboard:_recalc()
    local maxCols = 10
    local width = maxCols * self.keyW + (maxCols - 1) * self.gap
    self.x = BASE_WIDTH / 2 - width / 2
    self.y = BASE_HEIGHT / 2 - 120

    self.keys = {}

    for r = 1, #self.layout do
        local row = self.layout[r]
        for c = 1, #row do
            local key = row[c]

            local w = self.keyW
            if key == "BACKSPACE" then
                w = self.keyW * 4 + self.gap * 3
            end

            local x = self.x + (c - 1) * (self.keyW + self.gap)
            local y = self.y + (r - 1) * (self.keyH + self.gap)

            self.keys[#self.keys + 1] = {
                key = key,
                row = r,
                col = c,
                x = x,
                y = y,
                w = w,
                h = self.keyH
            }
        end
    end
end

function VirtualKeyboard:open(text)
    self.active = true
    self.text = text or ""
    self.row, self.col = 1, 1
    self:_recalc()
end

function VirtualKeyboard:close()
    self.active = false
end

function VirtualKeyboard:isOpen()
    return self.active
end

function VirtualKeyboard:_rowLen(r)
    return #(self.layout[r] or {})
end

function VirtualKeyboard:_currentKey()
    local r = self.layout[self.row]
    if not r then return nil end
    return r[self.col]
end

function VirtualKeyboard:_move(dx, dy)
    local nr = clamp(self.row + dy, 1, #self.layout)
    local len = self:_rowLen(nr)
    if len == 0 then return end

    local nc = clamp(self.col + dx, 1, len)
    self.row = nr
    self.col = nc
end

function VirtualKeyboard:_applyKey(key)
    if not key then return end

    if key == "BACKSPACE" then
        self.text = self.text:sub(1, math.max(0, #self.text - 1))
        return
    end

    if #self.text < self.maxLen then
        self.text = self.text .. key
    end
end

function VirtualKeyboard:_hit(x, y)
    for i = 1, #self.keys do
        local k = self.keys[i]
        if x >= k.x and x <= k.x + k.w and y >= k.y and y <= k.y + k.h then
            return k
        end
    end
    return nil
end

function VirtualKeyboard:mousemoved(x, y)
    if not self.active then return false end

    local k = self:_hit(x, y)
    if not k then return false end

    self.row = k.row
    self.col = k.col
    return true
end

function VirtualKeyboard:mousepressed(x, y, button)
    if not self.active then return false end
    if button ~= 1 then return false end

    local k = self:_hit(x, y)
    if not k then return false end

    self.row = k.row
    self.col = k.col
    self:_applyKey(k.key)
    return true
end

function VirtualKeyboard:keypressed(key)
    if not self.active then return false end

    if key == "up" then self._held.up = true self:_move(0, -1) return true end
    if key == "down" then self._held.down = true self:_move(0,  1) return true end
    if key == "left" then self._held.left = true self:_move(-1, 0) return true end
    if key == "right" then self._held.right = true self:_move( 1, 0) return true end

    if key == "return" or key == "space" or key == "z" then
        self:_applyKey(self:_currentKey())
        return true
    end

    if key == "backspace" then
        self:_applyKey("BACKSPACE")
        return true
    end

    return false
end

function VirtualKeyboard:keyreleased(key)
    if key == "up" then self._held.up = false end
    if key == "down" then self._held.down = false end
    if key == "left" then self._held.left = false end
    if key == "right" then self._held.right = false end
end

function VirtualKeyboard:update(dt)
    if not self.active then return end

    local function held(dir, dx, dy)
        if not self._held[dir] then
            self._tHeld[dir] = 0
            return
        end

        self._tHeld[dir] = self._tHeld[dir] + dt
        if self._tHeld[dir] >= self._repeatDelay then
            local t = self._tHeld[dir] - self._repeatDelay
            while t >= self._repeatRate do
                self:_move(dx, dy)
                t = t - self._repeatRate
            end
            self._tHeld[dir] = self._repeatDelay + t
        end
    end

    held("up", 0, -1)
    held("down", 0, 1)
    held("left", -1, 0)
    held("right", 1, 0)
end

function VirtualKeyboard:draw()
    if not self.active then return end

    love.graphics.rectangle("line", self.x, self.y - 56, 420, 40)
    love.graphics.print(self.text, self.x + 10, self.y - 48)

    for i = 1, #self.keys do
        local k = self.keys[i]
        if k.row == self.row and k.col == self.col then
            love.graphics.rectangle("line", k.x - 3, k.y - 3, k.w + 6, k.h + 6)
        end
        love.graphics.rectangle("line", k.x, k.y, k.w, k.h)
        love.graphics.printf(k.key, k.x, k.y + 10, k.w, "center")
    end
end

return VirtualKeyboard