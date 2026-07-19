local NPC = require("engine.EntitySystem.NPC")
local Signal = require("engine.Utils.signal")

---@class Question
---@field owner string Name of the question owner (NPC)
---@field name string Unique name identifier for the question
---@field finished boolean Whether the question has been completed
---@field onComplete function|nil Callback executed when question is completed
local Questions = {}
Questions.__index = Questions
Questions.list = {}

Questions.add = Signal:new()
Questions.finish = Signal:new()

---Create a new question
---@param Owner string Name of the question owner
---@param Name string Name of the question
---@param OnComplete function|nil Callback after completion
---@return Question
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

---Remove a question from the list
---@param q Question The question to remove
function Questions:GiveUp(q)
    for i,v in pairs(Questions.list) do
        if v == q then
            table.remove(Questions.list, i)
        end
    end
end

---Mark a question as completed
---@param q Question The question to complete
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

---Callback for when a question is finished
---@param Question string | Question Question name or object
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