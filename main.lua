local player

function love.load()
    local screen_width = love.graphics.getWidth()
    local screen_height = love.graphics.getHeight()


    player = {
        w = 32,
        h = 32,
        speed = 200 -- pixels per second
    }

    player.x = screen_width / 2 - player.w / 2
    player.y = screen_height - player.h - 10
end

function love.draw() -- Executed in loop to draw the screen
    love.graphics.rectangle("fill", player.x, player.y, player.w, player.h)
end

function love.update(dt) -- Executed on every frame to calculate the logic
    -- love.keyboard.isDown(key) returns true while key is pressed.
    -- dt (delta time): time since the last frame

    if love.keyboard.isDown("right") then
        player.x = player.x + player.speed * dt
    end
    if love.keyboard.isDown("left") then
        player.x = player.x - player.speed * dt
    end
end
