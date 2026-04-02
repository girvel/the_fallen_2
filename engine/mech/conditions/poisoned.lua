local health = require("engine.mech.health")
local poisoned = {}

--- @class condition_poisoned
--- @field codename "poisoned"
--- @field life_time integer
--- @field _t number
local methods = {}
poisoned.mt = {__index = methods}

--- @param damage integer
--- @return condition_poisoned
poisoned.new = function(damage)
  return setmetatable({
    codename = "poisoned",
    life_time = damage * 6,
    _t = 0,
  }, poisoned.mt)
end

--- @param damage integer
poisoned.modify_outgoing_damage = function(damage)
  return function(self, entity, _damage, target, is_critical)
    if target.conditions
      and Fun.iter(target.conditions)
        :all(function(c) return getmetatable(c) ~= poisoned.mt end)
    then
      table.insert(target.conditions, poisoned.new(damage))
    end
    return damage
  end
end

methods.update = function(self, entity, dt)
  local next_t = self._t + dt
  local d = math.floor(next_t / 6) - math.floor(self._t / 6)
  if d > 0 then
    health.damage(entity, d)  -- TODO damage source
  end
  self._t = next_t
end

Ldump.mark(poisoned, {mt = "const"}, ...)
return poisoned
