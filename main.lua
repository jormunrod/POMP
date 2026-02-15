local K = require("constants")

local player
local enemies
local spawn_timer

function love.load()
    local screen_width = love.graphics.getWidth()
    local screen_height = love.graphics.getHeight()

    -- Create player
    player = {
        x = 0,
        y = 0,
        w = K.PLAYER_SIZE,
        h = K.PLAYER_SIZE,
        speed = K.PLAYER_SPEED
    }

    player.x = screen_width / 2 - player.w / 2
    player.y = screen_height - player.h - K.PLAYER_BOTTOM_MARGIN

    -- Enemies
    enemies = {}
    spawn_timer = 0
end

function love.draw() -- Executed in loop to draw the screen
    love.graphics.rectangle("fill", player.x, player.y, player.w, player.h)
    for i, enemy in ipairs(enemies) do
        love.graphics.rectangle("fill", enemy.x, enemy.y, enemy.w, enemy.h)
    end
end

function love.update(dt) -- Executed on every frame to calculate the logic
    -- love.keyboard.isDown(key) returns true while key is pressed.
    -- dt (delta time): time since the last frame

    -- Player movement
    if love.keyboard.isDown("right") then
        player.x = player.x + player.speed * dt
    end
    if love.keyboard.isDown("left") then
        player.x = player.x - player.speed * dt
    end

    -- Enemies spawn
    spawn_timer = spawn_timer - dt
    if spawn_timer <= 0 then
        spawn_timer = K.ENEMY_SPAWN_RATE

        local new_enemy = {
            x = love.math.random(0, love.graphics.getWidth() - K.ENEMY_SIZE),
            y = -K.ENEMY_SIZE,
            w = K.ENEMY_SIZE,
            h = K.ENEMY_SIZE,
            speed = K.ENEMY_SPEED
        }

        table.insert(enemies, new_enemy)
    end

    -- Enemies movement and cleanup
    for i = #enemies, 1, -1 do
        local enemy = enemies[i]

        enemy.y = enemy.y + enemy.speed * dt

        if checkCollision(player, enemy) then
            love.load() -- Restart the game
            return
        end

        if enemy.y > love.graphics.getHeight() then
            table.remove(enemies, i)
        end
    end
end

function checkCollision(a, b)
    return (a.x < b.x + b.w) and
        (a.x + a.w > b.x) and
        (a.y < b.y + b.h) and
        (a.y + a.h > b.y)
end
