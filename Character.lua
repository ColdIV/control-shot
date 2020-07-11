local Class = require('libs.Class')

local Character = Class({
    shot = false,
    shotCD = 0,
    shotMaxCD = 0.25,
    control = "ai",
    width = 32,
    height = 32,
    speed = 100,
    cLine = {1, 0, 0},
    cFill = {0, 0, 0},
    cNCFill = {0.5, 0.5, 0.5}, -- "no control"
    projectileSpeed = 150,
    projectileWidth = 16,
    projectileHeight = 16
})

function Character:getNewPos(x, y, direction, speed, dt)
    local newX = x + (direction[4] * (speed * dt)) - (direction[2] * (speed * dt))
    local newY = y + (direction[3] * (speed * dt)) - (direction[1] * (speed * dt))

    return newX, newY
end

function Character:update(controls, width, height, dt)
    self:move(controls, width, height, dt)
    self:moveProjectiles(width, height, dt)
end

function Character:move(direction, width, height, dt)
    self.facing = self.facing or {1, 0, 0, 0, 0}
    for i = 1, 4 do
        if direction[i] == 1 then
            for j = 1, #direction do
                self.facing[j] = direction[j]
            end
            break
        end
    end

    if self.shotCD > 0 then
        self.shotCD = self.shotCD - 1 * dt
        if self.shotCD < 0 then self.shotCD = 0 end
    end

    if direction[5] == 1 then
        if self.shotCD == 0 then
            self:shoot(self.facing, dt)
            self.shotCD = self.shotMaxCD
        end
    end

    local newX, newY = self:getNewPos(self.x, self.y, direction, self.speed, dt)

    -- check map bounds
    if newX > width - self.width then newX = width - self.width
    elseif newX < 0 then newX = 0 end
    if newY > height - self.height then newY = height - self.height
    elseif newY < 0 then newY = 0 end

    self.x = newX
    self.y = newY
end

function Character:moveProjectiles(width, height, dt)
    width = tonumber(width)
    height = tonumber(height)
    self.projectiles = self.projectiles or {}

    for i = 1, #self.projectiles do
        if self.projectiles[i].active == true then

            local newX, newY = self:getNewPos(self.projectiles[i].x, self.projectiles[i].y, self.projectiles[i].direction, self.projectiles[i].speed, dt)

            -- check map bounds, @TODO: add some sort of explosion on contact?
            if newX > width then self.projectiles[i].active = false
            elseif newX < 0 - self.projectiles[i].width then self.projectiles[i].active = false end
            if newY > height then self.projectiles[i].active = false
            elseif newY < 0 - self.projectiles[i].height then self.projectiles[i].active = false end

            self.projectiles[i].x = newX
            self.projectiles[i].y = newY
        end
    end
end

function Character:draw() 
    love.graphics.setColor(self.cLine)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    love.graphics.setColor(self.cFill)
    love.graphics.rectangle("fill", self.x + 2, self.y + 2, self.width - 4, self.height - 4)

    self:drawProjectiles()
end

function Character:drawProjectiles() 
    for i = 1, #self.projectiles do
        if self.projectiles[i].active == true then
            love.graphics.setColor(self.projectiles[i].color)
            love.graphics.circle("fill", self.projectiles[i].x + self.projectileWidth / 2, self.projectiles[i].y  + self.projectileHeight / 2, self.projectileWidth / 2)
            -- love.graphics.rectangle("fill", self.projectiles[i].x, self.projectiles[i].y, self.projectiles[i].width, self.projectiles[i].height)
        end
    end
end

function Character:createProjectile()
    for i = 1, #self.projectiles do
        if self.projectiles[i].active == false then
            return i
        end
    end

    table.insert(self.projectiles, {})
    return #self.projectiles
end

function Character:shoot(direction, dt)
    self.projectiles = self.projectiles or {}
   
    local index = self:createProjectile()
    
    self.projectiles[index].direction = {}
    for i = 1, #direction do
        self.projectiles[index].direction[i] = direction[i]
    end
    self.projectiles[index].x = self.x + self.projectileWidth / 2
    self.projectiles[index].y = self.y + self.projectileHeight / 2
    self.projectiles[index].width = self.projectileWidth
    self.projectiles[index].height = self.projectileHeight
    self.projectiles[index].speed = self.projectileSpeed
    self.projectiles[index].color = self.cFill
    self.projectiles[index].active = true
end

function Character:getPos()
    return self.x, self.y
end

return Character