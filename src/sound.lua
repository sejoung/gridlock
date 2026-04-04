-- Procedural sound effects using Love2D SoundData
local sound = {}

local sounds = {}
local SAMPLE_RATE = 44100

local function generateTone(freq, duration, volume, waveform)
    volume = volume or 0.3
    waveform = waveform or "sine"
    local samples = math.floor(SAMPLE_RATE * duration)
    local data = love.sound.newSoundData(samples, SAMPLE_RATE, 16, 1)

    for i = 0, samples - 1 do
        local t = i / SAMPLE_RATE
        local envelope = 1 - (i / samples)  -- fade out
        local value = 0

        if waveform == "sine" then
            value = math.sin(2 * math.pi * freq * t)
        elseif waveform == "square" then
            value = math.sin(2 * math.pi * freq * t) > 0 and 1 or -1
            value = value * 0.5
        elseif waveform == "noise" then
            value = (math.random() * 2 - 1)
        end

        data:setSample(i, value * volume * envelope)
    end

    return love.audio.newSource(data, "static")
end

local function generateSweep(freqStart, freqEnd, duration, volume)
    volume = volume or 0.3
    local samples = math.floor(SAMPLE_RATE * duration)
    local data = love.sound.newSoundData(samples, SAMPLE_RATE, 16, 1)

    for i = 0, samples - 1 do
        local t = i / SAMPLE_RATE
        local progress = i / samples
        local freq = freqStart + (freqEnd - freqStart) * progress
        local envelope = 1 - progress
        local value = math.sin(2 * math.pi * freq * t)
        data:setSample(i, value * volume * envelope)
    end

    return love.audio.newSource(data, "static")
end

function sound.load()
    sounds.select = generateTone(440, 0.08, 0.2, "sine")
    sounds.move = generateTone(520, 0.06, 0.15, "sine")
    sounds.invalid = generateTone(200, 0.15, 0.2, "square")
    sounds.clear = generateSweep(400, 800, 0.4, 0.25)
    sounds.click = generateTone(600, 0.04, 0.15, "sine")
    sounds.undo = generateTone(350, 0.08, 0.15, "sine")
end

function sound.play(name)
    local s = sounds[name]
    if s then
        s:stop()
        s:play()
    end
end

return sound
