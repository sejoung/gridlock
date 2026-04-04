local game = require("src.game")

function love.load()
    love.graphics.setBackgroundColor(0.15, 0.15, 0.18)

    -- Window icon
    local iconInfo = love.filesystem.getInfo("assets/icon.png")
    if iconInfo then
        local iconData = love.image.newImageData("assets/icon.png")
        love.window.setIcon(iconData)
    end

    game.load()
end

function love.update(dt)
    game.update(dt)
end

function love.draw()
    game.draw()
end

function love.mousepressed(x, y, button)
    game.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
    game.mousereleased(x, y, button)
end

function love.mousemoved(x, y, dx, dy)
    game.mousemoved(x, y, dx, dy)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
    game.keypressed(key)
end
