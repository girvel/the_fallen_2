local actions = require("engine.mech.actions")
local tcod = require("engine.tech.tcod")
local health = require("engine.mech.health")
local xp = require("engine.mech.xp")
local action = require("engine.tech.action")


local eldritch_blast = {
  name = "мистический заряд",
  codename = "eldritch_blast",
  cost = {
    actions = 1,
  },

  parameter_type = "entity_target",
  target_filter = function(self, entity, target)
    -- TODO duplicated actions.bow_attack.target_filter, should be action.make_enemy_target_filter(range)
    if not (target
      and target.hp
      and State.hostility:get(entity, target) ~= "ally")
    then return false end

    local result do
      local vision_map = tcod.map(State.grids.solids)
      vision_map:refresh_fov(entity.position, actions.BOW_ATTACK_RANGE)
      result = vision_map:is_visible_unsafe(unpack(target.position))
      vision_map:free()
    end

    return result
  end,

  is_available = action.make_is_available(),

  act = action.make_act(function(self, entity, target)
    local attack_roll = D(20)
      + entity:get_modifier("cha")
      + xp.get_proficiency_bonus(entity.level or 1)
    local damage_roll = D(10)
    health.attack(entity, target, attack_roll, damage_roll)
    return true
  end),
}

Ldump.mark(eldritch_blast, "const", ...)
return eldritch_blast
