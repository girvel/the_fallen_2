local health = require("engine.mech.health")
local xp = require("engine.mech.xp")
local action = require("engine.tech.action")


local eldritch_blast = {}

--- @class spells_eldritch_blast: action
--- @field target entity
local methods = {}

--- @return spells_eldritch_blast
eldritch_blast.new = function(target)
  local t = {}
  Table.extend(t, eldritch_blast.prelude)
  Table.extend(t, methods)
  t.target = target
  return t
end

methods._act = function(self, entity)
  local attack_roll = D(20)
    + entity:get_modifier("cha")
    + xp.get_proficiency_bonus(entity.level or 1)
  local damage_roll = D(10)
  health.attack(entity, self.target, attack_roll, damage_roll)
  return true
end

eldritch_blast.prelude = {
  name = "мистический заряд",
  codename = "eldritch_blast",
  parameter_type = "entity_target",
  produce = eldritch_blast.new,
  cost = {
    actions = 1,
  },

  _act = function()
    Error("Attempting to call .act on prelude to an action")
  end,

  get_hint = function(self, entity)
    return "TODO"
  end,
}

action.mix_in(eldritch_blast.prelude)

eldritch_blast.perk = {
  modify_additional_actions = function(self, entity, list)
    table.insert(list, eldritch_blast.prelude)
    return list
  end,
}

Ldump.mark(eldritch_blast, {}, ...)
return eldritch_blast
