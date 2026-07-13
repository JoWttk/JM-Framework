local Entity = {}

local nextId = 0

function Entity.new()
    nextId = nextId + 1
    return nextId
end

function Entity.destroy(id, Components)
    for _, comp in pairs(Components) do
        comp[id] = nil
    end
end

return Entity
