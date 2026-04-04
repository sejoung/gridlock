local car = require("src.car")

local board = {}

board.GRID_SIZE = 6
board.CELL_SIZE = 72
board.OFFSET_X = 0
board.OFFSET_Y = 0
board.cars = {}
board.exit = nil

function board.init(levelData)
    -- Center the board in the window
    local totalSize = board.GRID_SIZE * board.CELL_SIZE
    board.OFFSET_X = (800 - totalSize) / 2
    board.OFFSET_Y = (600 - totalSize) / 2 + 20

    board.exit = levelData.exit
    board.cars = {}

    for _, carData in ipairs(levelData.cars) do
        table.insert(board.cars, car.new(carData))
    end
end

function board.snapshot()
    local snap = {}
    for i, c in ipairs(board.cars) do
        snap[i] = { x = c.x, y = c.y }
    end
    return snap
end

function board.restore(snap)
    for i, pos in ipairs(snap) do
        board.cars[i].x = pos.x
        board.cars[i].y = pos.y
    end
end

function board.getCarAt(gx, gy)
    for _, c in ipairs(board.cars) do
        if car.occupies(c, gx, gy) then
            return c
        end
    end
    return nil
end

function board.canMove(movingCar, dx, dy)
    for _, c in ipairs(board.cars) do
        if c ~= movingCar then
            local nx, ny = movingCar.x + dx, movingCar.y + dy
            for step = 0, movingCar.len - 1 do
                local cx, cy
                if movingCar.dir == "H" then
                    cx, cy = nx + step, ny
                else
                    cx, cy = nx, ny + step
                end
                if car.occupies(c, cx, cy) then
                    return false
                end
            end
        end
    end

    -- Check bounds
    local nx, ny = movingCar.x + dx, movingCar.y + dy
    if movingCar.dir == "H" then
        if nx < 1 or nx + movingCar.len - 1 > board.GRID_SIZE then
            -- Allow goal car to exit
            if movingCar.isGoal and board.exit.side == "right" and nx + movingCar.len - 1 > board.GRID_SIZE then
                return true
            end
            return false
        end
    else
        if ny < 1 or ny + movingCar.len - 1 > board.GRID_SIZE then
            return false
        end
    end

    return true
end

function board.checkClear()
    for _, c in ipairs(board.cars) do
        if c.isGoal then
            if board.exit.side == "right" and c.x + c.len - 1 > board.GRID_SIZE then
                return true
            end
        end
    end
    return false
end

function board.screenToGrid(sx, sy)
    local gx = math.floor((sx - board.OFFSET_X) / board.CELL_SIZE) + 1
    local gy = math.floor((sy - board.OFFSET_Y) / board.CELL_SIZE) + 1
    return gx, gy
end

function board.gridToScreen(gx, gy)
    local sx = board.OFFSET_X + (gx - 1) * board.CELL_SIZE
    local sy = board.OFFSET_Y + (gy - 1) * board.CELL_SIZE
    return sx, sy
end

function board.draw()
    -- Draw board background
    love.graphics.setColor(0.25, 0.25, 0.28)
    love.graphics.rectangle("fill",
        board.OFFSET_X, board.OFFSET_Y,
        board.GRID_SIZE * board.CELL_SIZE,
        board.GRID_SIZE * board.CELL_SIZE)

    -- Draw grid lines
    love.graphics.setColor(0.35, 0.35, 0.38)
    for i = 0, board.GRID_SIZE do
        local x = board.OFFSET_X + i * board.CELL_SIZE
        local y = board.OFFSET_Y + i * board.CELL_SIZE
        love.graphics.line(x, board.OFFSET_Y, x, board.OFFSET_Y + board.GRID_SIZE * board.CELL_SIZE)
        love.graphics.line(board.OFFSET_X, y, board.OFFSET_X + board.GRID_SIZE * board.CELL_SIZE, y)
    end

    -- Draw exit
    if board.exit and board.exit.side == "right" then
        love.graphics.setColor(0.9, 0.3, 0.3, 0.6)
        local ex = board.OFFSET_X + board.GRID_SIZE * board.CELL_SIZE
        local ey = board.OFFSET_Y + (board.exit.row - 1) * board.CELL_SIZE
        love.graphics.rectangle("fill", ex, ey + 10, 16, board.CELL_SIZE - 20)
        -- Arrow
        love.graphics.polygon("fill",
            ex + 16, ey + board.CELL_SIZE / 2,
            ex + 6, ey + 10,
            ex + 6, ey + board.CELL_SIZE - 10)
    end

    -- Draw cars
    for _, c in ipairs(board.cars) do
        car.draw(c, board)
    end

    love.graphics.setColor(1, 1, 1)
end

return board
