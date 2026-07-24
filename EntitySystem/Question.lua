---@class QuestionCallbacks
---@field load fun(q: Question)|nil
---@field update fun(q: Question, dt: number)|nil
---@field draw fun(q: Question)|nil

---@class Question
---@field owner string Name of the question owner (NPC)
---@field name string Unique name identifier for the question
---@field finished boolean Whether the question has been completed
---@field onReceive QuestionCallbacks
---@field onComplete function|nil Callback executed when question is completed
local Questions = {}
Questions.__index = Questions
Questions.list = {}

Questions.add = Signal:new()
Questions.finish = Signal:new()

---Create a new question
---@param Owner string Name of the question owner
---@param Name string Name of the question
---@param onReceive QuestionCallbacks
---@param OnComplete function|nil Callback after completion
---@return Question
function Questions:new(Owner, Name, onReceive, OnComplete)
    local q = {}
    q.owner = Owner
    q.name = Name
    q.onComplete = OnComplete or nil
    q.onReceive = onReceive or {}

    q.finished = false

    setmetatable(q, self)
    table.insert(Questions.list, q)

    if q.onReceive.load then
        q.onReceive.load(q)
    end

    return q
end

---Update every active question
---@param dt number
function Questions.update(dt)
    for _, q in ipairs(Questions.list) do
        if q.onReceive.update then
            q.onReceive.update(q, dt)
        end
    end
end

---Draw every active question
function Questions.draw()
    for _, q in ipairs(Questions.list) do
        if q.onReceive.draw then
            q.onReceive.draw(q)
        end
    end
end

---Remove a question from the list
---@param q Question The question to remove
function Questions:giveUp(q)
    for i, v in ipairs(Questions.list) do
        if v == q then
            table.remove(Questions.list, i)
            break
        end
    end
end

---Mark a question as completed
---@param q Question The question to complete
function Questions:complete(q)
    if q.finished then return end

    q.finished = true
    if q.onComplete then
        q.onComplete()
    end
end

Questions.add:connect(function (Owner, Name, onReceive, onComplete)
    Questions:new(Owner, Name, onReceive, onComplete)
end)

---Callback for when a question is finished
---@param Question string | Question Question name or object
Questions.finish:connect(function (Question)
    if type(Question) == "string" then
        for _, v in ipairs(Questions.list) do
            if v.name == Question then
                Questions:complete(v)
                break
            end
        end
    else
        Questions:complete(Question)
    end
end)

return Questions