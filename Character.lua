local Class = require('libs.Class')

local Character = Class({shot = false, control = "ai", width = 32, height = 32, speed = 50})

function Character:move(direction, dt)
    if direction[5] == 1 then
        self:shoot(direction, dt)
    end
    self.x = self.x + (direction[4] * (self.speed * dt)) - (direction[2] * (self.speed * dt))
    self.y = self.y + (direction[3] * (self.speed * dt)) - (direction[1] * (self.speed * dt))
end

function Character:shoot(direction, dt)
end

function Character:getPos()
    return self.x, self.y
end

return Character