-- Virtual resolution system using coordinate transform
-- Renders directly to screen at native resolution (sharp text/UI)
-- while using virtual 800x600 coordinate system
local screen = {}

local VIRTUAL_W = 800
local VIRTUAL_H = 600

local scale = 1
local offsetX = 0
local offsetY = 0
local actualW = VIRTUAL_W
local actualH = VIRTUAL_H

function screen.getVirtualSize()
    return VIRTUAL_W, VIRTUAL_H
end

function screen.load()
    local w, h = love.graphics.getDimensions()
    -- Fallback if dimensions are 0 (web build edge case)
    if w == 0 or h == 0 then
        w, h = VIRTUAL_W, VIRTUAL_H
    end
    screen.resize(w, h)
end

function screen.resize(w, h)
    if w <= 0 or h <= 0 then return end
    actualW = w
    actualH = h

    local scaleX = w / VIRTUAL_W
    local scaleY = h / VIRTUAL_H
    scale = math.min(scaleX, scaleY)

    offsetX = math.floor((w - VIRTUAL_W * scale) / 2)
    offsetY = math.floor((h - VIRTUAL_H * scale) / 2)
end

-- Convert actual screen coordinates to virtual coordinates
function screen.toVirtual(x, y)
    local vx = (x - offsetX) / scale
    local vy = (y - offsetY) / scale
    return vx, vy
end

-- Start rendering with virtual coordinate system
function screen.beginDraw()
    love.graphics.clear(0, 0, 0)

    -- Set up transform: translate + scale
    love.graphics.push()
    love.graphics.translate(offsetX, offsetY)
    love.graphics.scale(scale, scale)

    -- Clear virtual area with background color
    love.graphics.setColor(0.1, 0.1, 0.14)
    love.graphics.rectangle("fill", 0, 0, VIRTUAL_W, VIRTUAL_H)
end

-- End rendering
function screen.endDraw()
    love.graphics.pop()
end

return screen
