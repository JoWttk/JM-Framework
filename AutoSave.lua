---@class AutoSave
---@field dirty boolean Whether there are pending changes to save
---@field timer number Elapsed time since last save
---@field interval number Auto-save interval in seconds
---@field pending table Pending data to be saved
local AutoSave = {
    dirty = false,
    timer = 0,
    interval = 10,
    pending = {}
}

local Save = require("engine.Save")

---Mark the auto-save system as dirty, scheduling a save.
---@param payload table|nil Optional data to include in the next save
function AutoSave.markDirty(payload)
    AutoSave.dirty = true
    AutoSave.timer = 0
    if payload and type(payload) == "table" then
        for k, v in pairs(payload) do
            AutoSave.pending[k] = v
        end
    end
end

---Immediately save all pending data (player, progress, settings).
---Attempts Poki web save first, falls back to local file save.
function AutoSave.saveNow()
    if AutoSave.pending.player then
        local ok, Poki = pcall(require, "engine.Web.Poki")
        if ok and Poki and Poki.saveProgress then
            pcall(function()
                Poki.saveProgress("player", AutoSave.pending.player)
            end)
        else
            Save.write("player.txt", AutoSave.pending.player)
        end
    end

    local ok, Progress = pcall(require, "engine.Progress")
    if ok and Progress and Progress.save then
        Progress.save()

        local okp, Poki = pcall(require, "engine.Web.Poki")
        if okp and Poki and Poki.saveProgress then
            pcall(function() Poki.saveProgress("progress", Save.read("progress.txt") or {}) end)
        end
    end

    local ok2, Settings = pcall(require, "scenes.Settings")
    if ok2 and Settings and Settings.save then
        Settings.save()
        local okp2, Poki = pcall(require, "engine.Web.Poki")
        if okp2 and Poki and Poki.saveProgress then
            pcall(function() Poki.saveProgress("settings", Save.read("settings.txt") or {}) end)
        end
    end

    AutoSave.dirty = false
    AutoSave.pending = {}
    AutoSave.timer = 0
end

---Update the auto-save timer. Saves automatically when interval is reached.
---@param dt number Delta time in seconds
function AutoSave.update(dt)
    if not AutoSave.dirty then return end
    AutoSave.timer = AutoSave.timer + dt
    if AutoSave.timer >= AutoSave.interval then
        AutoSave.saveNow()
    end
end

---Set the auto-save interval.
---@param sec number Interval in seconds
function AutoSave.setInterval(sec)
    AutoSave.interval = sec or AutoSave.interval
end

return AutoSave
