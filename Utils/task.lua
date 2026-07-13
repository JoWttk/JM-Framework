local task = {}

local ready = {}
local sleeping = {}

local now = 0

local function push_ready(co, ...)
	ready[#ready + 1] = { co = co, args = { ... } }
end

function task.spawn(fn, ...)
	assert(type(fn) == "function", "task.spawn: expected function")
	local co = coroutine.create(fn)
	push_ready(co, ...)
	return co
end

function task.delay(seconds, fn, ...)
	assert(type(seconds) == "number", "task.delay: expected number")
	assert(type(fn) == "function", "task.delay: expected function")
	local args = { ... }
	local co = coroutine.create(function()
		fn(unpack(args))
	end)
	sleeping[#sleeping + 1] = { co = co, wake = now + math.max(0, seconds), args = {} }
	return co
end

function task.wait(seconds)
	seconds = seconds or 0
	assert(coroutine.running(), "task.wait must be called inside a coroutine")
	return coroutine.yield(math.max(0, seconds))
end

function task.cancel(co)
	for i = #sleeping, 1, -1 do
		if sleeping[i].co == co then
			table.remove(sleeping, i)
			return true
		end
	end

	for i = #ready, 1, -1 do
		if ready[i].co == co then
			table.remove(ready, i)
			return true
		end
	end

	return false
end

function task.step(dt)
	now = now + dt

	for i = #sleeping, 1, -1 do
		local t = sleeping[i]
		if t.wake <= now then
			table.remove(sleeping, i)
			push_ready(t.co, unpack(t.args))
		end
	end

	local i = 1
	while i <= #ready do
		local item = ready[i]
		ready[i] = nil
		i = i + 1

		local co = item.co
		if coroutine.status(co) ~= "dead" then
			local ok, waitSecondsOrErr = coroutine.resume(co, unpack(item.args))
			if not ok then
				print("[task] coroutine error:", waitSecondsOrErr)
			else
				if type(waitSecondsOrErr) == "number" then
					sleeping[#sleeping + 1] = { co = co, wake = now + math.max(0, waitSecondsOrErr), args = {} }
				end
			end
		end
	end

	ready = {}
end

return task