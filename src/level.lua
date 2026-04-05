local level = {}
local json = require("src.json")
local carTypes = require("src.car_types")

local levels = {}
local CACHE_FILE = "downloaded_levels.json"
local CACHE_VERSION_FILE = "levels_version.txt"

-- GitHub Pages URLs (change to your repo)
local BASE_URL = "https://sejoung.github.io/gridlock"
level.VERSION_URL = BASE_URL .. "/levels-version.txt"
level.LEVELS_URL = BASE_URL .. "/levels.json"
level.updateStatus = "idle"  -- "idle", "checking", "downloading", "done"
level.updateMessage = ""
level.newLevelsCount = 0

-- ============================================================
-- Load bundled levels from levels/ folder
-- ============================================================
local function loadBundled()
    local bundled = {}
    local i = 1
    while true do
        local path = "levels.level" .. i
        local ok, data = pcall(require, path)
        if ok and data then
            table.insert(bundled, data)
            i = i + 1
        else
            break
        end
    end
    return bundled
end

-- ============================================================
-- Load cached downloaded levels
-- ============================================================
local function loadCached()
    local info = love.filesystem.getInfo(CACHE_FILE)
    if not info then return nil, nil end

    local content = love.filesystem.read(CACHE_FILE)
    if not content then return nil, nil end

    local ok, data = pcall(json.decode, content)
    if not ok or not data then return nil, nil end

    -- Read cached version
    local version = nil
    local vInfo = love.filesystem.getInfo(CACHE_VERSION_FILE)
    if vInfo then
        version = love.filesystem.read(CACHE_VERSION_FILE)
    end

    return data, version
end

-- ============================================================
-- Parse JSON level data into game format
-- ============================================================
local function parseLevels(data)
    if not data or not data.levels then return {} end

    local parsed = {}
    for _, lv in ipairs(data.levels) do
        local cars = {}
        for _, c in ipairs(lv.cars) do
            local typeDef = carTypes[c.type]
            table.insert(cars, {
                id = c.id,
                x = c.x,
                y = c.y,
                dir = c.dir,
                type = c.type,
            })
        end
        table.insert(parsed, {
            id = lv.id,
            exit = lv.exit,
            cars = cars,
        })
    end

    -- Sort by id
    table.sort(parsed, function(a, b) return a.id < b.id end)
    return parsed
end

-- ============================================================
-- Merge bundled + downloaded, avoid duplicates by id
-- ============================================================
local function mergeLevels(bundled, downloaded)
    if not downloaded or #downloaded == 0 then
        return bundled
    end

    -- Use bundled as base, add downloaded levels with new ids
    local idSet = {}
    local merged = {}

    for _, lv in ipairs(bundled) do
        idSet[lv.id] = true
        table.insert(merged, lv)
    end

    for _, lv in ipairs(downloaded) do
        if not idSet[lv.id] then
            idSet[lv.id] = true
            table.insert(merged, lv)
        end
    end

    -- Sort by id
    table.sort(merged, function(a, b) return a.id < b.id end)
    return merged
end

-- ============================================================
-- Public API
-- ============================================================

function level.loadAll()
    local bundled = loadBundled()

    -- Try to load cached downloaded levels
    local cachedData = loadCached()
    local downloaded = parseLevels(cachedData)

    levels = mergeLevels(bundled, downloaded)
end

function level.get(num)
    return levels[num]
end

function level.count()
    return #levels
end

-- HTTP fetch helper (used in threads)
local FETCH_CODE = [[
    local function fetch(url, maxRedirects)
        local http = require("socket.http")
        local ltn12 = require("ltn12")
        maxRedirects = maxRedirects or 5
        for i = 1, maxRedirects do
            local body = {}
            local result, status, headers = http.request{
                url = url,
                sink = ltn12.sink.table(body),
                redirect = false,
                headers = { ["User-Agent"] = "Gridlock/1.0" },
            }
            if status == 200 then
                return table.concat(body)
            elseif status == 301 or status == 302 or status == 307 or status == 308 then
                local location = headers and headers["location"]
                if location then url = location else return nil end
            else
                return nil
            end
        end
        return nil
    end
]]

-- Check for updates: Step 1 = version check, Step 2 = download if needed
function level.checkForUpdates()
    if level.updateStatus == "checking" or level.updateStatus == "downloading" then
        return
    end

    level.updateStatus = "checking"
    level.updateMessage = ""
    level.newLevelsCount = 0

    -- Read local cached version
    local localVersion = nil
    local vInfo = love.filesystem.getInfo(CACHE_VERSION_FILE)
    if vInfo then
        localVersion = love.filesystem.read(CACHE_VERSION_FILE)
        if localVersion then localVersion = localVersion:match("^%s*(.-)%s*$") end
    end

    -- Step 1: Fetch remote version (tiny file)
    local thread = love.thread.newThread(FETCH_CODE .. [[
        local versionUrl, levelsUrl, localVersion = ...
        local channel = love.thread.getChannel("level_update")

        local ok = pcall(require, "socket.http")
        if not ok then
            channel:push({ status = "skip" })
            return
        end

        local remoteVersion = fetch(versionUrl)
        if not remoteVersion then
            channel:push({ status = "skip" })
            return
        end

        remoteVersion = remoteVersion:match("^%s*(.-)%s*$")

        if remoteVersion == localVersion then
            channel:push({ status = "up_to_date" })
            return
        end

        -- Step 2: Version differs, download full levels.json
        local body = fetch(levelsUrl)
        if body then
            channel:push({ status = "ok", body = body, version = remoteVersion })
        else
            channel:push({ status = "skip" })
        end
    ]])

    thread:start(level.VERSION_URL, level.LEVELS_URL, localVersion or "")
end

-- Call this in game.update() to process download results
function level.updateCheck()
    if level.updateStatus ~= "checking" then return end

    local channel = love.thread.getChannel("level_update")
    local result = channel:pop()
    if not result then return end

    if result.status == "ok" then
        -- New levels downloaded
        local ok, data = pcall(json.decode, result.body)
        if ok and data then
            love.filesystem.write(CACHE_FILE, result.body)
            love.filesystem.write(CACHE_VERSION_FILE, result.version or "")

            local bundled = loadBundled()
            local downloaded = parseLevels(data)
            local oldCount = #levels
            levels = mergeLevels(bundled, downloaded)
            level.newLevelsCount = #levels - oldCount

            if level.newLevelsCount > 0 then
                level.updateMessage = level.newLevelsCount .. " new levels added!"
            end
            level.updateStatus = "done"
        else
            level.updateStatus = "idle"
        end
    elseif result.status == "up_to_date" then
        level.updateStatus = "idle"
    else
        -- skip / error: silently continue with bundled levels
        level.updateStatus = "idle"
    end
end

return level
