local Signal = {}
Signal.__index = Signal

function Signal.new()
    return setmetatable({ _handlers = {} }, Signal)
end

function Signal:connect(fn)
    local handlers = self._handlers
    handlers[#handlers + 1] = fn

    local alive = true
    return {
        disconnect = function()
            if not alive then return end
            alive = false
            for i = #handlers, 1, -1 do
                if handlers[i] == fn then
                    table.remove(handlers, i)
                    break
                end
            end
        end
    }
end

function Signal:fire(...)
    local handlers = self._handlers
    for i = 1, #handlers do
        handlers[i](...)
    end
end

return Signal
