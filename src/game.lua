local board = require("src.board")
local level = require("src.level")
local input = require("src.input")
local ui = require("src.ui")
local save = require("src.save")
local sound = require("src.sound")
local anim = require("src.anim")
local hint = require("src.hint")

local game = {}

-- Game states: "title", "level_select", "playing", "clear"
game.state = "title"
game.currentLevel = 1
game.moveCount = 0
game.undoStack = {}
game.hintUsed = false

function game.load()
    save.load()
    level.loadAll()
    sound.load()
    ui.loadFonts()
    -- Auto-check for level updates on launch
    level.checkForUpdates()
end

function game.update(dt)
    -- Process level update downloads
    level.updateCheck()

    if game.state == "playing" then
        input.update(dt)
        board.update(dt)
        hint.update(dt)
    elseif game.state == "clear" then
        board.update(dt)
    end
    ui.update(dt)
end

function game.draw()
    if game.state == "title" then
        ui.drawTitle()
    elseif game.state == "level_select" then
        ui.drawLevelSelect(level.count(), save.getData())
    elseif game.state == "playing" then
        board.draw()
        hint.drawHint(board)
        ui.drawHUD(game.currentLevel, game.moveCount, game.hintUsed)
    elseif game.state == "clear" then
        board.draw()
        ui.drawClear(game.currentLevel, game.moveCount, game.hintUsed)
    end
end

function game.startLevel(levelNum)
    game.currentLevel = levelNum
    game.moveCount = 0
    game.undoStack = {}
    game.hintUsed = false
    local data = level.get(levelNum)
    board.init(data)
    anim.reset()
    hint.reset()
    input.init(board, {
        onCarMoved = game.onCarMoved,
        onClear = game.onClear,
    })
    game.state = "playing"
end

function game.onCarMoved(snapshot)
    table.insert(game.undoStack, snapshot)
    game.moveCount = game.moveCount + 1
    hint.invalidate()
end

function game.undo()
    if #game.undoStack > 0 then
        local snapshot = table.remove(game.undoStack)
        board.restore(snapshot)
        game.moveCount = game.moveCount - 1
        hint.invalidate()
        sound.play("undo")
    end
end

function game.reset()
    game.startLevel(game.currentLevel)
end

function game.hint()
    local action, moveData = hint.request(board)

    if action == "show_car" then
        game.hintUsed = true
        sound.play("click")
    elseif action == "show_direction" then
        sound.play("click")
    elseif action == "auto_move" and moveData then
        -- Find the car and perform the move
        local targetCar = nil
        for _, c in ipairs(board.cars) do
            if c.id == moveData.carId then
                targetCar = c
                break
            end
        end
        if targetCar then
            local snap = board.snapshot()
            -- Apply only 1 step in the move direction
            local stepX = moveData.dx > 0 and 1 or (moveData.dx < 0 and -1 or 0)
            local stepY = moveData.dy > 0 and 1 or (moveData.dy < 0 and -1 or 0)
            targetCar.x = targetCar.x + stepX
            targetCar.y = targetCar.y + stepY
            anim.startMove(targetCar.id, stepX, stepY, board.CELL_SIZE)
            sound.play("move")
            game.onCarMoved(snap)

            if board.checkClear() then
                sound.play("clear")
                game.onClear()
            end
        end
    elseif action == "no_solution" then
        sound.play("invalid")
    end
end

function game.onClear()
    save.markCleared(game.currentLevel, game.moveCount)
    game.state = "clear"
end

function game.nextLevel()
    if game.currentLevel < level.count() then
        game.startLevel(game.currentLevel + 1)
    else
        game.state = "level_select"
    end
end

function game.mousepressed(x, y, button)
    if game.state == "title" then
        ui.titleClick(x, y, game)
    elseif game.state == "level_select" then
        ui.levelSelectClick(x, y, game)
    elseif game.state == "playing" then
        if not ui.hudClick(x, y, game) then
            input.mousepressed(x, y, button)
        else
            sound.play("click")
        end
    elseif game.state == "clear" then
        ui.clearClick(x, y, game)
        sound.play("click")
    end
end

function game.mousereleased(x, y, button)
    if game.state == "playing" then
        input.mousereleased(x, y, button)
    end
end

function game.mousemoved(x, y, dx, dy)
    if game.state == "playing" then
        input.mousemoved(x, y, dx, dy)
    end
    ui.mousemoved(x, y)
end

function game.keypressed(key)
    if game.state == "playing" then
        if key == "u" then
            game.undo()
        elseif key == "r" then
            game.reset()
        elseif key == "h" then
            game.hint()
        end
    end
end

return game
