local ui = {}

local BUTTON_W = 220
local BUTTON_H = 52

-- Fonts
local titleFont = nil
local subtitleFont = nil
local bodyFont = nil
local smallFont = nil

-- Hover tracking
local mouseX, mouseY = 0, 0
-- Button hover animation
local hoverAlpha = 0

function ui.loadFonts()
    titleFont = love.graphics.newFont(40)
    subtitleFont = love.graphics.newFont(22)
    bodyFont = love.graphics.newFont(20)
    smallFont = love.graphics.newFont(16)
end

function ui.update(dt)
    -- Could add hover animations here
end

function ui.mousemoved(x, y)
    mouseX, mouseY = x, y
end

local function isInside(mx, my, x, y, w, h)
    return mx >= x and mx <= x + w and my >= y and my <= y + h
end

local function isHovered(x, y, w, h)
    return isInside(mouseX, mouseY, x, y, w, h)
end

local function drawButton(text, x, y, w, h, font)
    w = w or BUTTON_W
    h = h or BUTTON_H
    font = font or bodyFont

    local hovered = isHovered(x, y, w, h)

    if hovered then
        love.graphics.setColor(0.4, 0.4, 0.48)
    else
        love.graphics.setColor(0.28, 0.28, 0.33)
    end
    love.graphics.rectangle("fill", x, y, w, h, 8, 8)

    if hovered then
        love.graphics.setColor(1, 1, 0.6, 0.8)
        love.graphics.setLineWidth(2)
    else
        love.graphics.setColor(0.6, 0.6, 0.65)
        love.graphics.setLineWidth(1)
    end
    love.graphics.rectangle("line", x, y, w, h, 8, 8)
    love.graphics.setLineWidth(1)

    love.graphics.setFont(font)
    local tw = font:getWidth(text)
    local th = font:getHeight()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(text, x + (w - tw) / 2, y + (h - th) / 2)
end

-- Title Screen

function ui.drawTitle()
    -- Background gradient feel
    love.graphics.setColor(0.1, 0.1, 0.14)
    love.graphics.rectangle("fill", 0, 0, 800, 600)

    -- Title
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1)
    local title = "GRIDLOCK"
    local tw = titleFont:getWidth(title)
    love.graphics.print(title, (800 - tw) / 2, 120)

    -- Subtitle
    love.graphics.setFont(subtitleFont)
    love.graphics.setColor(0.6, 0.6, 0.65)
    local subtitle = "A Parking Puzzle"
    local sw = subtitleFont:getWidth(subtitle)
    love.graphics.print(subtitle, (800 - sw) / 2, 170)

    -- Divider line
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(300, 210, 500, 210)

    local bx = (800 - BUTTON_W) / 2
    drawButton("Start", bx, 245)
    drawButton("Level Select", bx, 315)
    drawButton("Exit", bx, 385)

    -- Level update status
    local levelMod = require("src.level")
    love.graphics.setFont(smallFont)
    if levelMod.updateStatus == "done" and levelMod.newLevelsCount > 0 then
        love.graphics.setColor(0.4, 0.8, 0.4)
        local msg = levelMod.updateMessage
        love.graphics.print(msg, (800 - smallFont:getWidth(msg)) / 2, 440)
    end

    -- Level count
    love.graphics.setColor(0.4, 0.4, 0.45)
    local countText = levelMod.count() .. " levels"
    love.graphics.print(countText, (800 - smallFont:getWidth(countText)) / 2, 460)

    -- Footer
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0.35, 0.35, 0.4)
    local footer = "Drag to move cars"
    local fw = smallFont:getWidth(footer)
    love.graphics.print(footer, (800 - fw) / 2, 560)
end

function ui.titleClick(x, y, game)
    local bx = (800 - BUTTON_W) / 2

    if isInside(x, y, bx, 245, BUTTON_W, BUTTON_H) then
        game.startLevel(1)
    elseif isInside(x, y, bx, 315, BUTTON_W, BUTTON_H) then
        game.state = "level_select"
    elseif isInside(x, y, bx, 385, BUTTON_W, BUTTON_H) then
        love.event.quit()
    end
end

-- Level Select

function ui.drawLevelSelect(levelCount, saveData)
    love.graphics.setColor(0.1, 0.1, 0.14)
    love.graphics.rectangle("fill", 0, 0, 800, 600)

    love.graphics.setFont(subtitleFont)
    love.graphics.setColor(1, 1, 1)
    local header = "Level Select"
    local hw = subtitleFont:getWidth(header)
    love.graphics.print(header, (800 - hw) / 2, 30)

    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(300, 60, 500, 60)

    local cols = 5
    local btnSize = 72
    local gap = 16
    local startX = (800 - (cols * (btnSize + gap) - gap)) / 2
    local startY = 90

    love.graphics.setFont(bodyFont)

    for i = 1, levelCount do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local bx = startX + col * (btnSize + gap)
        local by = startY + row * (btnSize + gap)

        local hovered = isHovered(bx, by, btnSize, btnSize)

        if saveData.cleared[i] then
            love.graphics.setColor(0.15, 0.45, 0.25)
        elseif hovered then
            love.graphics.setColor(0.4, 0.4, 0.48)
        else
            love.graphics.setColor(0.28, 0.28, 0.33)
        end
        love.graphics.rectangle("fill", bx, by, btnSize, btnSize, 8, 8)

        if hovered then
            love.graphics.setColor(1, 1, 0.6, 0.8)
            love.graphics.setLineWidth(2)
        else
            love.graphics.setColor(0.5, 0.5, 0.55)
            love.graphics.setLineWidth(1)
        end
        love.graphics.rectangle("line", bx, by, btnSize, btnSize, 8, 8)
        love.graphics.setLineWidth(1)

        -- Level number
        love.graphics.setColor(1, 1, 1)
        local text = tostring(i)
        local tw = bodyFont:getWidth(text)
        local th = bodyFont:getHeight()
        love.graphics.print(text, bx + (btnSize - tw) / 2, by + (btnSize - th) / 2)

        -- Checkmark for cleared
        if saveData.cleared[i] then
            love.graphics.setFont(smallFont)
            love.graphics.setColor(0.5, 1, 0.5)
            love.graphics.print("Clear", bx + (btnSize - smallFont:getWidth("Clear")) / 2, by + btnSize - 18)
            love.graphics.setFont(bodyFont)
        end
    end

    drawButton("Back", (800 - BUTTON_W) / 2, 520)
end

function ui.levelSelectClick(x, y, game)
    local level = require("src.level")
    local cols = 5
    local btnSize = 72
    local gap = 16
    local startX = (800 - (cols * (btnSize + gap) - gap)) / 2
    local startY = 90

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

    if isInside(x, y, (800 - BUTTON_W) / 2, 520, BUTTON_W, BUTTON_H) then
        game.state = "title"
    end
end

-- HUD

local HUD_BTN_W = 110
local HUD_BTN_H = 42

function ui.drawHUD(levelNum, moveCount, hintUsed)
    -- Top bar background
    love.graphics.setColor(0.12, 0.12, 0.15, 0.9)
    love.graphics.rectangle("fill", 0, 0, 800, 48)

    love.graphics.setFont(bodyFont)
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.print("Level " .. levelNum, 20, 12)

    love.graphics.setColor(0.8, 0.8, 0.5)
    local movesText = "Moves: " .. moveCount
    if hintUsed then
        movesText = movesText .. "  (Hint)"
    end
    local mw = bodyFont:getWidth(movesText)
    love.graphics.print(movesText, 800 - mw - 20, 12)

    -- Bottom bar background
    love.graphics.setColor(0.12, 0.12, 0.15, 0.9)
    love.graphics.rectangle("fill", 0, 552, 800, 48)

    drawButton("Undo", 12, 555, HUD_BTN_W, HUD_BTN_H, smallFont)
    drawButton("Reset", 132, 555, HUD_BTN_W, HUD_BTN_H, smallFont)
    drawButton("Hint", 252, 555, HUD_BTN_W, HUD_BTN_H, smallFont)
    drawButton("Menu", 800 - HUD_BTN_W - 12, 555, HUD_BTN_W, HUD_BTN_H, smallFont)
end

function ui.hudClick(x, y, game)
    if isInside(x, y, 12, 555, HUD_BTN_W, HUD_BTN_H) then
        game.undo()
        return true
    elseif isInside(x, y, 132, 555, HUD_BTN_W, HUD_BTN_H) then
        game.reset()
        return true
    elseif isInside(x, y, 252, 555, HUD_BTN_W, HUD_BTN_H) then
        game.hint()
        return true
    elseif isInside(x, y, 800 - HUD_BTN_W - 12, 555, HUD_BTN_W, HUD_BTN_H) then
        game.state = "title"
        return true
    end
    return false
end

-- Clear Screen

function ui.drawClear(levelNum, moveCount, hintUsed)
    -- Dark overlay
    love.graphics.setColor(0, 0, 0, 0.65)
    love.graphics.rectangle("fill", 0, 0, 800, 600)

    -- Panel
    local panelW, panelH = 340, 320
    local px = (800 - panelW) / 2
    local py = (600 - panelH) / 2 - 20

    love.graphics.setColor(0.18, 0.18, 0.22)
    love.graphics.rectangle("fill", px, py, panelW, panelH, 12, 12)
    love.graphics.setColor(0.5, 0.5, 0.55)
    love.graphics.rectangle("line", px, py, panelW, panelH, 12, 12)

    -- Title
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 0.9, 0.3)
    local text = "Clear!"
    local tw = titleFont:getWidth(text)
    love.graphics.print(text, (800 - tw) / 2, py + 20)

    -- Level info
    love.graphics.setFont(subtitleFont)
    love.graphics.setColor(0.8, 0.8, 0.8)
    local info = "Level " .. levelNum
    local iw = subtitleFont:getWidth(info)
    love.graphics.print(info, (800 - iw) / 2, py + 70)

    -- Move count
    love.graphics.setFont(bodyFont)
    love.graphics.setColor(0.7, 0.8, 0.5)
    local moves = "Moves: " .. moveCount
    local mw = bodyFont:getWidth(moves)
    love.graphics.print(moves, (800 - mw) / 2, py + 100)

    if hintUsed then
        love.graphics.setFont(smallFont)
        love.graphics.setColor(0.8, 0.6, 0.3)
        local hintText = "Hint used"
        local hw = smallFont:getWidth(hintText)
        love.graphics.print(hintText, (800 - hw) / 2, py + 120)
    end

    -- Buttons
    local bx = (800 - BUTTON_W) / 2
    drawButton("Next Level", bx, py + 145)
    drawButton("Retry", bx, py + 205)
    drawButton("Level Select", bx, py + 265)
end

function ui.clearClick(x, y, game)
    local panelH = 320
    local py = (600 - panelH) / 2 - 20
    local bx = (800 - BUTTON_W) / 2

    if isInside(x, y, bx, py + 145, BUTTON_W, BUTTON_H) then
        game.nextLevel()
    elseif isInside(x, y, bx, py + 205, BUTTON_W, BUTTON_H) then
        game.reset()
    elseif isInside(x, y, bx, py + 265, BUTTON_W, BUTTON_H) then
        game.state = "level_select"
    end
end

return ui
