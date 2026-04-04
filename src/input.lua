local input = {}
local anim = require("src.anim")
local sound = require("src.sound")

local board = nil
local onCarMoved = nil
local onClear = nil
local selectedCar = nil
local dragging = false
local dragStartX, dragStartY = 0, 0
local DRAG_THRESHOLD = 10

function input.init(b, callbacks)
    board = b
    onCarMoved = callbacks.onCarMoved
    onClear = callbacks.onClear
    selectedCar = nil
    dragging = false
end

function input.update(dt)
    anim.update(dt)
end

function input.mousepressed(x, y, button)
    if button ~= 1 then return end

    local gx, gy = board.screenToGrid(x, y)
    if gx < 1 or gx > board.GRID_SIZE or gy < 1 or gy > board.GRID_SIZE then
        return
    end

    -- Deselect previous
    if selectedCar then
        selectedCar.selected = false
    end

    selectedCar = board.getCarAt(gx, gy)
    if selectedCar then
        selectedCar.selected = true
        dragging = true
        dragStartX, dragStartY = x, y
        sound.play("select")
    end
end

function input.mousereleased(x, y, button)
    if button ~= 1 then return end
    dragging = false
end

function input.mousemoved(x, y, dx, dy)
    if not dragging or not selectedCar then return end

    local totalDX = x - dragStartX
    local totalDY = y - dragStartY

    if math.abs(totalDX) < DRAG_THRESHOLD and math.abs(totalDY) < DRAG_THRESHOLD then
        return
    end

    local moveX, moveY = 0, 0

    if selectedCar.dir == "H" then
        if totalDX > DRAG_THRESHOLD then
            moveX = 1
        elseif totalDX < -DRAG_THRESHOLD then
            moveX = -1
        end
    else
        if totalDY > DRAG_THRESHOLD then
            moveY = 1
        elseif totalDY < -DRAG_THRESHOLD then
            moveY = -1
        end
    end

    if moveX ~= 0 or moveY ~= 0 then
        if board.canMove(selectedCar, moveX, moveY) then
            local snap = board.snapshot()
            selectedCar.x = selectedCar.x + moveX
            selectedCar.y = selectedCar.y + moveY
            anim.startMove(selectedCar.id, moveX, moveY, board.CELL_SIZE)
            sound.play("move")
            onCarMoved(snap)

            if board.checkClear() then
                sound.play("clear")
                onClear()
            end
        else
            -- Invalid move feedback
            anim.startShake(selectedCar.id, selectedCar.dir)
            sound.play("invalid")
        end
        dragStartX, dragStartY = x, y
    end
end

return input
