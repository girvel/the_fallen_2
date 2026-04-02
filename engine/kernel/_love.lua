--- @meta
love.handlers = {}

--- @param args1 string[]
--- @param args2 string[]
love.load = function(args1, args2) end

--- @param dt number
love.update = function(dt) end

--- @param dt number
love.draw = function(dt) end

--- @param key string?
--- @param scancode string?
--- @param isrepeat boolean
love.keypressed = function(key, scancode, isrepeat) end

love.arg = {}

--- @param args string[]
--- @return string[]
love.arg.parseGameArguments = function(args) end
