local save = {}

local data = {
    cleared = {},
    bestMoves = {},
}

local SAVE_FILE = "gridlock_save.dat"

function save.load()
    local info = love.filesystem.getInfo(SAVE_FILE)
    if info then
        local contents = love.filesystem.read(SAVE_FILE)
        if contents then
            local fn, err = loadstring("return " .. contents)
            if fn then
                local ok, loaded = pcall(fn)
                if ok and loaded then
                    data = loaded
                    data.cleared = data.cleared or {}
                    data.bestMoves = data.bestMoves or {}
                end
            end
        end
    end
end

function save.save()
    local str = "{\n"
    str = str .. "  cleared = {"
    for k, v in pairs(data.cleared) do
        str = str .. "[" .. k .. "]=" .. tostring(v) .. ","
    end
    str = str .. "},\n"
    str = str .. "  bestMoves = {"
    for k, v in pairs(data.bestMoves) do
        str = str .. "[" .. k .. "]=" .. v .. ","
    end
    str = str .. "},\n"
    str = str .. "}"
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
