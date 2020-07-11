local Class = require('libs.Class')
local Menu = require('libs.Menu')
local Character = require('Character')
local Projectile = require('Projectile')

local Game = Class({
	title = 'Soul Shot',
	author = '',
    width = '960',
    height = '540',
    flags = {resizable=false, vsync=false},
	running = false,
	scale = 1,
	xoffset = 0,
	yoffset = 0,
})

local DEBUG = true

function Game:load()
    love.window.setTitle(self.title)
    love.window.setMode(self.width, self.height, self.flags)

	self.resetOnStart = false
    -- workaround, elements={}, elementIndices={} are required here unfortunately
    
	-- Menu
	self.menu = Menu:new({elements = {}, elementIndices = {}, headline = 'Menu', gameWidth = self.width, gameHeight = self.height, author = self.author})
    self.menu:setColorText(0, 0, 0, 1)
    self.menu:setColorBackground(1, 1, 1, 1)
	self.menu:addElement('Play', function()
		if self.resetOnStart then
			self:reset()
		else
			self.running = true
		end
		self.menu:hide() 
	end)
    self.menu:addElement('Fullscreen', function() self.menu:renameElement(self:toggleFullscreen()) end)
    self.menu:addElement('Quit', function() love.event.quit(0) end)
	self.menu:show()
	
	-- game
	self:reset()
	self.font = love.graphics.newFont(24)
	self.smallFont = love.graphics.newFont(12)
end

function Game:reset()
	self.resetOnStart = false
	self.firstChange = true
	self.lastChange = false
	self.controls = {0, 0, 0, 0, 0} -- w, a, s, d, space
	self.hero = Character:new({
		control = 'player',
		x = self.width / 2 - Character.width / 2,
		y = self.height / 2 - Character.height / 2,
		cLine = {0, 1, 0},
		cFill = {1, 1, 1}
	})

	self.foes = {}
	self.projectiles = {}
	self.explosions = {}

	self.score = 0
	self.scoreColor = {1, 1, 1, 1}
	self.scoreText = {}
	self.scoreTextDuration = 0.5
	self.scoreBonusText = {}
	self.scoreBonusText["homesweethome"] = "Home Sweet Home!"

	self.running = true
end

function Game:createFoe()
	self.foes = self.foes or {}

	for i = 1, #self.foes do
		if self.foes[i].dead == true then
			return i
		end
	end

	table.insert(self.foes, {})
	return #self.foes
end

function Game:spawnFoe()
	local index = self:createFoe()
	self.foes[index] = Character:new({
		control = 'ai',
		x = 50,
		y = 50,
		cLine = {1, 0, 0},
		cFill = {1, 0, 0}
	})
end

function Game:createProjectile()
	self.projectiles = self.projectiles or {}

    for i = 1, #self.projectiles do
        if self.projectiles[i].active == false then
            return i
        end
    end

    table.insert(self.projectiles, {})
    return #self.projectiles
end

function Game:shoot(x, y, direction, color, control, dt)
    local index = self:createProjectile()
	self.projectiles[index] = Projectile:new({
		control = control,
		x = x + Projectile.width / 2 + (Projectile.width * direction[4] * 2) - (Projectile.width * direction[2] * 2),
		y = y + Projectile.height / 2 + (Projectile.height * direction[3] * 2) - (Projectile.height * direction[1] * 2),
		color = color
	})

	self.projectiles[index].direction = {}
	for i = 1, #direction do
		self.projectiles[index].direction[i] = direction[i]
	end
end

function Game:createExplosion()
	self.explosions = self.explosions or {}

    for i = 1, #self.explosions do
        if self.explosions[i].active == false then
            return i
        end
    end

    table.insert(self.explosions, {})
    return #self.explosions
end

function Game:explosion(x, y, dt)
	local directions = {
		{1, 0, 0, 0, 0},
		{1, 1, 0, 0, 0},
		{1, 0, 0, 1, 0},
		{0, 0, 1, 0, 0},
		{0, 1, 1, 0, 0},
		{0, 0, 1, 1, 0},
		{0, 1, 0, 0, 0},
		{0, 0, 0, 1, 0}
	}

	local tmpControl = {}
	local particleSize = Projectile.width / 2
	for i = 1, #directions do
		local direction = directions[i]
		local index = self:createExplosion()
		self.explosions[index] = Projectile:new({
			control = tmpControl,
			width = particleSize,
			height = particleSize,
			x = x + particleSize / 2 + (particleSize * direction[4] * 2) - (particleSize * direction[2] * 2),
			y = y + particleSize / 2 + (particleSize * direction[3] * 2) - (particleSize * direction[1] * 2),
			color = {1, 1, 0},
			speed = 200
		})

		self.explosions[index].direction = {}
		for i = 1, #direction do
			self.explosions[index].direction[i] = direction[i]
		end
	end
end

function Game:update(dt)
	local x, y = self:translateCoords(love.mouse.getPosition())
	if self.menu:isVisible() then
        self.menu:update(dt, x, y)
	end
	
	-- check if menu is open
	if self.running == false then return end
	
	-- add to score over time
	self.score = self.score + (1 * dt * 100)
	for i = 1, #self.scoreText do
		if self.scoreText[i][2] > 0 then
			self.scoreText[i][2] = self.scoreText[i][2] - 1 * dt
		elseif self.scoreText[i][2] < 0 then
			self.scoreText[i][2] = 0
		end
	end

	-- controls
	self.hero:update(self.controls, tostring(self.width), tostring(self.height), dt)
	-- did hero shoot?
    if self.controls[5] == 1 then
        if self.hero:shoot() == true then
            self:shoot(self.hero.x, self.hero.y, self.hero.facing, self.hero.cFill, self.hero.control, dt)
        end
    end

	-- update foes
	for i = 1, #self.foes do
		if self.foes[i].dead == false and self.foes[i].control ~= 'player' and self.foes[i].control ~= 'none' then
			self.foes[i]:update({0, 0, 1, 1, 1}, tostring(self.width), tostring(self.height), dt)

			-- did foe shoot?
			if self.foes[i].facing[5] == 1 then
				if self.foes[i]:shoot() == true then
					self:shoot(self.foes[i].x, self.foes[i].y, self.foes[i].facing, self.foes[i].cFill, self.foes[i].control, dt)
				end
			end

			-- has the foe tackled the hero?
			local contact = self.foes[i]:collision(self.hero.x, self.hero.y, self.hero.width, self.hero.height)
			if contact == true then
				self:over()
			end
		end
	end

	-- update projectiles
	for i = 1, #self.projectiles do
		if self.projectiles[i].active == true then
			if self.projectiles[i]:update(self.width, self.height, dt) == false then
				self:explosion(self.projectiles[i].x, self.projectiles[i].y, dt)
			end

			-- collision
			if self.projectiles[i].control ~= 'player' then
				if self.projectiles[i]:collision(self.hero.x, self.hero.y, self.hero.width, self.hero.height) then
					self.projectiles[i].active = false
					self:explosion(self.projectiles[i].x, self.projectiles[i].y, dt)

					self:over()
				end
			else
				for j = 1, #self.foes do
					if self.foes[j].dead == false then
						if self.projectiles[i]:collision(self.foes[j].x, self.foes[j].y, self.foes[j].width, self.foes[j].height) then
							self.projectiles[i].active = false
							self:explosion(self.projectiles[i].x, self.projectiles[i].y, dt)

							self.foes[j].dead = true
							self:changeControl(j)
						end
					end
				end
			end
		end
	end

	-- update explosions
	for i = 1, #self.explosions do
		if self.explosions[i].active == true then
			self.explosions[i]:update(self.width, self.height, dt)

			-- collision with other explosions
			for j = 1, #self.explosions do
				if i ~= j and self.explosions[i].control ~= self.explosions[j].control then
					if self.explosions[i]:collision(self.explosions[j].x, self.explosions[j].y, self.explosions[j].width, self.explosions[j].height) then
						self.explosions[i].active = false
						self.explosions[j].active = false
					end
				end
			end

			-- collision with hero
			if self.explosions[i]:collision(self.hero.x, self.hero.y, self.hero.width, self.hero.height) then
				self.explosions[i].active = false
			end

			-- collision with foes
			for j = 1, #self.foes do
				if self.foes[j].dead == false then
					if self.explosions[i]:collision(self.foes[j].x, self.foes[j].y, self.foes[j].width, self.foes[j].height) then
						self.explosions[i].active = false
					end
				end
			end

			-- collision with projectiles
			for j = 1, #self.projectiles do
				if self.projectiles[j].active == true then
					if self.explosions[i]:collision(self.projectiles[j].x, self.projectiles[j].y, self.projectiles[j].width, self.projectiles[j].height) then
						self.explosions[i].active = false
					end
				end
			end
		end
	end
end

function Game:addScore(bonus, text)
	self.score = self.score + bonus
	for i = 1, #self.scoreText do
		if self.scoreText[i][2] == 0 then
			self.scoreText[i] = {text, self.scoreTextDuration}
			return
		end
	end

	table.insert(self.scoreText, {text, self.scoreTextDuration})
end

function Game:changeControl(foeIndex)
	-- if self.lastChange then
	-- 	self:addScore(250, '+250 Suicide :(')
	-- 	self:over()
	-- 	return
	-- end

	-- suicide prevention ;)
	local homesweethome = false
	if self.foes[foeIndex].control == 'none' then
		-- self.lastChange = true
		homesweethome = true
	end

	local tmpFoe = {}
	tmpFoe.x = self.foes[foeIndex].x
	tmpFoe.y = self.foes[foeIndex].y
	tmpFoe.cLine = self.foes[foeIndex].cLine

	-- score bonus
	if homesweethome then
		self:addScore(1000, '+250 ' .. self.scoreBonusText["homesweethome"])
		if self.scoreBonusText["homesweethome"] ~= "" then self.scoreBonusText["homesweethome"] =  "" end
	else
		self:addScore(500, '+500')
	end

	if self.firstChange then
		self.firstChange = false
		self.foes[foeIndex] = Character:new({
			control = 'none',
			x = self.hero.x,
			y = self.hero.y,
			cLine = self.hero.cLine,
			cFill = self.hero.cNCFill
		})
	end

	if homesweethome then self.firstChange = true end

	self.hero.x = tmpFoe.x
	self.hero.y = tmpFoe.y
	self.hero.cLine = tmpFoe.cLine
end

function Game:over()
	-- game over @TODO
	print("game over")
	self.running = false
	self.resetOnStart = true
end

function Game:draw()
	love.graphics.push()
	
	-- scale for fullscreen
	local width, height = love.graphics.getDimensions()
	if width ~= self.width or height ~= self.height then
		local xscale = width / self.width
		local yscale = height / self.height
		self.scale = math.min(xscale, yscale)
		
		self.xoffset = (width - self.width * self.scale) / 2
		self.yoffset = (height - self.height * self.scale) / 2
		
		love.graphics.translate(self.xoffset, self.yoffset)
		love.graphics.scale(self.scale, self.scale)
	end
	
	-- draw everything
	if self.menu:isVisible() then
        self.menu:draw()
	else
		-- draw game

		-- draw hero
		self.hero:draw()

		-- draw foes
		for i = 1, #self.foes do
			if self.foes[i].dead == false then
				self.foes[i]:draw()
			end
		end

		-- draw projectiles
		for i = 1, #self.projectiles do
			if self.projectiles[i].active == true then
				self.projectiles[i]:draw()
			end
		end

		-- draw explosions
		for i = 1, #self.explosions do
			if self.explosions[i].active == true then
				self.explosions[i]:draw()
			end
		end

		-- draw score
		love.graphics.setColor(self.scoreColor)
		love.graphics.printf(math.floor(self.score), self.font, 10, 10, self.width)
		for i = 1, #self.scoreText do
			if self.scoreText[i][2] > 0 then
				love.graphics.printf(self.scoreText[i][1], self.smallFont, 10 + 10 * i, 10 + 25 * i, self.width)
			end
		end
	end
	
	love.graphics.pop()
end

function Game:translateCoords(x, y)
	local translateX, translateY = x, y
	translateX = translateX / self.scale
	translateX = translateX - self.xoffset
	translateY = translateY / self.scale
	translateY = translateY - self.yoffset
	
	return translateX, translateY
end

function Game:onClick(x, y, button)
	x, y = self:translateCoords(x, y)
	
	if self.menu:isVisible() then
        self.menu:onClick(x, y, button)
    end
end

function Game:keyPressed(key, scancode, isrepeat)
	if key == "escape" then
		if self.menu:isVisible() and self.running then
			self.menu:hide()
			self.running = true
		else
			self.menu:show()
			self.running = false
		end
	elseif key == "f11" then
		self.menu:renameElement(self:toggleFullscreen())
	elseif key == "w" then
		self.controls[1] = 1
		self.controls[3] = 0
	elseif key == "a" then
		self.controls[2] = 1
		self.controls[4] = 0
	elseif key == "s" then
		self.controls[3] = 1
		self.controls[1] = 0
	elseif key == "d" then
		self.controls[4] = 1
		self.controls[2] = 0
	elseif key == "space" then
		self.controls[5] = 1
	end
end

function Game:keyReleased(key)
	if key == "w" then
		self.controls[1] = 0
	elseif key == "a" then
		self.controls[2] = 0
	elseif key == "s" then
		self.controls[3] = 0
	elseif key == "d" then
		self.controls[4] = 0
	elseif key == "space" then
		self.controls[5] = 0
	elseif key == "q" and DEBUG then
		self:spawnFoe() -- @TODO: remove, debug only
	end
end

function Game:toggleFullscreen()
	fullscreen, _ = love.window.getFullscreen()
	if fullscreen then 
		local x, y = love.mouse.getPosition()
		love.window.setFullscreen(false, "desktop")
		love.mouse.setPosition(self:translateCoords(x, y))
		return 'Window', 'Fullscreen'
	else
		local x, y = love.mouse.getPosition()
		local width, height = love.graphics.getDimensions()
		love.window.setFullscreen(true, "desktop")
		local newWidth, newHeight = love.graphics.getDimensions()
		love.mouse.setPosition(x * (newWidth / width), y * (newHeight / height))
		return 'Fullscreen', 'Window'
	end
end

return Game