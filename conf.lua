function love.conf(t)
    t.title = "Gridlock"
    t.version = "11.4"

    t.window.width = 800
    t.window.height = 600
    t.window.resizable = true
    t.window.minwidth = 400
    t.window.minheight = 300

    t.modules.joystick = false
    t.modules.physics = false
end
