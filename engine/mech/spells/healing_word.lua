local api = require("engine.tech.api")
local animated = require("engine.tech.animated")
local health = require("engine.mech.health")
local tcod = require("engine.tech.tcod")
local action = require("engine.tech.action")


local healing_word = Memoize(function(mod, cast_level)
  cast_level = cast_level or 1
  return {
    name = "Лечащее слово",
    codename = "healing_word_" .. cast_level,

    cost = {
      bonus_actions = 1,
      -- NEXT RM
      -- ["spell_slots_" .. cast_level] = 1,
    },

    range = 40,

    parameter_type = "entity_target",
    target_filter = function(self, entity, target)
      if not (target
        and target.hp
        and target.hp < target:get_max_hp())
      then return false end

      -- NEXT repeating thing
      local result do
        local vision_map = tcod.map(State.grids.solids)
        vision_map:refresh_fov(entity.position, self.range)
        result = vision_map:is_visible_unsafe(unpack(target.position))
        vision_map:free()
      end

      return result
    end,

    is_available = action.make_is_available(),

    act = action.make_act(function(self, entity, target)
      api.rotate(entity, target)
      entity:animate("gesture")
      health.heal(target, (D(4) * cast_level + entity:get_modifier("wis")):roll())
      animated.add_fx("engine/assets/animations/healing_word_target", target.position)
      animated.add_fx("engine/assets/animations/healing_word_spell", entity.position)
      return true
    end),
  }
end)

return healing_word
