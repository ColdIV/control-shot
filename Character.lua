local Class = require('libs.Class')

local Character = Class({shot = false, control = "ai", width = 32, height = 32, speed = 100})

function Character:move(direction, width, height, dt)
    if direction[5] == 1 then
        self:shoot(direction, dt)
    end

    local newX = self.x + (direction[4] * (self.speed * dt)) - (direction[2] * (self.speed * dt))
    local newY = self.y + (direction[3] * (self.speed * dt)) - (direction[1] * (self.speed * dt))

    -- check map bounds
    if newX > width - self.width then newX = width - self.width
    elseif newX < 0 then newX = 0 end
    if newY > height - self.height then newY = height - self.height
    elseif newY < 0 then newY = 0 end

    self.x = newX
    self.y = newY
end

function Character:shoot(direction, dt)
end

function Character:getPos()
    return self.x, self.y
end

return Character