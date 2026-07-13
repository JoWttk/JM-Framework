local TextBox = {}

function TextBox:new(x, y, width, height, fontPath, fontSize, textColor, bgColor)
    local obj = {}
    setmetatable(obj, self)
    self.__index = self

    obj.x = x
    obj.y = y
    obj.width = width
    obj.height = height
    obj.text = ""
    obj.font = love.graphics.newFont(fontPath, fontSize)
    obj.textColor = textColor
    obj.bgColor = bgColor
    obj.isActive = false

    return obj
end

return TextBox