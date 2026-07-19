---@class SaveTXT
local SaveTXT = {}

---Convert a Lua value to its string representation for saving.
---@param v any Value to convert (boolean, number, string)
---@return string
local function toString(v)
    if type(v) == "boolean" then
        return v and "true" or "false"
    end
    return tostring(v)
end

---Parse a string value back to its original type (boolean, number, or string).
---@param s string The string to parse
---@return boolean|number|string
local function parseValue(s)
    s = s:gsub("^%s+", ""):gsub("%s+$", "")

    if s == "true" then return true end
    if s == "false" then return false end

    local n = tonumber(s)
    if n ~= nil then return n end

    return s
end

---Write a key-value table to a text file.
---Each entry is written as "key=value" on its own line, sorted alphabetically.
---@param filename string Save file name (e.g. "player.txt")
---@param data table Table of key-value pairs to persist
function SaveTXT.write(filename, data)
    assert(type(data) == "table", "SaveTXT.write: data must be a table")

    local lines = {}
    for k, v in pairs(data) do
        lines[#lines + 1] = tostring(k) .. "=" .. toString(v)
    end

    table.sort(lines)
    love.filesystem.write(filename, table.concat(lines, "\n") .. "\n")
end

---Read and parse a key-value text file back into a table.
---Supports comments starting with # or //. Lines are parsed as "key=value".
---@param filename string Save file name to read
---@return table|nil Parsed data table, or nil if file doesn't exist
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

---Delete a save file if it exists.
---@param filename string Save file name to remove
function SaveTXT.delete(filename)
    if love.filesystem.getInfo(filename) then
        love.filesystem.remove(filename)
    end
end

return SaveTXT