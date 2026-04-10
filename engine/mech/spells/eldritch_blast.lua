local health = require("engine.mech.health")
local xp = require("engine.mech.xp")
local action = require("engine.tech.action")


local eldritch_blast = {}

--- @class spells_eldritch_blast: action
--- @field target entity
local methods = setmetatable({}, {__index = action.base})  --- @diagnostic disable-line
eldritch_blast.mt = {__index = methods}

--- @return spells_eldritch_blast
eldritch_blast.new = function(target)
  return setmetatable({
    target = target,
  }, eldritch_blast.mt)
end

methods._act = function(self, entity)
  local attack_roll = D(20)
    + entity:get_modifier("cha")
    + xp.get_proficiency_bonus(entity.level or 1)
  local damage_roll = D(10)
  health.attack(entity, self.target, attack_roll, damage_roll)
end

Ldump.mark(eldritch_blast, {mt = "const"}, ...)
return eldritch_blast
