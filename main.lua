local game = require("src.game")
local screen = require("src.screen")

function love.load()
    -- Window icon
    local iconInfo = love.filesystem.getInfo("assets/ui/window_icon.png")
    if iconInfo then
        local iconData = love.image.newImageData("assets/ui/window_icon.png")
        love.window.setIcon(iconData)
    end

    screen.load()
    game.load()
end

function love.update(dt)
    game.update(dt)
end

function love.draw()
    screen.beginDraw()
    game.draw()
    screen.endDraw()
end

function love.resize(w, h)
    screen.resize(w, h)
end

function love.mousepressed(x, y, button)
    local vx, vy = screen.toVirtual(x, y)
    game.mousepressed(vx, vy, button)
end

function love.mousereleased(x, y, button)
    local vx, vy = screen.toVirtual(x, y)
    game.mousereleased(vx, vy, button)
end

function love.mousemoved(x, y, dx, dy)
    local vx, vy = screen.toVirtual(x, y)
    game.mousemoved(vx, vy, dx, dy)
end

-- Track only the first touch to prevent multi-touch confusion
local activeTouchId = nil

function love.touchpressed(id, x, y)
    if activeTouchId then return end
    activeTouchId = id
    local vx, vy = screen.toVirtual(x, y)
    game.mousepressed(vx, vy, 1)
end

function love.touchreleased(id, x, y)
    if id ~= activeTouchId then return end
    activeTouchId = nil
    local vx, vy = screen.toVirtual(x, y)
    game.mousereleased(vx, vy, 1)
end

function love.touchmoved(id, x, y, dx, dy)
    if id ~= activeTouchId then return end
    local vx, vy = screen.toVirtual(x, y)
    game.mousemoved(vx, vy, dx, dy)
end

function love.wheelmoved(x, y)
    game.wheelmoved(x, y)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
    game.keypressed(key)
end
