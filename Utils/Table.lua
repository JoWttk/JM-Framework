local Table = {}

function Table.find(tbl, value)
    for i, v in ipairs(tbl) do
        if v == value then
            return i
        end
    end

    return nil
end

return Table