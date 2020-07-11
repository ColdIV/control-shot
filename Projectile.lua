local Class = require('libs.Class')

local Projectile = Class({
    control = "ai",
    width = 16,
    height = 16,
    speed = 150,
    color = {1, 0, 0},
    active = true,
    direction = {0, 0, 0, 0, 0}
})

function Projectile:getNewPos(x, y, speed, dt)
    local newX = x + (self.direction[4] * (speed * dt)) - (self.direction[2] * (speed * dt))
    local newY = y + (self.direction[3] * (speed * dt)) - (self.direction[1] * (speed * dt))

    return newX, newY
end

function Projectile:update(width, height, dt)
    width = tonumber(width)
    height = tonumber(height)
    return self:move(width, height, dt)
end

function Projectile:move(width, height, dt)
    local newX, newY = self:getNewPos(self.x, self.y, self.speed, dt)

    if newX > width then self.active = false
    elseif newX < 0 - self.width then self.active = false end
    if newY > height then self.active = false
    elseif newY < 0 - self.height then self.active = false end

    self.x = newX
    self.y = newY

    return self.active
end

function Projectile:collision(x, y, width, height)
    if self.x < x + width and self.x + self.width > x and self.y < y + height and self.y + self.height > y then
        self.active = false
        return true
    end

    return false
end

function Projectile:draw() 
    love.graphics.setColor(self.color)
    love.graphics.circle("fill", self.x + self.width / 2, self.y  + self.height / 2, self.width / 2)
end

return Projectile