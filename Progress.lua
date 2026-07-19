local Progress = {}

local Save = require("engine.Save")

local ChapterS = 3
local LEVELS_PER_Chapter = 6

local data = {}

local function key(Chapter, level)
    return "W" .. Chapter .. "L" .. level
end

function Progress.load()
    data = Save.read("progress.txt") or {}

    for w = 1, ChapterS do
        for l = 1, LEVELS_PER_Chapter do
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

function Progress.isLocked(Chapter, level)
    local k = key(Chapter, level)
    if data[k] == nil then
        return (Chapter ~= 1 or level ~= 1)
    end
    return data[k]
end

function Progress.completeLevel(Chapter, level)
    local nextLevel = level + 1
    if nextLevel <= LEVELS_PER_Chapter then
        data[key(Chapter, nextLevel)] = false 
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