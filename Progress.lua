local Progress = {}

local Save = require("engine.Save")

local WORLDS = 3
local LEVELS_PER_WORLD = 6

local data = {}

local function key(world, level)
    return "W" .. world .. "L" .. level
end

function Progress.load()
    data = Save.read("progress.txt") or {}

    for w = 1, WORLDS do
        for l = 1, LEVELS_PER_WORLD do
            local k = key(w, l)
            if data[k] == nil then
                data[k] = (w ~= 1 or l ~= 1)
            end
        end
    end
end

function Progress.save()
    Save.write("progress.txt", data)
end

function Progress.isLocked(world, level)
    local k = key(world, level)
    if data[k] == nil then
        return (world ~= 1 or level ~= 1)
    end
    return data[k]
end

function Progress.completeLevel(world, level)
    local nextLevel = level + 1
    if nextLevel <= LEVELS_PER_WORLD then
        data[key(world, nextLevel)] = false 
    end
    Progress.save()
    
    local ok, AutoSave = pcall(require, "engine.AutoSave")
    if ok and AutoSave and AutoSave.saveNow then AutoSave.saveNow() end
    
    local check = Save.read("progress.txt")
    if check then
        print("Progress saved. W1L2 = " .. tostring(check["W1L2"]))
    else
        print("WARNING: progress.txt could not be read after save!")
    end
end

return Progress

-- AI