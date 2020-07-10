local Class = require('libs.Class')

local Character = Class({shot = false, control = "ai", width = 32, height = 32})

function Character:move(x, y)
    self.x = x
    self.y = y
end

function Character:getPos()
    return self.x, self.y
end

return Character