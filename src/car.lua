local car = {}
local carTypes = require("src.car_types")
local anim = require("src.anim")

-- Cache loaded images
local imageCache = {}

local function loadImage(path)
    if not imageCache[path] then
        local success, img = pcall(love.graphics.newImage, path)
        if success then
            img:setFilter("nearest", "nearest")
            imageCache[path] = img
        end
    end
    return imageCache[path]
end

function car.new(data)
    local typeDef = carTypes[data.type]
    assert(typeDef, "Unknown car type: " .. tostring(data.type))

    local c = {
        id = data.id,
        x = data.x,
        y = data.y,
        len = typeDef.len,
        dir = data.dir,
        isGoal = (data.id == "goal"),
        selected = false,
        image = loadImage("assets/cars/" .. typeDef.sprite),
    }
    return c
end

function car.occupies(c, gx, gy)
    for i = 0, c.len - 1 do
        local cx, cy
        if c.dir == "H" then
            cx, cy = c.x + i, c.y
        else
            cx, cy = c.x, c.y + i
        end
        if cx == gx and cy == gy then
            return true
        end
    end
    return false
end

function car.draw(c, board)
    local sx, sy = board.gridToScreen(c.x, c.y)
    local pad = 4
    local cellW, cellH

    -- Apply animation offset
    local ox, oy = anim.getOffset(c.id)
    sx = sx + ox
    sy = sy + oy

    if c.dir == "H" then
        cellW = c.len * board.CELL_SIZE
        cellH = board.CELL_SIZE
    else
        cellW = board.CELL_SIZE
        cellH = c.len * board.CELL_SIZE
    end

    -- Selection glow (drawn behind the car)
    if c.selected then
        love.graphics.setColor(1, 1, 0.5, 0.3)
        love.graphics.rectangle("fill", sx, sy, cellW, cellH, 8, 8)
        love.graphics.setColor(1, 1, 0.4, 0.7)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", sx + 1, sy + 1, cellW - 2, cellH - 2, 8, 8)
        love.graphics.setLineWidth(1)
    end

    if c.image then
        local imgW = c.image:getWidth()
        local imgH = c.image:getHeight()

        if c.selected then
            love.graphics.setColor(0.8, 0.95, 1.0)
        else
            love.graphics.setColor(1, 1, 1)
        end

        local centerX = sx + cellW / 2
        local centerY = sy + cellH / 2

        if c.dir == "H" then
            local scaleX = (cellH - pad * 2) / imgW
            local scaleY = (cellW - pad * 2) / imgH
            local scale = math.min(scaleX, scaleY)

            love.graphics.draw(c.image,
                centerX, centerY,
                math.pi / 2,
                scale, scale,
                imgW / 2, imgH / 2)
        else
            local scaleX = (cellW - pad * 2) / imgW
            local scaleY = (cellH - pad * 2) / imgH
            local scale = math.min(scaleX, scaleY)

            love.graphics.draw(c.image,
                centerX, centerY,
                0,
                scale, scale,
                imgW / 2, imgH / 2)
        end
    else
        -- Fallback: colored rectangle
        local w = cellW - pad * 2
        local h = cellH - pad * 2

        if c.isGoal then
            love.graphics.setColor(0.85, 0.25, 0.25)
        elseif c.selected then
            love.graphics.setColor(0.4, 0.7, 0.9)
        else
            love.graphics.setColor(0.3, 0.5, 0.7)
        end

        love.graphics.rectangle("fill", sx + pad, sy + pad, w, h, 6, 6)
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.rectangle("line", sx + pad, sy + pad, w, h, 6, 6)
    end
end

return car
