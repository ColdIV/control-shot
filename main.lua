local o_ten_one = require "libs.o-ten-one"
local Game = require('Game')

local splashScreenActive = true
local game = Game:new()

function love.load()
	game:load()
	
	splash = o_ten_one()
	splash.onDone = function() splashScreenActive = false end
end

function love.draw()
	if splashScreenActive then
		splash:draw()
	else
		game:draw()
	end
end

function love.update(dt)
	if splashScreenActive then
		splash:update(dt)
	else
		game:update(dt)
	end
end

function love.mousereleased(x, y, button)
	if not splashScreenActive then
		game:onClick(x, y, button)
	end
end

function love.keypressed(key, scancode, isrepeat)
	if splashScreenActive then
		splash:skip()
	else
		game:keyPressed(key, scancode, isrepeat)
	end
end

function love.keyreleased(key)
	game:keyReleased(key)
 end