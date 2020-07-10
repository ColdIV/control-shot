local Class = function(defaults)
    local class = defaults or {}
    class.__index = class
    class.new = function (self, o)
        return setmetatable(o or {}, self)
    end
    
    return class
end

return Class
