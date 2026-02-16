local K = require("constants")

local score
local player
local enemies
local coins
local enemy_spawn_timer
local coin_spawn_timer

local game_state -- "menu", "options" "playing", "gameover"

local img_coin

local sfx_coin
local sfx_hit

local font_title
local font_game

local menu_selection = 1                        -- 1=play, 2=options
local difficulty_index = 2                      -- 1=easy, 2=normal, 3=hard
local difficulties = {
    { name = "EASY",   spawn_rate_mult = 1.5 }, -- 50% slower (more easy)
    { name = "NORMAL", spawn_rate_mult = 1.0 }, -- normal velocity
    { name = "HARD",   spawn_rate_mult = 0.6 }  -- 40% faster (more hard)
}

local checkCollision, resetGame, drawGame, drawMenu, drawGameover, drawOptions


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
    img_coin = love.graphics.newImage("assets/sprites/coin.png")

    game_state = "menu"
    resetGame()
end

function love.draw()
    love.graphics.setColor(1, 1, 1)

    if game_state == "menu" then
        drawMenu()
    elseif game_state == "options" then
        drawOptions()
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
            local mult = difficulties[difficulty_index].spawn_rate_mult

            local base_rate = K.ENEMY_SPAWN_RATE * mult

            local dynamic_time = base_rate - (score * 0.01)

            local min_limit = 0.2 * mult
            enemy_spawn_timer = math.max(min_limit, dynamic_time)

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
        if key == "up" then
            menu_selection = menu_selection - 1
            if menu_selection < 1 then menu_selection = 2 end
        elseif key == "down" then
            menu_selection = menu_selection + 1
            if menu_selection > 2 then menu_selection = 1 end
        end
        if key == "return" or key == "space" or key == "z" then
            if menu_selection == 1 then
                game_state = "playing"
                resetGame()
            elseif menu_selection == 2 then
                game_state = "options"
            end
        end
    elseif game_state == "options" then
        if key == "left" then
            difficulty_index = difficulty_index - 1
            if difficulty_index < 1 then difficulty_index = 3 end
        elseif key == "right" then
            difficulty_index = difficulty_index + 1
            if difficulty_index > 3 then difficulty_index = 1 end
        end
        if key == "return" or key == "space" or key == "escape" or key == "z" then
            game_state = "menu"
        end
    elseif game_state == "gameover" then
        if key == "return" or key == "space" or key == "z" then
            game_state = "menu"
        end
    end
    if key == "escape" and game_state == "menu" then
        love.event.quit()
    end
end

function drawMenu()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()

    local text_play = "PLAY GAME"
    local text_opt = "OPTIONS"

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(font_title)
    love.graphics.printf(K.GAME_TITLE, 0, h / 3, w, "center")
    love.graphics.setFont(font_game)

    if menu_selection == 1 then
        text_play = "> " .. text_play .. " <"
        love.graphics.setColor(1, 1, 0)
    else
        love.graphics.setColor(1, 1, 1)
    end
    love.graphics.printf(text_play, 0, h / 2, w, "center")

    if menu_selection == 2 then
        text_opt = "> " .. text_opt .. " <"
        love.graphics.setColor(1, 1, 0)
    else
        love.graphics.setColor(1, 1, 1)
    end
    love.graphics.printf(text_opt, 0, h / 2 + 40, w, "center")
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
    love.graphics.setColor(1, 1, 1)
    for _, coin in ipairs(coins) do
        love.graphics.draw(img_coin, coin.x, coin.y)
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
    love.graphics.setFont(font_title)
    love.graphics.printf("GAME OVER", 0, h / 3, w, "center")
    love.graphics.setFont(font_game)

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Final score: " .. score, 0, h / 2, w, "center")
    love.graphics.printf("Press START to Menu", 0, h / 2 + 30, w, "center")
end

function drawOptions()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(font_title)
    love.graphics.printf("OPTIONS", 0, h / 4, w, "center")

    love.graphics.setFont(font_game)
    love.graphics.printf("Difficulty:", 0, h / 2 - 20, w, "center")

    local difficulty_name = "< " .. difficulties[difficulty_index].name .. " >"

    love.graphics.setColor(0.5, 1, 0.5)
    love.graphics.printf(difficulty_name, 0, h / 2 + 20, w, "center")

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Press START to return", 0, h - 50, w, "center")
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
