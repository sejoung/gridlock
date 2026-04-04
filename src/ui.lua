local ui = {}

local BUTTON_W = 180
local BUTTON_H = 44

local function drawButton(text, x, y, w, h)
    w = w or BUTTON_W
    h = h or BUTTON_H

    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.rectangle("fill", x, y, w, h, 6, 6)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.rectangle("line", x, y, w, h, 6, 6)

    local font = love.graphics.getFont()
    local tw = font:getWidth(text)
    local th = font:getHeight()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(text, x + (w - tw) / 2, y + (h - th) / 2)
end

local function isInside(mx, my, x, y, w, h)
    return mx >= x and mx <= x + w and my >= y and my <= y + h
end

-- Title Screen

function ui.drawTitle()
    love.graphics.setColor(1, 1, 1)
    local font = love.graphics.getFont()
    local title = "GRIDLOCK"
    local tw = font:getWidth(title)
    love.graphics.print(title, (800 - tw) / 2, 150)

    local subtitle = "A Parking Puzzle"
    local sw = font:getWidth(subtitle)
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print(subtitle, (800 - sw) / 2, 180)

    local bx = (800 - BUTTON_W) / 2
    drawButton("Start", bx, 280)
    drawButton("Level Select", bx, 340)
    drawButton("Exit", bx, 400)
end

function ui.titleClick(x, y, game)
    local bx = (800 - BUTTON_W) / 2

    if isInside(x, y, bx, 280, BUTTON_W, BUTTON_H) then
        game.startLevel(1)
    elseif isInside(x, y, bx, 340, BUTTON_W, BUTTON_H) then
        game.state = "level_select"
    elseif isInside(x, y, bx, 400, BUTTON_W, BUTTON_H) then
        love.event.quit()
    end
end

-- Level Select

function ui.drawLevelSelect(levelCount, saveData)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Level Select", 320, 40)

    local cols = 5
    local btnSize = 64
    local gap = 16
    local startX = (800 - (cols * (btnSize + gap) - gap)) / 2
    local startY = 100

    for i = 1, levelCount do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local bx = startX + col * (btnSize + gap)
        local by = startY + row * (btnSize + gap)

        if saveData.cleared[i] then
            love.graphics.setColor(0.2, 0.5, 0.3)
        else
            love.graphics.setColor(0.3, 0.3, 0.35)
        end
        love.graphics.rectangle("fill", bx, by, btnSize, btnSize, 6, 6)
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.rectangle("line", bx, by, btnSize, btnSize, 6, 6)

        love.graphics.setColor(1, 1, 1)
        local text = tostring(i)
        local font = love.graphics.getFont()
        local tw = font:getWidth(text)
        local th = font:getHeight()
        love.graphics.print(text, bx + (btnSize - tw) / 2, by + (btnSize - th) / 2)
    end

    drawButton("Back", (800 - BUTTON_W) / 2, 500)
end

function ui.levelSelectClick(x, y, game)
    local level = require("src.level")
    local cols = 5
    local btnSize = 64
    local gap = 16
    local startX = (800 - (cols * (btnSize + gap) - gap)) / 2
    local startY = 100

    for i = 1, level.count() do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local bx = startX + col * (btnSize + gap)
        local by = startY + row * (btnSize + gap)

        if isInside(x, y, bx, by, btnSize, btnSize) then
            game.startLevel(i)
            return
        end
    end

    if isInside(x, y, (800 - BUTTON_W) / 2, 500, BUTTON_W, BUTTON_H) then
        game.state = "title"
    end
end

-- HUD

function ui.drawHUD(levelNum, moveCount)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Level: " .. levelNum, 20, 10)
    love.graphics.print("Moves: " .. moveCount, 700, 10)

    local smallBtn = 80
    drawButton("Undo(U)", 20, 560, smallBtn, 30)
    drawButton("Reset(R)", 110, 560, smallBtn, 30)
    drawButton("Menu", 690, 560, smallBtn, 30)
end

function ui.hudClick(x, y, game)
    local smallBtn = 80
    if isInside(x, y, 20, 560, smallBtn, 30) then
        game.undo()
        return true
    elseif isInside(x, y, 110, 560, smallBtn, 30) then
        game.reset()
        return true
    elseif isInside(x, y, 690, 560, smallBtn, 30) then
        game.state = "title"
        return true
    end
    return false
end

-- Clear Screen

function ui.drawClear(levelNum, moveCount)
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, 800, 600)

    love.graphics.setColor(1, 1, 0.4)
    local text = "Level " .. levelNum .. " Clear!"
    local font = love.graphics.getFont()
    local tw = font:getWidth(text)
    love.graphics.print(text, (800 - tw) / 2, 180)

    love.graphics.setColor(1, 1, 1)
    local moves = "Moves: " .. moveCount
    local mw = font:getWidth(moves)
    love.graphics.print(moves, (800 - mw) / 2, 220)

    local bx = (800 - BUTTON_W) / 2
    drawButton("Next Level", bx, 300)
    drawButton("Retry", bx, 360)
    drawButton("Level Select", bx, 420)
end

function ui.clearClick(x, y, game)
    local bx = (800 - BUTTON_W) / 2

    if isInside(x, y, bx, 300, BUTTON_W, BUTTON_H) then
        game.nextLevel()
    elseif isInside(x, y, bx, 360, BUTTON_W, BUTTON_H) then
        game.reset()
    elseif isInside(x, y, bx, 420, BUTTON_W, BUTTON_H) then
        game.state = "level_select"
    end
end

return ui
