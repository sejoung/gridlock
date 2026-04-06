local save = {}
local json = require("src.json")

local data = {
    cleared = {},
    bestMoves = {},
}

local SAVE_FILE = "gridlock_save.json"

function save.load()
    local info = love.filesystem.getInfo(SAVE_FILE)
    if info then
        local contents = love.filesystem.read(SAVE_FILE)
        if contents then
            local ok, loaded = pcall(json.decode, contents)
            if ok and loaded then
                -- Reconstruct with numeric keys (JSON keys are strings)
                data.cleared = {}
                data.bestMoves = {}
                if loaded.cleared then
                    for k, v in pairs(loaded.cleared) do
                        data.cleared[tonumber(k)] = v
                    end
                end
                if loaded.bestMoves then
                    for k, v in pairs(loaded.bestMoves) do
                        data.bestMoves[tonumber(k)] = v
                    end
                end
            end
        end
    end
end

function save.save()
    local str = '{"cleared":{'
    local first = true
    for k, v in pairs(data.cleared) do
        if not first then str = str .. "," end
        str = str .. '"' .. k .. '":' .. tostring(v)
        first = false
    end
    str = str .. '},"bestMoves":{'
    first = true
    for k, v in pairs(data.bestMoves) do
        if not first then str = str .. "," end
        str = str .. '"' .. k .. '":' .. v
        first = false
    end
    str = str .. '}}'
    love.filesystem.write(SAVE_FILE, str)
end

function save.markCleared(levelNum, moves)
    data.cleared[levelNum] = true
    if not data.bestMoves[levelNum] or moves < data.bestMoves[levelNum] then
        data.bestMoves[levelNum] = moves
    end
    save.save()
end

function save.getData()
    return data
end

return save
