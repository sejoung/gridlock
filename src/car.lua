local car = {}
local carTypes = require("src.car_types")

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

    if c.dir == "H" then
        cellW = c.len * board.CELL_SIZE
        cellH = board.CELL_SIZE
    else
        cellW = board.CELL_SIZE
        cellH = c.len * board.CELL_SIZE
    end

    if c.image then
        local imgW = c.image:getWidth()
        local imgH = c.image:getHeight()

        -- Sprite is vertical (pointing up). For H cars, rotate 90° CW.
        if c.dir == "H" then
            -- After 90° CW rotation: sprite width becomes height and vice versa
            local scaleX = (cellH - pad * 2) / imgW
            local scaleY = (cellW - pad * 2) / imgH
            local scale = math.min(scaleX, scaleY)

            local drawW = imgW * scale
            local drawH = imgH * scale

            -- Rotate 90° CW around center of the cell area
            local cx = sx + cellW / 2
            local cy = sy + cellH / 2

            if c.selected then
                love.graphics.setColor(0.7, 0.9, 1.0)
            else
                love.graphics.setColor(1, 1, 1)
            end

            love.graphics.draw(c.image,
                cx, cy,
                math.pi / 2,
                scale, scale,
                imgW / 2, imgH / 2)
        else
            -- Vertical: use sprite as-is
            local scaleX = (cellW - pad * 2) / imgW
            local scaleY = (cellH - pad * 2) / imgH
            local scale = math.min(scaleX, scaleY)

            local drawW = imgW * scale
            local drawH = imgH * scale

            local cx = sx + cellW / 2
            local cy = sy + cellH / 2

            if c.selected then
                love.graphics.setColor(0.7, 0.9, 1.0)
            else
                love.graphics.setColor(1, 1, 1)
            end

            love.graphics.draw(c.image,
                cx, cy,
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
