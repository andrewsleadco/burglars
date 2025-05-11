local player = {}
local tiles = {}
local tileSize = 4
local gravity = 800
local destroyRange = 20 * tileSize
local particles = {}
local camera = { x = 0, y = 0 }
local fallingBlocks = {}

-- Keypress tracking
love.keyboard.wasPressed = {}

function love.keypressed(key)
    love.keyboard.wasPressed[key] = true
end

-- Collision Stuff
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

-- Sprite stuff
local burglarSprite = {}
burglarSprite.idle = {}
burglarSprite.run = {}

function love.load()
    player = {
        x = 100, y = 50,
        width = 20, height = 40,
        speed = 200,
        jumpForce = -350,
        vx = 0, vy = 0,
        onGround = false,
        tool = "Hammer",
        anim = {
            state = "idle",
            frame = 1,
            timer = 0,
            speed = 0.15,
            flip = false
        }
    }

    burglarSprite.idle[1] = love.graphics.newImage("assets/burglar_idle.png")
    burglarSprite.run[1] = love.graphics.newImage("assets/burglar_run_0.png")
    burglarSprite.run[2] = love.graphics.newImage("assets/burglar_run_1.png")

    local worldWidth = 400
    local worldHeight = 200

    for y = 1, worldHeight do
        tiles[y] = {}
        for x = 1, worldWidth do
            if y >= worldHeight - 3 then
                tiles[y][x] = 2 -- indestructible
            elseif y >= worldHeight - 10 and y <= worldHeight - 8 then
                tiles[y][x] = 1 -- destructible yellow
            else
                tiles[y][x] = 0
            end
        end
    end

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

    player.x = (houseLeft + houseWidth / 2) * tileSize
    player.y = (houseTop - 5) * tileSize
end

function love.update(dt)
    local mx, my = love.mouse.getPosition()
    local worldMouseX = mx + camera.x
    local worldMouseY = my + camera.y
    local px = player.x + player.width / 2
    local py = player.y + player.height / 2
    player.aimAngle = math.atan2(worldMouseY - py, worldMouseX - px)

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

    player.anim.state = (player.vx ~= 0) and "run" or "idle"
    player.anim.flip = player.vx < 0
    local frames = burglarSprite[player.anim.state]
    player.anim.timer = player.anim.timer + dt
    if player.anim.timer >= player.anim.speed then
        player.anim.timer = 0
        player.anim.frame = (player.anim.frame % #frames) + 1
    end

    if love.keyboard.wasPressed["k"] then
        if player.tool == "Hammer" then
            activateHammer()
        end
    end

    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(particles, i)
        end
    end

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

    camera.x = math.floor(player.x + player.width / 2 - love.graphics.getWidth() / 2)
    camera.y = math.floor(player.y + player.height / 2 - love.graphics.getHeight() / 2)

    love.keyboard.wasPressed = {}
end

function love.draw()
    love.graphics.push()
    love.graphics.translate(-camera.x, -camera.y)

    for y = 1, #tiles do
        for x = 1, #tiles[y] do
            if tiles[y][x] == 1 then
                love.graphics.setColor(1, 1, 0)
            elseif tiles[y][x] == 2 then
                love.graphics.setColor(0.4, 0.4, 0.4)
            else
                goto continue
            end
            love.graphics.rectangle("fill", (x - 1) * tileSize, (y - 1) * tileSize, tileSize, tileSize)
            ::continue::
        end
    end

    for _, b in ipairs(fallingBlocks) do
        love.graphics.setColor(1, 1, 0)
        love.graphics.rectangle("fill", b.x, b.y, tileSize, tileSize)
    end

    local frames = burglarSprite[player.anim.state]
    local sprite = frames[player.anim.frame] or frames[1]
    local scaleX = player.anim.flip and -1 or 1
    local offsetX = player.anim.flip and sprite:getWidth() or 0
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(sprite, player.x + offsetX, player.y, 0, scaleX, 1)

    for _, p in ipairs(particles) do
        love.graphics.setColor(1, 1, 0, p.life / p.maxLife)
        love.graphics.rectangle("fill", p.x, p.y, p.size, p.size)
    end

    love.graphics.pop()
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
            local centerX = (tileX - 0.5) * tileSize
            local centerY = (tileY - 0.5) * tileSize
            local dx = (player.x + player.width / 2) - centerX
            local dy = (player.y + player.height / 2) - centerY
            local distance = math.sqrt(dx * dx + dy * dy)

            if distance <= destroyRange then
                tiles[tileY][tileX] = 0
                spawnParticles(centerX, centerY)
                checkFloatingCluster(tileX, tileY - 1)
                checkFloatingCluster(tileX - 1, tileY)
                checkFloatingCluster(tileX + 1, tileY)
            end
        end
    end
end

function activateHammer()
    local px = player.x + player.width / 2
    local py = player.y + player.height / 2
    local offset = 12
    local hitX = px + math.cos(player.aimAngle) * offset
    local hitY = py + math.sin(player.aimAngle) * offset
    local tileX = math.floor(hitX / tileSize) + 1
    local tileY = math.floor(hitY / tileSize) + 1

    if tiles[tileY] and tiles[tileY][tileX] == 1 then
        tiles[tileY][tileX] = 0
        spawnParticles((tileX - 0.5) * tileSize, (tileY - 0.5) * tileSize)
        checkFloatingCluster(tileX, tileY - 1)
        checkFloatingCluster(tileX - 1, tileY)
        checkFloatingCluster(tileX + 1, tileY)
    end
end

function checkFloatingCluster(x, y)
    if not tiles[y] or tiles[y][x] ~= 1 then return end
    local below = tiles[y + 1] and tiles[y + 1][x]
    if below and below ~= 0 then return end

    table.insert(fallingBlocks, {
        x = (x - 1) * tileSize,
        y = (y - 1) * tileSize,
        vx = 0, vy = 0,
        tileType = tiles[y][x]
    })
    tiles[y][x] = 0
    checkFloatingCluster(x, y - 1)
    checkFloatingCluster(x - 1, y)
    checkFloatingCluster(x + 1, y)
end

function spawnParticles(x, y)
    for i = 1, 8 do
        table.insert(particles, {
            x = x, y = y,
            vx = (math.random() - 0.5) * 200,
            vy = (math.random() - 1.5) * 200,
            size = math.random(2, 6),
            life = 1.0,
            maxLife = 1.0
        })
    end
end
