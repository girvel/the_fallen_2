local api = require("engine.tech.api")
local paralyzed = {}

--- @class condition_paralyzed: condition
--- @field mod? ability
--- @field dc integer
local methods = {}
paralyzed.mt = {__index = methods}

--- @param mod? ability
--- @param dc? integer
--- @return condition_paralyzed
paralyzed.new = function(life_time, mod, dc)
  return setmetatable({
    life_time = life_time,
    mod = mod,
    dc = dc,
  }, paralyzed.mt)
end

methods.codename = "paralyzed"

methods.move_start = function(self, entity)
  if self.mod and entity:saving_throw(self.mod, self.dc) then
    return true
  end
end

-- TODO autofail dex/str saves

methods.modify_activation = function(self, entity, value, action)
  return false
end

methods.modify_incoming_attack_roll = function(self, entity, roll)
  return roll:set("advantage")
end

methods.modify_incoming_is_critical = function(self, entity, value, source)
  if api.distance(entity, source) == 1 then
    return true
  end
  return value
end

Ldump.mark(paralyzed, {mt = "const"}, ...)
return paralyzed
