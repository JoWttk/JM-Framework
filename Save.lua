local SaveTXT = {}

local function toString(v)
    if type(v) == "boolean" then
        return v and "true" or "false"
    end
    return tostring(v)
end

local function parseValue(s)
    s = s:gsub("^%s+", ""):gsub("%s+$", "")

    if s == "true" then return true end
    if s == "false" then return false end

    local n = tonumber(s)
    if n ~= nil then return n end

    return s
end

function SaveTXT.write(filename, data)
    assert(type(data) == "table", "SaveTXT.write: data must be a table")

    local lines = {}
    for k, v in pairs(data) do
        lines[#lines + 1] = tostring(k) .. "=" .. toString(v)
    end

    table.sort(lines)
    love.filesystem.write(filename, table.concat(lines, "\n") .. "\n")
end

function SaveTXT.read(filename)
    if not love.filesystem.getInfo(filename) then
        return nil
    end

    local content = love.filesystem.read(filename)
    local out = {}

    for line in content:gmatch("[^\r\n]+") do
        line = line:gsub("^%s+", ""):gsub("%s+$", "")

        if line ~= "" and not line:match("^#") and not line:match("^//") then
            local key, value = line:match("^([^=]+)=(.*)$")
            if key then
                key = key:gsub("^%s+", ""):gsub("%s+$", "")
                out[key] = parseValue(value)
            end
        end
    end

    return out
end

function SaveTXT.delete(filename)
    if love.filesystem.getInfo(filename) then
        love.filesystem.remove(filename)
    end
end

return SaveTXT