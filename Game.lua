local Class = require('libs.Class')
local Menu = require('libs.Menu')
local Character = require('Character')
local Projectile = require('Projectile')

local Game = Class({
	title = 'Control Shot',
	author = '',
    width = '600',
    height = '500',
    flags = {resizable=false, vsync=false},
	running = false,
	scale = 1,
	xoffset = 0,
	yoffset = 0,
})

local DEBUG = true

function Game:load()
	math.randomseed(os.time())
    love.window.setTitle(self.title)
	love.window.setMode(self.width, self.height, self.flags)
	local icon = love.image.newImageData("icon.png")
	love.window.setIcon(icon)
	
	-- sounds
	self.sounds = {}
	self.sounds.shoot = love.audio.newSource("sounds/shoot.wav", "static")
	self.sounds.foeShoot = love.audio.newSource("sounds/foeShoot.wav", "static")
	self.sounds.heroHit = love.audio.newSource("sounds/heroHit.wav", "static")
	self.sounds.explosion = love.audio.newSource("sounds/explosion.wav", "static")
	self.sounds.foeHit = love.audio.newSource("sounds/foeHit.wav", "static")
	self.sounds.wallHit = love.audio.newSource("sounds/wallHit.wav", "static")
	self.sounds.switchBack = love.audio.newSource("sounds/switchBack.wav", "static")
	self.sounds.gamestart = love.audio.newSource("sounds/gamestart.wav", "static")
	self.sounds.gameover = love.audio.newSource("sounds/gameover.wav", "static")

	self.resetOnStart = false
    -- workaround, elements={}, elementIndices={} are required here unfortunately
    
	-- Menu
	self.firstStart = true
	self.menu = Menu:new({elements = {}, elementIndices = {}, headline = 'Control Shot', gameWidth = self.width, gameHeight = self.height, author = self.author})
    self.menu:setColorText(0, 0, 0, 1)
    self.menu:setColorBackground(1, 1, 1, 1)
	self.menu:addElement('Play', function()
		if self.resetOnStart then
			self:playSound(self.sounds.gamestart)
			self:reset()
		else
			if self.firstStart == true then
				self:playSound(self.sounds.gamestart)
				self.firstStart = false
			end
		end
		self.running = true
		self.menu:hide() 
	end)
    self.menu:addElement('Fullscreen', function() self.menu:renameElement(self:toggleFullscreen()) end)
    self.menu:addElement('Quit', function() love.event.quit(0) end)
	self.menu:show()
	
	-- game
	self:reset()
	self.font = love.graphics.newFont(24)
	self.smallFont = love.graphics.newFont(12)
	self.bigFont = love.graphics.newFont(60)
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
	self.ais = {}
	self.aiKeys = {"ai-follow", "ai-turret", "ai-patrol"}
	self.ais["ai-follow"] = {
		control = 'ai-follow',
		cLine = {1, 0, 0},
		cFill = {1, 0, 0},
		speed = 50,
		width = 32,
		height = 32,
		shotMaxCD = 0.25
	}
	self.ais["ai-turret"] = {
		control = 'ai-turret',
		cLine = {0.75, 0.5, 0.12},
		cFill = {0.75, 0.5, 0.12},
		speed = 0,
		width = 32,
		height = 32,
		shotMaxCD = 1.5
	}
	self.ais["ai-patrol"] = {
		control = 'ai-patrol',
		cLine = {0.25, 0.5, 0.75},
		cFill = {0.25, 0.5, 0.75},
		speed = 50,
		width = 32,
		height = 32,
		shotMaxCD = 1
	}
	self.projectiles = {}
	self.explosions = {}

	self.score = 0
	self.scoreColor = {1, 1, 1, 1}
	self.scoreText = {}
	self.scoreTextDuration = 0.75
	self.scoreBonusText = {}
	self.scoreBonusText["homesweethome"] = "Home Sweet Home!"

	self.countdowns = {}
	self.foeSpawn = true
	self.spawnAmount = 1
	self.spawnAmounts = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}

	-- self.running = true
end

function Game:playSound(sound)
	local clone = sound:clone()
	clone:play()
end

function Game:aiAct(i)
	local w, a, s, d, space = 0, 0, 0, 0, 0
	local foe = self.foes[i]
	if foe.control == 'ai-follow' then
		if self.hero.x < foe.x then a = 1
		elseif self.hero.x > foe.x then d = 1 end
		if self.hero.y < foe.y then w = 1
		elseif self.hero.y > foe.y then s = 1 end
	elseif foe.control == 'ai-turret' then
		if self.hero.x < foe.x - foe.width then a = 1
		elseif self.hero.x > foe.x + foe.width then d = 1 end
		if self.hero.y < foe.y - foe.height then w = 1
		elseif self.hero.y > foe.y + foe.height then s = 1 end
		space = 1
	elseif foe.control == 'ai-patrol' then
		if math.sqrt(math.pow(self.hero.x - foe.x, 2) + math.pow(self.hero.y - foe.y, 2)) < self.width / 4 then
			if self.hero.x < foe.x - foe.width then a = 1
			elseif self.hero.x > foe.x + foe.width then d = 1 end
			if self.hero.y < foe.y - foe.height then w = 1
			elseif self.hero.y > foe.y + foe.height then s = 1 end
			space = 1
		else
			foe.direction = foe.direction or {0, 0, 0, 0, 0}

			if foe.x <= foe.width * 3 and foe.y >= self.height - foe.height * 3 then w = 1
			elseif foe.x >= self.width - foe.width * 3 and foe.y >= self.height - foe.height * 3 then a = 1
			elseif foe.x >= self.width - foe.width * 3 and foe.y <= foe.height * 3 then s = 1
			elseif foe.x <= foe.width * 3 and foe.y <= foe.height * 3 then d = 1
			elseif foe.direction[1] == 0 and foe.direction[2] == 0 and foe.direction[3] == 0 and foe.direction[4] == 0 then
				-- find close corner
				local sa = math.sqrt(math.pow(0 - foe.x, 2) + math.pow(self.height - foe.y, 2))
				local sd = math.sqrt(math.pow(self.width - foe.x, 2) + math.pow(self.height - foe.y, 2))
				local wd = math.sqrt(math.pow(self.width - foe.x, 2) + math.pow(0 - foe.y, 2))
				local wa = math.sqrt(math.pow(0 - foe.x, 2) + math.pow(0 - foe.y, 2))
				local closest = math.min(math.min(wa, wd), math.min(sd, sa))
				if closest == wa then w = 1 a = 1
				elseif closest == wd then w = 1 a = 1
				elseif closest == sd then s = 1 d = 1
				elseif closest == sa then s = 1 a = 1 end
			else return foe.direction end

			self.foes[i].direction = {w, a, s, d, space}
		end
	end

	return {w, a, s, d, space}
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

function Game:spawnFoe(x, y, ai)
	x = x or 50
	y = y or 50
	ai = ai or 'ai-follow'
	local index = self:createFoe()
	self.foes[index] = Character:new({
		control = ai,
		cLine = self.ais[ai].cLine,
		cFill = self.ais[ai].cFill,
		speed = self.ais[ai].speed,
		width = self.ais[ai].width,
		height = self.ais[ai].height,
		x = x,
		y = y,
		shotMaxCD = self.ais[ai].shotMaxCD
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

	-- countdowns
	for i = 1, #self.countdowns do
		if self.countdowns[i].active == true then
			if self.countdowns[i].time > 0 then
				self.countdowns[i].time = self.countdowns[i].time - 1 * dt
			elseif self.countdowns[i].time < 0 then
				self.countdowns[i].time = 0
				self.countdowns[i].func()
				self.countdowns[i].active = false
			end
		end
	end

	-- spawns
	if self.foeSpawn == true then
		self.foeSpawn = false
		for i = 1, self.spawnAmount do
			local x, y = math.random(Character.width, self.width - Character.width), math.random(Character.height, self.height - Character.height)
			local ai = self.aiKeys[math.random(1, #self.aiKeys)]
			self:countdown(5, function () 
				self:spawnFoe(x, y, ai)
				self.foeSpawn = true
			end, self.ais[ai].cFill, x, y)
		end
		self.spawnAmount = self.spawnAmounts[math.random(1, math.min(self.spawnAmount + 1, #self.spawnAmounts))]
	end

	-- controls
	self.hero:update(self.controls, tostring(self.width), tostring(self.height), dt)
	-- did hero shoot?
    if self.controls[5] == 1 then
		if self.hero:shoot() == true then
			self:playSound(self.sounds.shoot)
            self:shoot(self.hero.x, self.hero.y, self.hero.facing, self.hero.cFill, self.hero.control, dt)
        end
    end

	-- update foes
	for i = 1, #self.foes do
		if self.foes[i].dead == false and self.foes[i].control ~= 'player' and self.foes[i].control ~= 'none' then
			local direction = self:aiAct(i)
			self.foes[i]:update(direction, tostring(self.width), tostring(self.height), dt)

			-- did foe shoot?
			if self.foes[i].facing[5] == 1 then
				if self.foes[i]:shoot() == true then
					self:playSound(self.sounds.foeShoot)
					self:shoot(self.foes[i].x, self.foes[i].y, self.foes[i].facing, self.foes[i].cFill, self.foes[i].control, dt)
				end
			end

			-- has the foe tackled the hero or its body?
			local contact = false
			for j = 1, #self.foes do
				if self.foes[j].control == 'none' and self.foes[j].dead == false then
					contact = self.foes[i]:collision(self.foes[j].x, self.foes[j].y, self.foes[j].width, self.foes[j].height)
				end
			end

			contact = contact or self.foes[i]:collision(self.hero.x, self.hero.y, self.hero.width, self.hero.height)
			if contact == true then
				self:playSound(self.sounds.heroHit)
				self:over()
			end
		end
	end

	-- update projectiles
	for i = 1, #self.projectiles do
		if self.projectiles[i].active == true then
			if self.projectiles[i]:update(self.width, self.height, dt) == false then
				self:explosion(self.projectiles[i].x, self.projectiles[i].y, dt)
				self:playSound(self.sounds.wallHit)
			end

			-- collision
			if self.projectiles[i].control ~= 'player' then
				if self.projectiles[i]:collision(self.hero.x, self.hero.y, self.hero.width, self.hero.height) then
					self.projectiles[i].active = false
					self:explosion(self.projectiles[i].x, self.projectiles[i].y, dt)
					self:playSound(self.sounds.explosion)
					self:over()
				end
			end

			for j = 1, #self.foes do
				if self.foes[j].dead == false and (self.projectiles[i].control == 'player' or self.foes[j].control == 'none') then
					if self.projectiles[i]:collision(self.foes[j].x, self.foes[j].y, self.foes[j].width, self.foes[j].height) then
						if self.projectiles[i].control ~= 'player' and self.foes[j].control == 'none' then
							self.projectiles[i].active = false
							self:explosion(self.projectiles[i].x, self.projectiles[i].y, dt)
							self:playSound(self.sounds.explosion)
							self:over()
						else
							self.projectiles[i].active = false							
							if self.foes[j].control == 'none' then
								self:playSound(self.sounds.switchBack)
							else
								self:playSound(self.sounds.foeHit)
								self:explosion(self.projectiles[i].x, self.projectiles[i].y, dt)
							end
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

function Game:countdown(time, func, color, x, y)
	self.countdowns = self.countdowns or {}
	color = color or {1, 1, 1, 0.5}
	x = x or -1
	y = y or -1

	local newCountdown = {
		time = time,
		func = func,
		x = x,
		y = y,
		color = color,
		active = true
	}

	for i = 1, #self.countdowns do 
		if self.countdowns[i].time == 0 then
			self.countdowns[i] = newCountdown
			return
		end
	end

	table.insert(self.countdowns, newCountdown)
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
	self.running = false
	self.resetOnStart = true
	self:playSound(self.sounds.gameover)
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
		
		-- print help
		love.graphics.setColor({1, 1, 1, 1})
		love.graphics.printf("Move with W, A, S ,D\nShoot with SPACE\nYou take over the enemy you shot, leaving your shell exposed\n\nIncrease your score to infinity and beyond!\n\n\nNote: Buttons don't work properly in fullscreen!", self.smallFont, 0, self.height / 2 + 20, self.width, "center")
	else
		-- draw border
		love.graphics.setColor(self.hero.cLine)
		love.graphics.rectangle("line", 0, 0, self.width, self.height)

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

		-- draw countdowns
		for i = 1, #self.countdowns do
			if self.countdowns[i].active == true and self.countdowns[i].x ~= -1 and self.countdowns[i].y ~= -1 then
				love.graphics.setColor(self.countdowns[i].color)
				love.graphics.printf(math.floor(self.countdowns[i].time) + 1, self.font, self.countdowns[i].x, self.countdowns[i].y, self.width)
			end
		end

		-- draw score
		love.graphics.setColor(self.scoreColor)
		love.graphics.printf(math.floor(self.score), self.font, 0, 10, self.width, "center")
		for i = 1, #self.scoreText do
			if self.scoreText[i][2] > 0 then
				love.graphics.printf(self.scoreText[i][1], self.smallFont, 0 + 10 * i, 10 + 25 * i, self.width, "center")
			end
		end

		if self.running == false then
			love.graphics.setColor({1, 1, 1, 1})
			love.graphics.printf("Game Over", self.bigFont, 0, self.height / 2 - 60, self.width, "center")
			love.graphics.printf("Press [ESC] to get back to the menu", self.smallFont, 0, self.height / 2 + 20, self.width, "center")
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
		print ("FPS: " .. love.timer.getFPS())
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