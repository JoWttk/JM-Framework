local Bar = {}

local function clamp(v, a, b)
	if v < a then return a end
	if v > b then return b end
	return v
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function easeOutQuad(t)
	return 1 - (1 - t) * (1 - t)
end

function Bar.new(params)
	params = params or {}
	local self = {}

	self.current = clamp(params.percent or 0, 0, 1)
	self.start = self.current
	self.target = self.current
	self.tweenDuration = params.tweenDuration or 0.3
	self.tweenElapsed = 0
	self.tweening = false

	self.fgColor = params.fgColor or {0.2, 0.7, 0.2, 1}
	self.bgColor = params.bgColor or {0.15, 0.15, 0.15, 1}
	self.borderColor = params.borderColor or {0, 0, 0, 1}
	self.borderWidth = params.borderWidth or 2

	self.showText = params.showText == nil and true or params.showText
	self.font = params.font
	self.label = params.label or ""
	self.labelStroke = params.labelStroke or 2
	self.width = params.width or 200
	self.height = params.height or 20
	self.padding = params.padding or 2

	function self:setPercent(p, duration)
		p = clamp(p or 0, 0, 1)
		duration = (duration == nil) and self.tweenDuration or duration
		if duration and duration > 0 then
			self.start = self.current
			self.target = p
			self.tweenDuration = duration
			self.tweenElapsed = 0
			self.tweening = true
		else
			self.current = p
			self.start = p
			self.target = p
			self.tweening = false
		end
	end

	function self:setValue(value, max, duration)
		max = max or 1
		local p = 0
		if max ~= 0 then p = value / max end
		self:setPercent(p, duration)
	end

	function self:instant(p)
		self.current = clamp(p or 0, 0, 1)
		self.start = self.current
		self.target = self.current
		self.tweening = false
	end

	function self:update(dt)
		if self.tweening then
			self.tweenElapsed = self.tweenElapsed + dt
			local t = clamp(self.tweenElapsed / math.max(1e-6, self.tweenDuration), 0, 1)
			local et = easeOutQuad(t)
			self.current = lerp(self.start, self.target, et)
			if t >= 1 then
				self.tweening = false
				self.current = self.target
			end
		end
	end

	function self:draw(x, y, w, h)
		w = w or self.width
		h = h or self.height

		local pad = self.padding

		love.graphics.setColor(self.bgColor)
		love.graphics.rectangle("fill", x, y, w, h)

		local innerW = (w - pad * 2) * clamp(self.current, 0, 1)
		love.graphics.setColor(self.fgColor)
		love.graphics.rectangle("fill", x + pad, y + pad, innerW, h - pad * 2)

		-- border
		if self.borderWidth and self.borderWidth > 0 then
			love.graphics.setLineWidth(self.borderWidth)
			love.graphics.setColor(self.borderColor)
			love.graphics.rectangle("line", x, y, w, h)
		end

		-- text overlay (percent)
		if self.showText then
			local percentText = string.format("%d%%", math.floor(self.current * 100 + 0.5))
			if self.font then love.graphics.setFont(self.font) end
			local tw = love.graphics.getFont():getWidth(percentText)
			local th = love.graphics.getFont():getHeight()
			love.graphics.setColor(1,1,1,1)
			love.graphics.print(percentText, x + (w - tw) / 2, y + (h - th) / 2)
		end

		if self.labelStroke and self.labelStroke > 0 and self.label and #self.label > 0 then
			if self.font then love.graphics.setFont(self.font) end
			love.graphics.setColor(0,0,0,1)
			for dx = -self.labelStroke, self.labelStroke, self.labelStroke do
				for dy = -self.labelStroke, self.labelStroke, self.labelStroke do
					if dx ~= 0 or dy ~= 0 then
						love.graphics.print(self.label, x - 4 - love.graphics.getFont():getWidth(self.label) + dx, y + (h - love.graphics.getFont():getHeight()) / 2 + dy)
					end
				end
			end
		end

		-- label (left)
		if self.label and #self.label > 0 then
			if self.font then love.graphics.setFont(self.font) end
			love.graphics.setColor(1,1,1,1)
			love.graphics.print(self.label, x - 4 - love.graphics.getFont():getWidth(self.label), y + (h - love.graphics.getFont():getHeight()) / 2)
		end
	end

	return self
end

return {
	new = Bar.new
}