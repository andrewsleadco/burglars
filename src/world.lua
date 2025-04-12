local Chunk = require('src/chunk')
local Physics = require('src/physics')

local World = {}
World.__index = World

function World.new(width, height)
    local self = setmetatable({}, World)
    self.width = width
    self.height = height
    self.chunks = {}
    self.physics = Physics.new()
    self.debris = {}
    
    -- Initialize chunks
    for x = 1, width do
        self.chunks[x] = {}
        for y = 1, height do
            -- Generate terrain (simple example)
            local material = Chunk.EMPTY
            
            -- Ground level
            if y > height * 0.7 then
                material = Chunk.DIRT
                
                -- Stone below dirt
                if y > height * 0.8 then
                    material = Chunk.STONE
                end
            end
            
            self.chunks[x][y] = Chunk.new(x, y, material)
        end
    end
    
    return self
end

function World:getChunk(x, y)
    if x < 1 or x > self.width or y < 1 or y > self.height then
        return nil
    end
    return self.chunks[x][y]
end

function World:destroyChunk(x, y, force)
    local chunk = self:getChunk(x, y)
    if not chunk then return false end
    
    local destroyed, material = chunk:damage(force or 1)
    
    if destroyed then
        -- Create debris
        self.physics:createDebris(x, y, material)
        
        -- Check surrounding chunks for stability
        self:checkStability(x, y)
        return true
    end
    
    return false
end

function World:checkStability(x, y)
    -- Simple stability check: chunks without support fall
    for checkX = x-1, x+1 do
        for checkY = y-1, y+1 do
            local chunk = self:getChunk(checkX, checkY)
            if chunk and chunk.material ~= Chunk.EMPTY then
                -- Check if chunk has support beneath it
                local below = self:getChunk(checkX, checkY + 1)
                if not below or below.material == Chunk.EMPTY then
                    -- No support, mark for falling
                    self.physics:addFallingChunk(checkX, checkY, chunk.material)
                    chunk.material = Chunk.EMPTY
                end
            end
        end
    end
end

function World:update(dt)
    -- Update physics
    self.physics:update(dt, self)
end

function World:draw()
    -- Draw visible chunks (culling would be added here)
    for x = 1, self.width do
        for y = 1, self.height do
            self.chunks[x][y]:draw()
        end
    end
    
    -- Draw falling debris
    self.physics:draw()
end

return World