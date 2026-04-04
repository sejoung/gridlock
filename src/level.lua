local level = {}

local levels = {}

function level.loadAll()
    levels = {}
    local i = 1
    while true do
        local path = "levels.level" .. i
        local ok, data = pcall(require, path)
        if ok and data then
            table.insert(levels, data)
            i = i + 1
        else
            break
        end
    end
end

function level.get(num)
    return levels[num]
end

function level.count()
    return #levels
end

return level
