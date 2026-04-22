local api = require("engine.tech.api")
local paralyzed = {}

--- @class condition_paralyzed: condition
local methods = {}
paralyzed.mt = {__index = methods}

--- NEXT recheck saving throw
--- @return condition_paralyzed
paralyzed.new = function(life_time)
  return setmetatable({
    life_time = life_time,
  }, paralyzed.mt)
end

methods.codename = "paralyzed"

methods.modify_activation = function(self, entity, value, action)
  return false
end

methods.modify_incoming_is_critical = function(self, entity, value, source)
  if api.distance(entity, source) == 1 then
    return true
  end
  return value
end

Ldump.mark(paralyzed, {mt = "const"}, ...)
return paralyzed
