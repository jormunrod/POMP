local K = require("constants")

local score
local player
local enemies
local coins
local enemy_spawn_timer
local coin_spawn_timer

local game_state -- "menu", "playing", "gameover"

local sfx_coin
local sfx_hit

local font_title
local font_game

local checkCollision, resetGame, drawGame, drawMenu, drawGameover


function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")

    love.math.setRandomSeed(os.time())

    --load fonts
    font_title = love.graphics.newFont("assets/fonts/kenney_pixel.ttf", 80)
    font_game = love.graphics.newFont("assets/fonts/kenney_pixel.ttf", 30)
    love.graphics.setFont(font_game)


    -- load sounds
    sfx_coin = love.audio.newSource("assets/sfx/coin.wav", "static")
    sfx_hit = love.audio.newSource("assets/sfx/hit.wav", "static")

    -- load images
    -- ...

    game_state = "menu"
    resetGame()
end

function love.draw()
    if game_state == "menu" then
        drawMenu()
    elseif game_state == "playing" then
        drawGame()
    elseif game_state == "gameover" then
        drawGameover()
    end
end

function love.update(dt) -- Executed on every frame to calculate the logic
    if game_state == "playing" then
        -- Player movement
        if love.keyboard.isDown("right") then
            player.x = player.x + player.speed * dt
        end
        if love.keyboard.isDown("left") then
            player.x = player.x - player.speed * dt
        end

        -- Map limits
        if player.x < 0 then
            player.x = 0
        end
        if player.x > love.graphics.getWidth() - player.w then
            player.x = love.graphics.getWidth() - player.w
        end

        -- Coins spawn
        coin_spawn_timer = coin_spawn_timer - dt
        if coin_spawn_timer <= 0 then
            coin_spawn_timer = K.COIN_SPAWN_RATE

            local new_coin = {
                x = love.math.random(0, love.graphics.getWidth() - K.COIN_SIZE),
                y = -K.COIN_SIZE,
                w = K.COIN_SIZE,
                h = K.COIN_SIZE,
                speed = K.COIN_SPEED
            }

            table.insert(coins, new_coin)
        end

        -- Coins movement and cleanup
        for i = #coins, 1, -1 do
            local coin = coins[i]

            coin.y = coin.y + coin.speed * dt

            if checkCollision(player, coin) then
                table.remove(coins, i)
                score = score + 1
                sfx_coin:clone():play()
            elseif coin.y > love.graphics.getHeight() then
                table.remove(coins, i)
            end
        end

        -- Enemies spawn
        enemy_spawn_timer = enemy_spawn_timer - dt
        if enemy_spawn_timer <= 0 then
            local dynamic_time = K.ENEMY_SPAWN_RATE - (score * 0.01)
            enemy_spawn_timer = math.max(0.2, dynamic_time)

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
                sfx_hit:clone():play()
                if player.lives > 1 then
                    player.lives = player.lives - 1
                else
                    player.lives = 0
                    game_state = "gameover"
                end
                table.remove(enemies, i)
            elseif enemy.y > love.graphics.getHeight() then
                table.remove(enemies, i)
            end
        end
    end
end

function love.keypressed(key)
    if game_state == "menu" then
        if key == "space" or key == "return" then
            game_state = "playing"
            resetGame()
        end
    elseif game_state == "gameover" then
        if key == "space" or key == "return" then
            game_state = "menu"
        end
    end

    if key == "escape" then
        love.event.quit()
    end
end

function drawMenu()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()

    local subtitle = "Press START to play"

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(font_title)
    love.graphics.printf(K.GAME_TITLE, 0, h / 3, w, "center")
    love.graphics.setFont(font_game)
    love.graphics.printf(subtitle, 0, h / 2, w, "center")
end

function drawGame()
    -- Draw player
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", player.x, player.y, player.w, player.h)

    -- Draw enemies
    love.graphics.setColor(1, 0.2, 0.2)
    for _, enemy in ipairs(enemies) do
        love.graphics.rectangle("fill", enemy.x, enemy.y, enemy.w, enemy.h)
    end

    -- Draw coins
    love.graphics.setColor(1, 1, 0)
    for _, coin in ipairs(coins) do
        love.graphics.rectangle("fill", coin.x, coin.y, coin.w, coin.h)
    end

    -- Draw UI
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Lives: " .. player.lives, 10, 10)
    love.graphics.print("Score: " .. score, 10, 30)
end

function drawGameover()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()

    love.graphics.setColor(1, 0, 0)
    love.graphics.printf("GAME OVER", 0, h / 3, w, "center")

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Final score: " .. score, 0, h / 2, w, "center")
    love.graphics.printf("Press START to Menu", 0, h / 2 + 30, w, "center")
end

function checkCollision(a, b)
    return (a.x < b.x + b.w) and
        (a.x + a.w > b.x) and
        (a.y < b.y + b.h) and
        (a.y + a.h > b.y)
end

function resetGame()
    local screen_width = love.graphics.getWidth()
    local screen_height = love.graphics.getHeight()

    -- Create player
    player = {
        x = screen_width / 2 - K.PLAYER_SIZE / 2,
        y = screen_height - K.PLAYER_SIZE - K.PLAYER_BOTTOM_MARGIN,
        w = K.PLAYER_SIZE,
        h = K.PLAYER_SIZE,
        speed = K.PLAYER_SPEED,
        lives = K.PLAYER_LIVES
    }

    -- Enemies
    enemies = {}
    enemy_spawn_timer = 0

    -- Coins
    coins = {}
    coin_spawn_timer = 0

    -- Score
    score = 0
end
