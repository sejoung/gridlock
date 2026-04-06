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

    local escapeMap = {
        ['"'] = '"', ['\\'] = '\\', ['/'] = '/',
        ['b'] = '\b', ['f'] = '\f', ['n'] = '\n',
        ['r'] = '\r', ['t'] = '\t',
    }

    local function parseString()
        skipWhitespace()
        if str:sub(pos, pos) ~= '"' then return nil end
        pos = pos + 1
        local parts = {}
        while pos <= #str do
            local c = str:sub(pos, pos)
            if c == '\\' then
                pos = pos + 1
                local esc = str:sub(pos, pos)
                if esc == 'u' then
                    -- Unicode escape: \uXXXX
                    local hex = str:sub(pos + 1, pos + 4)
                    local code = tonumber(hex, 16)
                    if code then
                        if code < 0x80 then
                            table.insert(parts, string.char(code))
                        elseif code < 0x800 then
                            table.insert(parts, string.char(
                                0xC0 + math.floor(code / 64),
                                0x80 + code % 64))
                        else
                            table.insert(parts, string.char(
                                0xE0 + math.floor(code / 4096),
                                0x80 + math.floor(code / 64) % 64,
                                0x80 + code % 64))
                        end
                    end
                    pos = pos + 5
                elseif escapeMap[esc] then
                    table.insert(parts, escapeMap[esc])
                    pos = pos + 1
                else
                    table.insert(parts, esc)
                    pos = pos + 1
                end
            elseif c == '"' then
                pos = pos + 1
                return table.concat(parts)
            else
                table.insert(parts, c)
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
