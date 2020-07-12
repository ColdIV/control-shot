local Game = require('Game')

local game = Game:new()

function love.load()
	game:load()
end

function love.draw()
	game:draw()
end

function love.update(dt)
	if dt < 1/120 then love.timer.sleep(1/120-dt) end
	game:update(dt)
end

function love.mousereleased(x, y, button)
	game:onClick(x, y, button)
end

function love.keypressed(key, scancode, isrepeat)
	game:keyPressed(key, scancode, isrepeat)
end

function love.keyreleased(key)
	game:keyReleased(key)
 end