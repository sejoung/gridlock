-- Hint system with BFS solver
-- Provides progressive hints: highlight car → show direction → auto-move
local hint = {}

local GRID = 6

-- Hint levels
hint.NONE = 0
hint.SHOW_CAR = 1       -- highlight which car to move
hint.SHOW_DIRECTION = 2  -- show car + direction arrow
hint.AUTO_MOVE = 3       -- perform the move automatically

-- State
local solution = nil      -- cached solution path from BFS
local hintLevel = 0       -- current hint level (0 = no hint)
local hintCarId = nil     -- car id to highlight
local hintDX = 0          -- move direction
local hintDY = 0
local hintTimer = 0       -- animation timer
local dirty = true        -- solution needs recalculation

-- ============================================================
-- BFS Solver
-- ============================================================

local function encodeState(cars)
    local parts = {}
    for i, c in ipairs(cars) do
        parts[i] = c.x .. "," .. c.y
    end
    return table.concat(parts, "|")
end

local function copyCars(cars)
    local copy = {}
    for i, c in ipairs(cars) do
        copy[i] = { x = c.x, y = c.y, len = c.len, dir = c.dir, isGoal = c.isGoal, id = c.id }
    end
    return copy
end

local function carOccupies(c, gx, gy)
    for s = 0, c.len - 1 do
        local cx = c.dir == "H" and c.x + s or c.x
        local cy = c.dir == "H" and c.y or c.y + s
        if cx == gx and cy == gy then return true end
    end
    return false
end

local function isOccupied(cars, gx, gy, skip)
    for i, c in ipairs(cars) do
        if i ~= skip and carOccupies(c, gx, gy) then
            return true
        end
    end
    return false
end

local function isCleared(cars, exitRow)
    for _, c in ipairs(cars) do
        if c.isGoal and c.y == exitRow and c.x + c.len - 1 > GRID then
            return true
        end
    end
    return false
end

local function getMoves(cars)
    local moves = {}
    for i, c in ipairs(cars) do
        if c.dir == "H" then
            -- Right
            for step = 1, GRID do
                local nx = c.x + step
                local tail = nx + c.len - 1
                if c.isGoal and tail > GRID then
                    local blocked = false
                    for s = 0, c.len - 1 do
                        local cx = nx + s
                        if cx <= GRID and isOccupied(cars, cx, c.y, i) then
                            blocked = true; break
                        end
                    end
                    if not blocked then table.insert(moves, {i, step, 0}) end
                    break
                elseif tail > GRID then
                    break
                elseif isOccupied(cars, tail, c.y, i) then
                    break
                else
                    table.insert(moves, {i, step, 0})
                end
            end
            -- Left
            for step = 1, GRID do
                local nx = c.x - step
                if nx < 1 then break end
                if isOccupied(cars, nx, c.y, i) then break end
                table.insert(moves, {i, -step, 0})
            end
        else
            -- Down
            for step = 1, GRID do
                local ny = c.y + step
                if ny + c.len - 1 > GRID then break end
                if isOccupied(cars, c.x, ny + c.len - 1, i) then break end
                table.insert(moves, {i, 0, step})
            end
            -- Up
            for step = 1, GRID do
                local ny = c.y - step
                if ny < 1 then break end
                if isOccupied(cars, c.x, ny, i) then break end
                table.insert(moves, {i, 0, -step})
            end
        end
    end
    return moves
end

-- Solve from current state, returns list of moves [{carIndex, dx, dy}, ...]
local function solve(cars, exitRow)
    local initCars = copyCars(cars)

    if isCleared(initCars, exitRow) then return {} end

    local visited = {}
    local queue = {}
    local initState = encodeState(initCars)
    visited[initState] = true

    table.insert(queue, { cars = initCars, path = {} })

    local maxIter = 300000
    local iter = 0

    while #queue > 0 and iter < maxIter do
        iter = iter + 1
        local current = table.remove(queue, 1)

        for _, m in ipairs(getMoves(current.cars)) do
            local ci, dx, dy = m[1], m[2], m[3]
            local newCars = copyCars(current.cars)
            newCars[ci].x = newCars[ci].x + dx
            newCars[ci].y = newCars[ci].y + dy

            local newPath = {}
            for _, p in ipairs(current.path) do
                table.insert(newPath, p)
            end
            table.insert(newPath, { carIndex = ci, carId = newCars[ci].id, dx = dx, dy = dy })

            if isCleared(newCars, exitRow) then
                return newPath
            end

            local state = encodeState(newCars)
            if not visited[state] then
                visited[state] = true
                table.insert(queue, { cars = newCars, path = newPath })
            end
        end
    end

    return nil -- unsolvable
end

-- ============================================================
-- Public API
-- ============================================================

function hint.reset()
    solution = nil
    hintLevel = 0
    hintCarId = nil
    hintDX = 0
    hintDY = 0
    hintTimer = 0
    dirty = true
end

function hint.invalidate()
    dirty = true
    hintLevel = 0
    hintCarId = nil
end

-- Request next hint level. Returns the hint action taken.
-- board: the board module (for car data and exit info)
function hint.request(board)
    -- Solve if needed
    if dirty or not solution then
        local solverCars = {}
        for i, c in ipairs(board.cars) do
            solverCars[i] = {
                x = c.x, y = c.y,
                len = c.len, dir = c.dir,
                isGoal = c.isGoal, id = c.id,
            }
        end
        solution = solve(solverCars, board.exit.row)
        dirty = false
    end

    if not solution or #solution == 0 then
        return "no_solution"
    end

    local nextMove = solution[1]
    hintCarId = nextMove.carId
    hintDX = nextMove.dx
    hintDY = nextMove.dy

    hintLevel = hintLevel + 1
    if hintLevel > hint.AUTO_MOVE then
        hintLevel = hint.AUTO_MOVE
    end

    hintTimer = 0

    if hintLevel == hint.AUTO_MOVE then
        -- Return move info so game.lua can execute it
        hintLevel = 0
        hintCarId = nil
        return "auto_move", nextMove
    elseif hintLevel == hint.SHOW_CAR then
        return "show_car"
    elseif hintLevel == hint.SHOW_DIRECTION then
        return "show_direction"
    end
end

function hint.update(dt)
    hintTimer = hintTimer + dt
end

function hint.getHintCarId()
    return hintCarId
end

function hint.getLevel()
    return hintLevel
end

-- Draw hint overlay on a car
function hint.drawHint(board)
    if hintLevel == hint.NONE or not hintCarId then return end

    local targetCar = nil
    for _, c in ipairs(board.cars) do
        if c.id == hintCarId then
            targetCar = c
            break
        end
    end
    if not targetCar then return end

    local sx, sy = board.gridToScreen(targetCar.x, targetCar.y)
    local cellW, cellH
    if targetCar.dir == "H" then
        cellW = targetCar.len * board.CELL_SIZE
        cellH = board.CELL_SIZE
    else
        cellW = board.CELL_SIZE
        cellH = targetCar.len * board.CELL_SIZE
    end

    local pulse = 0.5 + 0.5 * math.sin(hintTimer * 5)

    -- Level 1+: Highlight the car with pulsing glow
    love.graphics.setColor(0.3, 1, 0.3, 0.2 + 0.2 * pulse)
    love.graphics.rectangle("fill", sx - 4, sy - 4, cellW + 8, cellH + 8, 10, 10)
    love.graphics.setColor(0.3, 1, 0.3, 0.5 + 0.3 * pulse)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", sx - 2, sy - 2, cellW + 4, cellH + 4, 8, 8)
    love.graphics.setLineWidth(1)

    -- Level 2: Show direction arrow
    if hintLevel >= hint.SHOW_DIRECTION then
        local cx = sx + cellW / 2
        local cy = sy + cellH / 2
        local arrowLen = 20 + 5 * pulse
        local arrowSize = 8

        love.graphics.setColor(0.3, 1, 0.3, 0.8 + 0.2 * pulse)

        if hintDX > 0 then -- right
            local ax = sx + cellW + 8
            love.graphics.polygon("fill",
                ax + arrowLen, cy,
                ax, cy - arrowSize,
                ax, cy + arrowSize)
            love.graphics.setLineWidth(3)
            love.graphics.line(ax - 4, cy, ax + arrowLen - 4, cy)
        elseif hintDX < 0 then -- left
            local ax = sx - 8
            love.graphics.polygon("fill",
                ax - arrowLen, cy,
                ax, cy - arrowSize,
                ax, cy + arrowSize)
            love.graphics.setLineWidth(3)
            love.graphics.line(ax + 4, cy, ax - arrowLen + 4, cy)
        elseif hintDY > 0 then -- down
            local ay = sy + cellH + 8
            love.graphics.polygon("fill",
                cx, ay + arrowLen,
                cx - arrowSize, ay,
                cx + arrowSize, ay)
            love.graphics.setLineWidth(3)
            love.graphics.line(cx, ay - 4, cx, ay + arrowLen - 4)
        elseif hintDY < 0 then -- up
            local ay = sy - 8
            love.graphics.polygon("fill",
                cx, ay - arrowLen,
                cx - arrowSize, ay,
                cx + arrowSize, ay)
            love.graphics.setLineWidth(3)
            love.graphics.line(cx, ay + 4, cx, ay - arrowLen + 4)
        end
        love.graphics.setLineWidth(1)
    end
end

return hint
