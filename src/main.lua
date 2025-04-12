-- Load other modules
local World = require('src/world')
local Player = require('src/player')
local Camera = require('src/camera')

-- Global variables
local world
local player
local camera

function love.load()
    -- Initialize world
    world = World.new(200, 100) -- 200x100 chunks
    
    -- Create player
    player = Player.new(100, 100)
    
    -- Set up camera
    camera = Camera.new()
end

function love.update(dt)
    -- Update world physics
    world:update(dt)
    
    -- Update player
    player:update(dt, world)
    
    -- Update camera to follow player
    camera:follow(player.x, player.y)
end

function love.draw()
    -- Begin camera transformation
    camera:set()
    
    -- Draw world
    world:draw()
    
    -- Draw player
    player:draw()
    
    -- End camera transformation
    camera:unset()
    
    -- Draw UI (if any)
    -- Add UI code here
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
    
    -- Handle player input
    player:keypressed(key)
end