local NPC = require("engine.EntitySystem.NPC")
local Signal = require("engine.Utils.signal")

local Questions = {}

Questions.__index = Questions
Questions.list = {}

Questions.add = Signal:new()
Questions.finish = Signal:new()

function Questions:new(Owner, Name, OnComplete)
    local q = {}
    q.owner = Owner
    q.name = Name
    q.onComplete = OnComplete or nil

    q.finished = false

    setmetatable(q, self)
    table.insert(Questions.list, q)

    return q
end

function Questions:GiveUp(q)
    if not Questions.list[q] then return end
    table.remove(Questions.list, q)
end

function Questions:complete(q)
    if not Questions.list[q] then return end
    
    if q.onComplete then
        q.onComplete()
    end
    if q.finished then
        q.finished = true
    end
end

Questions.add:connect(function (Owner, Name, onComplete)
    if not onComplete then
        onComplete = nil
    end

    Questions:new(Owner, Name, onComplete)
end)

Questions.finish:connect(function (Question)
    if type(Question) == "string" then
        for i,v in pairs(Questions.list) do
            if v.name == Question then
                local Q = Questions.list[i]
                Q.finished = true
            end
        end
    else
        Questions:complete(Question)
    end
end)

return Questions