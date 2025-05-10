-- main.lua
local player = {}
local tiles = {}
local tileSize = 4
local gravity = 800
local destroyRange = 20 * tileSize
local particles = {}
local camera = { x = 0, y = 0 }
local fallingBlocks = {}

function love.load()
    player.x = 100
    player.y = 50
    player.width = 20
    player.height = 40
    player.speed = 200
    player.jumpForce = -350
    player.vx = 0
    player.vy = 0
    player.onGround = false
    player.tool = "Hammer" 

    local worldWidth = 400
    local worldHeight = 200

    for y = 1, worldHeight do
        tiles[y] = {}
        for x = 1, worldWidth do
            if y >= worldHeight - 3 then
                tiles[y][x] = 2 -- indestructible
            elseif (y >= worldHeight - 10 and y <= worldHeight - 8) then
                tiles[y][x] = 1 -- destructible yellow
            else
                tiles[y][x] = 0
            end
        end
    end

    -- Build a house for testing
    local houseHeight = 10
    local houseWidth = 20
    local houseBottom = worldHeight - 4
    local houseTop = houseBottom - houseHeight + 1
    local houseLeft = math.floor(worldWidth / 2 - houseWidth / 2)

    for y = houseTop, houseBottom do
        for x = houseLeft, houseLeft + houseWidth - 1 do
            local isWall = (x == houseLeft or x == houseLeft + houseWidth - 1)
            local isRoof = (y == houseTop)
            if isWall or isRoof then
                tiles[y][x] = 1
            end
        end
    end

    -- Optional: spawn player in front of the house
    player.x = (houseLeft + houseWidth / 2) * tileSize
    player.y = (houseTop - 5) * tileSize
end


function love.update(dt)
    -- Player movement
    if love.keyboard.isDown("a") then
        player.vx = -player.speed
    elseif love.keyboard.isDown("d") then
        player.vx = player.speed
    else
        player.vx = 0
    end

    if love.keyboard.isDown("space") and player.onGround then
        player.vy = player.jumpForce
        player.onGround = false
    end

    player.vy = player.vy + gravity * dt
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

    -- Update falling blocks
    for i = #fallingBlocks, 1, -1 do
        local b = fallingBlocks[i]
        b.vy = b.vy + gravity * dt
        b.y = b.y + b.vy * dt

        local tileBelowY = math.floor((b.y + tileSize) / tileSize) + 1
        local tileX = math.floor(b.x / tileSize) + 1

        if tiles[tileBelowY] and tiles[tileBelowY][tileX] ~= 0 then
            local snapY = math.floor(b.y / tileSize) + 1
            local snapX = math.floor(b.x / tileSize) + 1
            tiles[snapY][snapX] = b.tileType
            table.remove(fallingBlocks, i)
        end
    end

    -- Update camera
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
                        player.y = math.floor(tileTop - player.height + 0.5)
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
    love.graphics.translate(-camera.x, -camera.y)

    -- Draw tiles
    for y = 1, #tiles do
        for x = 1, #tiles[y] do
            if tiles[y][x] == 1 then
                love.graphics.setColor(1, 1, 0)
                love.graphics.rectangle("fill", (x - 1) * tileSize, (y - 1) * tileSize, tileSize, tileSize)
            elseif tiles[y][x] == 2 then
                love.graphics.setColor(0.4, 0.4, 0.4)
                love.graphics.rectangle("fill", (x - 1) * tileSize, (y - 1) * tileSize, tileSize, tileSize)
            end
        end
    end

    -- Draw falling blocks
    for _, b in ipairs(fallingBlocks) do
        love.graphics.setColor(1, 1, 0)
        love.graphics.rectangle("fill", b.x, b.y, tileSize, tileSize)
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

    -- Draw current tool name on HUD
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Tool: " .. player.tool, 10, 10)
end

function love.mousepressed(x, y, button)
    if button == 1 then
        local worldX = x + camera.x
        local worldY = y + camera.y

        local tileX = math.floor(worldX / tileSize) + 1
        local tileY = math.floor(worldY / tileSize) + 1

        if tiles[tileY] and tiles[tileY][tileX] == 1 then
            local tileCenterX = (tileX - 0.5) * tileSize
            local tileCenterY = (tileY - 0.5) * tileSize
            local dx = (player.x + player.width / 2) - tileCenterX
            local dy = (player.y + player.height / 2) - tileCenterY
            local distance = math.sqrt(dx * dx + dy * dy)

            if distance <= destroyRange then
                if player.tool == "Hammer" then
                tiles[tileY][tileX] = 0
                spawnParticles(tileCenterX, tileCenterY)
                checkFloatingCluster(tileX, tileY - 1)  -- above
                checkFloatingCluster(tileX - 1, tileY)  -- left
                checkFloatingCluster(tileX + 1, tileY)  -- right
                end
            end
        end
    end
end

function checkFloatingCluster(x, y)
    if not tiles[y] or not tiles[y][x] then return end
    if tiles[y][x] ~= 1 then return end -- only destructible

    local below = tiles[y+1] and tiles[y+1][x]
    if below and below ~= 0 then return end -- tile is supported

    -- Convert to falling block
    local block = {
        x = (x - 1) * tileSize,
        y = (y - 1) * tileSize,
        vx = 0, vy = 0,
        tileType = tiles[y][x]
    }
    table.insert(fallingBlocks, block)
    tiles[y][x] = 0

    -- Recursively check above/left/right
    checkFloatingCluster(x, y - 1)
    checkFloatingCluster(x - 1, y)
    checkFloatingCluster(x + 1, y)
end

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
