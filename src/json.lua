-- Minimal JSON parser for level data
local json = {}

function json.decode(str)
    local pos = 1

    local function skipWhitespace()
        pos = str:find("[^ \t\r\n]", pos) or (#str + 1)
    end

    local function peek()
        skipWhitespace()
        return str:sub(pos, pos)
    end

    local function consume(expected)
        skipWhitespace()
        if str:sub(pos, pos) == expected then
            pos = pos + 1
            return true
        end
        return false
    end

    local parseValue -- forward declaration

    local function parseString()
        skipWhitespace()
        if str:sub(pos, pos) ~= '"' then return nil end
        pos = pos + 1
        local start = pos
        while pos <= #str do
            local c = str:sub(pos, pos)
            if c == '\\' then
                pos = pos + 2
            elseif c == '"' then
                local s = str:sub(start, pos - 1)
                pos = pos + 1
                return s
            else
                pos = pos + 1
            end
        end
        return nil
    end

    local function parseNumber()
        skipWhitespace()
        local start = pos
        if str:sub(pos, pos) == '-' then pos = pos + 1 end
        while pos <= #str and str:sub(pos, pos):match("[0-9.]") do
            pos = pos + 1
        end
        local numStr = str:sub(start, pos - 1)
        return tonumber(numStr)
    end

    local function parseArray()
        if not consume('[') then return nil end
        local arr = {}
        if peek() == ']' then
            consume(']')
            return arr
        end
        while true do
            local val = parseValue()
            table.insert(arr, val)
            if not consume(',') then break end
        end
        consume(']')
        return arr
    end

    local function parseObject()
        if not consume('{') then return nil end
        local obj = {}
        if peek() == '}' then
            consume('}')
            return obj
        end
        while true do
            local key = parseString()
            consume(':')
            local val = parseValue()
            if key then obj[key] = val end
            if not consume(',') then break end
        end
        consume('}')
        return obj
    end

    parseValue = function()
        skipWhitespace()
        local c = str:sub(pos, pos)
        if c == '"' then return parseString()
        elseif c == '{' then return parseObject()
        elseif c == '[' then return parseArray()
        elseif c == 't' then pos = pos + 4; return true
        elseif c == 'f' then pos = pos + 5; return false
        elseif c == 'n' then pos = pos + 4; return nil
        else return parseNumber()
        end
    end

    return parseValue()
end

return json
