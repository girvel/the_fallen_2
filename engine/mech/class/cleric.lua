local health = require("engine.mech.health")
local tcod = require("engine.tech.tcod")
local action = require("engine.tech.action")
local class = require("engine.mech.class")


local cleric = {}

cleric.hit_dice = class.hit_dice(8)

cleric.spell_slots = {
  modify_resources = function(self, entity, resources, rest_type)
    if rest_type == "long" then
      if entity.level == 1 then
        resources.spell_slots_1 = 2
      elseif entity.level == 2 then
        resources.spell_slots_1 = 3
      else
        resources.spell_slots_1 = 4
      end

      if entity.level >= 4 then
        resources.spell_slots_2 = 3
      elseif entity.level >= 3 then
        resources.spell_slots_2 = 2
      end

      if entity.level >= 6 then
        resources.spell_slots_3 = 3
      elseif entity.level >= 5 then
        resources.spell_slots_3 = 2
      end
    end
    return resources
  end,
}

return cleric
