local Chunk = {}
Chunk.__index = Chunk

-- Materials
Chunk.EMPTY = 0
Chunk.DIRT = 1
Chunk.STONE = 2
Chunk.WOOD = 3
Chunk.METAL = 4

-- Properties for materials
local PROPERTIES = {
    [Chunk.EMPTY] = { solid = false, destructible = false, durability = 0 },
    [Chunk.DIRT] = { solid = true, destructible = true, durability = 1 },
    [Chunk.STONE] = { solid = true, destructible = true, durability = 3 },
    [Chunk.WOOD] = { solid = true, destructible = true, durability = 2 },
    [Chunk.METAL] = { solid = true, destructible = true, durability = 5 }
}

-- Colors for materials
local COLORS = {
    [Chunk.EMPTY] = {0, 0, 0, 0},
    [Chunk.DIRT] = {139/255, 69/255, 19/255},
    [Chunk.STONE] = {128/255, 128/255, 128/255},
    [Chunk.WOOD] = {160/255, 82/255, 45/255},
    [Chunk.METAL] = {192/255, 192/255, 192/255}
}

-- Size of chunks in pixels
local CHUNK_SIZE = 16

function Chunk.new(x, y, material)
    local self = setmetatable({}, Chunk)
    self.x = x
    self.y = y
    self.material = material or Chunk.EMPTY
    self.damaged = 0
    return self
end

function Chunk:damage(amount)
    if not PROPERTIES[self.material].destructible then
        return false
    end
    
    self.damaged = self.damaged + amount
    
    if self.damaged >= PROPERTIES[self.material].durability then
        -- Destroy the chunk
        local oldMaterial = self.material
        self.material = Chunk.EMPTY
        self.damaged = 0
        return true, oldMaterial
    end
    
    return false
end

function Chunk:draw()
    if self.material == Chunk.EMPTY then
        return
    end
    
    love.graphics.setColor(COLORS[self.material])
    love.graphics.rectangle("fill", 
        self.x * CHUNK_SIZE, 
        self.y * CHUNK_SIZE, 
        CHUNK_SIZE, 
        CHUNK_SIZE)
    
    -- Draw damage cracks if damaged
    if self.damaged > 0 then
        love.graphics.setColor(0, 0, 0, self.damaged / PROPERTIES[self.material].durability * 0.5)
        love.graphics.rectangle("fill", 
            self.x * CHUNK_SIZE, 
            self.y * CHUNK_SIZE, 
            CHUNK_SIZE, 
            CHUNK_SIZE)
    end
    
    love.graphics.setColor(1, 1, 1)
end

return Chunk