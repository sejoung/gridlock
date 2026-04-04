-- Animation utilities
local anim = {}

function anim.lerp(a, b, t)
    return a + (b - a) * t
end

function anim.smoothstep(t)
    t = math.max(0, math.min(1, t))
    return t * t * (3 - 2 * t)
end

-- Manages per-car visual offsets for smooth movement
local MOVE_DURATION = 0.1     -- seconds for move animation
local SHAKE_DURATION = 0.25   -- seconds for shake
local SHAKE_INTENSITY = 6     -- pixels

local carAnims = {}

function anim.reset()
    carAnims = {}
end

local function getAnim(carId)
    if not carAnims[carId] then
        carAnims[carId] = {
            offsetX = 0, offsetY = 0,     -- visual offset from grid pos
            targetX = 0, targetY = 0,
            moving = false, moveTimer = 0,
            shaking = false, shakeTimer = 0,
        }
    end
    return carAnims[carId]
end

function anim.startMove(carId, dx, dy, cellSize)
    local a = getAnim(carId)
    -- Start from negative offset (old position) and animate to 0
    a.offsetX = -dx * cellSize
    a.offsetY = -dy * cellSize
    a.targetX = 0
    a.targetY = 0
    a.moving = true
    a.moveTimer = 0
end

function anim.startShake(carId, dir)
    local a = getAnim(carId)
    a.shaking = true
    a.shakeTimer = 0
    a.shakeDir = dir  -- "H" or "V"
end

function anim.update(dt)
    for id, a in pairs(carAnims) do
        if a.moving then
            a.moveTimer = a.moveTimer + dt
            local t = math.min(a.moveTimer / MOVE_DURATION, 1)
            t = anim.smoothstep(t)
            a.offsetX = anim.lerp(a.offsetX, a.targetX, t)
            a.offsetY = anim.lerp(a.offsetY, a.targetY, t)
            if t >= 1 then
                a.offsetX = 0
                a.offsetY = 0
                a.moving = false
            end
        end
        if a.shaking then
            a.shakeTimer = a.shakeTimer + dt
            if a.shakeTimer >= SHAKE_DURATION then
                a.shaking = false
                a.offsetX = 0
                a.offsetY = 0
            else
                local progress = a.shakeTimer / SHAKE_DURATION
                local shake = math.sin(progress * math.pi * 4) * SHAKE_INTENSITY * (1 - progress)
                if a.shakeDir == "H" then
                    a.offsetX = shake
                    a.offsetY = 0
                else
                    a.offsetX = 0
                    a.offsetY = shake
                end
            end
        end
    end
end

function anim.getOffset(carId)
    local a = carAnims[carId]
    if a then
        return a.offsetX, a.offsetY
    end
    return 0, 0
end

function anim.isAnimating(carId)
    local a = carAnims[carId]
    if a then
        return a.moving or a.shaking
    end
    return false
end

return anim
