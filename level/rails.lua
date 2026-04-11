local items = require("level.palette.items")
local item = require("engine.tech.item")


local rails = {}

--- @class rails
local methods = {}
rails.mt = {__index = methods}

local init_debug

--- @return rails
rails.new = function()
  return setmetatable({
    
  }, rails.mt)
end

--- @param checkpoint string
methods.init = function(self, checkpoint)
  if Kernel.debug then init_debug() end
end

init_debug = function()
  item.give(State.player, State:add(items.short_bow()))
end

Ldump.mark(rails, {mt = "const"}, ...)
return rails
