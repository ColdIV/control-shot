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
    dead = false
})

function Character:getNewPos(x, y, direction, speed, dt)
    local newX = x + (direction[4] * (speed * dt)) - (direction[2] * (speed * dt))
    local newY = y + (direction[3] * (speed * dt)) - (direction[1] * (speed * dt))

    return newX, newY
end

function Character:update(controls, width, height, dt)
    self:move(controls, width, height, dt)
end

function Character:shoot()
    if self.shotCD == 0 then
        self.shotCD = self.shotMaxCD
        return true
    end

    return false
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

    -- shot cooldown
    if self.shotCD > 0 then
        self.shotCD = self.shotCD - 1 * dt
        if self.shotCD < 0 then self.shotCD = 0 end
    end

    -- find new position
    local newX, newY = self:getNewPos(self.x, self.y, direction, self.speed, dt)

    -- check map bounds
    if newX > width - self.width then newX = width - self.width
    elseif newX < 0 then newX = 0 end
    if newY > height - self.height then newY = height - self.height
    elseif newY < 0 then newY = 0 end

    self.x = newX
    self.y = newY
end

function Character:collision(x, y, width, height)
    if self.x < x + width and self.x + self.width > x and self.y < y + height and self.y + self.height > y then
        return true
    end

    return false
end

function Character:draw() 
    love.graphics.setColor(self.cLine)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    love.graphics.setColor(self.cFill)
    love.graphics.rectangle("fill", self.x + 2, self.y + 2, self.width - 4, self.height - 4)
end

return Character