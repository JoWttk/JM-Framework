---@class Image
---@field image love.Image The loaded image
---@field x number X position
---@field y number Y position
---@field width number Image width
---@field height number Image height
---@field scale number Display scale
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
        scale = scale
    }

    table.insert(Image.list, img)
    return img
end

---Draw all images
function Image.draw()
    for _, img in ipairs(Image.list) do
        love.graphics.draw(img.image, img.x, img.y, 0, img.scale or 1, img.scale or 1)
    end
end

---Clear all images
function Image.clear()
    Image.list = {}
end

return Image