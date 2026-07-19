---@class Entity
local Entity = {}

local nextId = 0

---Create a new entity and return its unique ID
---@return number Unique entity ID
function Entity.new()
    nextId = nextId + 1
    return nextId
end

---Destroy an entity by removing its component data
---@param id number Entity ID to destroy
---@param Components table Component tables to clean up
function Entity.destroy(id, Components)
    for _, comp in pairs(Components) do
        comp[id] = nil
    end
end

return Entity