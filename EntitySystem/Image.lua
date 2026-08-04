local tween = require "engine.Utils.tween"
---@class Image
---@field image love.Image The loaded image
---@field x number X position
---@field y number Y position
---@field width number Image width
---@field height number Image height
---@field scale number Display scale
---@field alpha number Display opacity (0-1)
local Image = {}

Image.list = {}

---Create a new image object
---@param path string|love.Image File path or image object
---@param x number X position
---@param y number Y position
---@param width number Image width
---@param height number Image height
---@param scale number Display scale
---@return Image
function Image.new(path, x, y, width, height, scale)
    local image

    if type(path) == "string" then
        image = love.graphics.newImage(path)
    else
        image = path
    end

    local img = {
        image = image,
        x = x,
        y = y,
        width = width,
        height = height,
        scale = scale,
        alpha = 1,
        baseScale = scale,
    }
    img.activeTween = nil
    img.visTween = nil
    img.visible = true

    function img:setTween(x, y, duration, easingName, onComplete, looped)
        if self.activeTween then
            tween.cancel(self.activeTween)
        end

        local easing = tween.easing[easingName] or tween.easing.linear
        local startX, startY = img.x, img.y

        local function run(tx, ty)
            img.activeTween = tween.to(img, { x = tx, y = ty }, duration, easing, function()
                img.activeTween = nil
                if onComplete then onComplete(img) end

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

        return self
    end

    ---@param duration number|nil
    ---@param onComplete function|nil callback opcional após sumir
    function img:hide(duration, onComplete)
        if not self.visible then return end
        self.visible = false

        if self.visTween then
            tween.cancel(self.visTween)
        end

        self.visTween = tween.to(self, { scale = 0, alpha = 0 }, duration or 0.23, tween.easing.quadIn, function()
            self.visTween = nil
            for i, v in ipairs(Image.list) do
                if v == self then
                    table.remove(Image.list, i)
                    break
                end
            end
            if onComplete then onComplete(self) end
        end)
    end

    ---Anima o "pop" de entrada e garante que está na lista
    ---@param duration number|nil
    ---@param onComplete function|nil
    function img:show(duration, onComplete)
        if self.visible then return end
        self.visible = true

        if self.visTween then
            tween.cancel(self.visTween)
        end

        local alreadyIn = false
        for _, v in ipairs(Image.list) do
            if v == self then alreadyIn = true break end
        end
        if not alreadyIn then
            self.scale = 0
            self.alpha = 0
            table.insert(Image.list, self)
        end

        self.visTween = tween.to(self, { scale = self.baseScale, alpha = 1 }, duration or 0.5, tween.easing.backOut, function()
            self.visTween = nil
            if onComplete then onComplete(self) end
        end)
    end

    table.insert(Image.list, img)
    return img
end

---Draw all images
function Image.draw()
    for _, img in ipairs(Image.list) do
        love.graphics.setColor(1, 1, 1, img.alpha or 1)

        local ox = img.width / 2
        local oy = img.height / 2

        love.graphics.draw(
            img.image,
            img.x + ox * (img.scale or 1),
            img.y + oy * (img.scale or 1),
            0,
            img.scale or 1,
            img.scale or 1,
            ox,
            oy
        )
    end
    love.graphics.setColor(1, 1, 1, 1)
end

---Clear all images
function Image.clear()
    Image.list = {}
end

return Image