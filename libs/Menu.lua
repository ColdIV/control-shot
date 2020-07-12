local Class = require('libs.Class')

local Menu = Class({
    headline = 'Menu',
    visible = false,
    elementIndices = {},
    elements = {},
    author = '',
    font = love.graphics.newFont(24),
    width = 250,
    height = 50,
    colorText = {1, 1, 1, 1},
    colorBackground = {0, 0, 0, 1},
    colorHover = {0, 1, 0, 1},
    backgroundColor = {0, 0, 0, 1},
    gameWidth = 900,
    gameHeight = 400,
    nextIndex = 1,
    separator = 10,
    hoverSound = love.audio.newSource("sounds/hover.wav", "static"),
    clickSound = love.audio.newSource("sounds/click.wav", "static")
})

function Menu:update(dt, x, y)
    if not self.visible then
        return
    end

    for i=1, #self.elements, 1 do
        if (self:checkHover(self.elements[i].index, x, y)) then
            if self.elements[i].hover == false then
                local clone = self.hoverSound:clone()
                clone:play()
            end
            self.elements[i].hover = true
        else
            self.elements[i].hover = false
        end
    end
    -- If available in config, play sound files on hover, click
end

function Menu:draw()
    if not self.visible then
        return
    end

    -- tmp variables
    local tmpX, tmpY, posX, posY = 0, 0, 0, self.separator
    local fontHeight = self.font:getAscent() + self.font:getDescent()
    
    -- draw background
    love.graphics.setColor(self:getBackgroundColor())
    love.graphics.rectangle('fill', 0, 0, self.gameWidth, self.gameHeight)

    -- draw headline
    -- love.graphics.setColor(self:getColorText())
    love.graphics.setColor({1, 1, 1})
    posX = ((self.gameWidth - self.font:getWidth(self.headline)) / 2)
    love.graphics.printf(self.headline, self.font, posX, posY, self.gameWidth)
	
	posX = self.gameWidth / 2
    posX = posX - (self.width / 2)
    posY = posY + self.separator + self.height

    -- draw buttons
    for i=1, #self.elements, 1 do
        love.graphics.setColor(self:getColorBackground())
        love.graphics.rectangle('fill', posX + 2, posY + 2, self.width - 4, self.height - 4)
        tmpX = ((self.width - self.font:getWidth(self.elements[i].label)) / 2) + posX
        tmpY = ((self.height - self.font:getHeight()) / 2) + posY + 3 -- no clue why the + 3 is needed. @todo future me.
        love.graphics.setColor(self:getColorText())
        love.graphics.printf(self.elements[i].label, self.font, tmpX, tmpY, self.width)
        if self.elements[i].hover then
            love.graphics.setColor(self:getColorHover())
            love.graphics.rectangle('line', posX, posY, self.width, self.height)
        end
        posY = posY + self.separator + self.height
    end

    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print(self.author, 9, self.gameHeight - 18)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(self.author, 10, self.gameHeight - 20)
end

function Menu:checkHover(index, x, y)
    local fontHeight = self.font:getAscent() + self.font:getDescent()
    local posX = ((self.gameWidth / 2)) - (self.width / 2)
    local posY = self.separator + self.height
    local step = self.separator + self.height

    -- find index
    for i=1, index, 1 do posY = posY + step end

    -- check collision
    if posX <= x and (posX + self.width) >= x and
       (posY - self.height) <= y and posY >= y
    then
        return true
    else 
        return false
    end
end

function Menu:onClick(x, y, button)
    if not self.visible then
        return
    end

    if button == 1 then
        for i=1, #self.elements, 1 do 
            if self:checkHover(i, x, y) then
                self.elements[i].func()
                local clone = self.clickSound:clone()
                clone:play()
            end
        end
    end
end

function Menu:addElement(label, func, type)
    local type = type or 'button'
    self.elementIndices[label] = self.nextIndex
    self.elements[self.nextIndex] = {label=label, func=func, type=type, hover=false, index=self.nextIndex}
    self.nextIndex = self.nextIndex + 1
end

function Menu:renameElement(label, newLabel, type)
	local type = type or 'button'
	
	self.elements[self.elementIndices[label]].label = newLabel
	local tmpIndex = self.elementIndices[label]
	self.elementIndices[label] = nil
	self.elementIndices[newLabel] = tmpIndex
end

function Menu:setWidth(width)
    self.width = width
end

function Menu:setHeight(height)
    self.height = height
end

function Menu:setColorText(r, g, b, a)
    self.colorText = {r, g, b, a}
end

function Menu:setColorBackground(r, g, b, a)
    self.colorBackground = {r, g, b, a}
end

function Menu:getElement(label)
    return self.elements[self.elementIndices[label]]
end

function Menu:getColorText()
    return self.colorText[1], self.colorText[2], self.colorText[3]
end

function Menu:getColorBackground()
    return self.colorBackground[1], self.colorBackground[2], self.colorBackground[3]
end

function Menu:getColorHover()
    return self.colorHover[1], self.colorHover[2], self.colorHover[3]
end

function Menu:getBackgroundColor()
    return self.backgroundColor[1], self.backgroundColor[2], self.backgroundColor[3]
end

function Menu:deleteElement(label)
    self.elementIndices[label] = nil
    self.elements[self.elementIndices[label]] = nil
end

function Menu:updateGameSize(width, height)
    self.gameWidth = width
    self.gameHeight = height
end

function Menu:isVisible()
    return self.visible
end

function Menu:show()
    self.visible = true
end

function Menu:hide()
    self.visible = false
end

return Menu