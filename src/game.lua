local board = require("src.board")
local level = require("src.level")
local input = require("src.input")
local ui = require("src.ui")
local save = require("src.save")

local game = {}

-- Game states: "title", "level_select", "playing", "clear"
game.state = "title"
game.currentLevel = 1
game.moveCount = 0
game.undoStack = {}

function game.load()
    save.load()
    level.loadAll()
end

function game.update(dt)
    if game.state == "playing" then
        input.update(dt)
    end
end

function game.draw()
    if game.state == "title" then
        ui.drawTitle()
    elseif game.state == "level_select" then
        ui.drawLevelSelect(level.count(), save.getData())
    elseif game.state == "playing" then
        board.draw()
        ui.drawHUD(game.currentLevel, game.moveCount)
    elseif game.state == "clear" then
        board.draw()
        ui.drawClear(game.currentLevel, game.moveCount)
    end
end

function game.startLevel(levelNum)
    game.currentLevel = levelNum
    game.moveCount = 0
    game.undoStack = {}
    local data = level.get(levelNum)
    board.init(data)
    input.init(board, {
        onCarMoved = game.onCarMoved,
        onClear = game.onClear,
    })
    game.state = "playing"
end

function game.onCarMoved(snapshot)
    table.insert(game.undoStack, snapshot)
    game.moveCount = game.moveCount + 1
end

function game.undo()
    if #game.undoStack > 0 then
        local snapshot = table.remove(game.undoStack)
        board.restore(snapshot)
        game.moveCount = game.moveCount - 1
    end
end

function game.reset()
    game.startLevel(game.currentLevel)
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
        end
    elseif game.state == "clear" then
        ui.clearClick(x, y, game)
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
end

function game.keypressed(key)
    if game.state == "playing" then
        if key == "u" then
            game.undo()
        elseif key == "r" then
            game.reset()
        end
    end
end

return game
