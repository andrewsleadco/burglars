function love.conf(t)
    t.window.title = "Destructible Side-Scroller"
    t.window.width = 800
    t.window.height = 600
    t.window.vsync = 1
    
    -- Disable unused modules to save memory
    t.modules.joystick = false
    t.modules.video = false
    
    -- Enable the modules we need
    t.modules.audio = true
    t.modules.graphics = true
    t.modules.keyboard = true
    t.modules.math = true
    t.modules.physics = true
    t.modules.sound = true
    
    -- Set identity for save files
    t.identity = "destructible-sidescroller"
end