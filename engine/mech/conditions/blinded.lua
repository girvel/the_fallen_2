local blinded = {}

--- @class condition_blinded: condition
local methods = {}
blinded.mt = {__index = methods}

--- @return condition_blinded: condition
blinded.new = function()
  return setmetatable({
    life_time = 6,
  }, blinded.mt)
end

methods.codename = "blinded"

methods.modify_attack_roll = function(self, entity, roll, slot)
  return roll:set("disadvantage")
end

methods.modify_incoming_attack_roll = function(self, entity, roll, source)
  return roll:set("advantage")
end

Ldump.mark(blinded, {mt = "const"}, ...)
return blinded
