-- main.lua
local player = {}
local tiles = {}
local tileSize = 32
local gravity = 800
local destroyRange = 3 * tileSize
local particles = {}
local camera = { x = 0, y = 0 } -- 🎥 Add a camera

function love.load()
    -- Load player
    player.x = 100
    player.y = 100
    player.width = 20
    player.height = 40
    player.speed = 200
    player.jumpForce = -350
    player.vx = 0
    player.vy = 0
    player.onGround = false

    -- Generate a simple world
    for y = 1, 25 do
        tiles[y] = {}
        for x = 1, 50 do
            if y >= 22 then
                tiles[y][x] = 2 -- Solid indestructible ground
            elseif (y >= 15 and y <= 17) then
                tiles[y][x] = 1 -- Destructible yellow blocks
            else
                tiles[y][x] = 0 -- Air
            end
        end
    end
end

function love.update(dt)
    -- Handle input
    if love.keyboard.isDown("a") then
        player.vx = -player.speed
    elseif love.keyboard.isDown("d") then
        player.vx = player.speed
    else
        player.vx = 0
    end

    -- Jumping
    if love.keyboard.isDown("space") and player.onGround then
        player.vy = player.jumpForce
        player.onGround = false
    end

    -- Apply gravity
    player.vy = player.vy + gravity * dt

    -- Move and handle collisions
    player.x = player.x + player.vx * dt
    handleCollisions("x")

    player.y = player.y + player.vy * dt
    handleCollisions("y")

    -- Update particles
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(particles, i)
        end
    end

    -- Update camera to center on player, removes subpixel shake during collision. 
    camera.x = math.floor(player.x + player.width / 2 - love.graphics.getWidth() / 2)
    camera.y = math.floor(player.y + player.height / 2 - love.graphics.getHeight() / 2)

end

function handleCollisions(axis)
    local left = math.floor(player.x / tileSize) + 1
    local right = math.floor((player.x + player.width - 1) / tileSize) + 1
    local top = math.floor(player.y / tileSize) + 1
    local bottom = math.floor((player.y + player.height - 1) / tileSize) + 1

    for y = top, bottom do
        for x = left, right do
            if tiles[y] and tiles[y][x] ~= 0 then
                local tileLeft = (x - 1) * tileSize
                local tileRight = tileLeft + tileSize
                local tileTop = (y - 1) * tileSize
                local tileBottom = tileTop + tileSize

                if axis == "x" then
                    if player.vx > 0 then
                        player.x = tileLeft - player.width
                    elseif player.vx < 0 then
                        player.x = tileRight
                    end
                    player.vx = 0
                elseif axis == "y" then
                    if player.vy > 0 then
                        player.y = math.floor(tileTop - player.height + 0.5) -- snap to nearest pixel
                        player.vy = 0
                        player.onGround = true                    
                    elseif player.vy < 0 then
                        player.y = tileBottom
                        player.vy = 0
                    end
                end
            end
        end
    end
end

function love.draw()
    love.graphics.push()
    love.graphics.translate(-camera.x, -camera.y) -- 🎥 Shift everything

    -- Draw tiles
    for y = 1, #tiles do
        for x = 1, #tiles[y] do
            if tiles[y][x] == 1 then
                love.graphics.setColor(1, 1, 0) -- Yellow destructible
                love.graphics.rectangle("fill", (x-1)*tileSize, (y-1)*tileSize, tileSize, tileSize)
            elseif tiles[y][x] == 2 then
                love.graphics.setColor(0.4, 0.4, 0.4) -- Gray indestructible
                love.graphics.rectangle("fill", (x-1)*tileSize, (y-1)*tileSize, tileSize, tileSize)
            end
        end
    end

    -- Draw player
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", player.x, player.y, player.width, player.height)

    -- Draw particles
    for _, p in ipairs(particles) do
        love.graphics.setColor(1, 1, 0, p.life / p.maxLife)
        love.graphics.rectangle("fill", p.x, p.y, p.size, p.size)
    end

    love.graphics.pop()
end

function love.mousepressed(x, y, button)
    if button == 1 then -- Left click
        local worldX = x + camera.x
        local worldY = y + camera.y

        local tileX = math.floor(worldX / tileSize) + 1
        local tileY = math.floor(worldY / tileSize) + 1

        if tiles[tileY] and tiles[tileY][tileX] == 1 then
            -- Calculate distance from player to tile center
            local tileCenterX = (tileX - 0.5) * tileSize
            local tileCenterY = (tileY - 0.5) * tileSize
            local dx = (player.x + player.width / 2) - tileCenterX
            local dy = (player.y + player.height / 2) - tileCenterY
            local distance = math.sqrt(dx*dx + dy*dy)

            if distance <= destroyRange then
                tiles[tileY][tileX] = 0 -- Destroy tile
                spawnParticles(tileCenterX, tileCenterY)
            end
        end
    end
end

-- Andrew's plane edits

-- End of Andrew's Plane edits
function spawnParticles(x, y)
    for i = 1, 8 do
        local p = {
            x = x,
            y = y,
            vx = (math.random() - 0.5) * 200,
            vy = (math.random() - 1.5) * 200,
            size = math.random(2, 6),
            life = 1.0,
            maxLife = 1.0
        }
        table.insert(particles, p)
    end
end
