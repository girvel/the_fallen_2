local monsters = require("engine.mech.monsters")
local api = require("engine.tech.api")
local animated = require("engine.tech.animated")
local health = require("engine.mech.health")
local tcod = require("engine.tech.tcod")
local action = require("engine.tech.action")
local actions = require("engine.mech.actions")
local xp = require("engine.mech.xp")


local spells = {}

----------------------------------------------------------------------------------------------------
-- [SECTION] Cantrips
----------------------------------------------------------------------------------------------------

--- @type action
spells.eldritch_blast = {
  name = "мистический заряд",
  codename = "eldritch_blast",
  cost = {
    actions = 1,
  },

  parameters = {
    entity_target = function(self, entity, target)
      -- NEXT duplicated actions.bow_attack.target_filter, should be action.filters.make_enemy_target(range)
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
  },

  is_available = action.make_is_available(),

  act = action.make_act(function(self, entity, target)
    api.rotate(entity, target)
    entity:animate("fast_gesture"):next(function()
      local attack_roll = D(20)
        + entity:get_modifier("cha")
        + xp.get_proficiency_bonus(entity.level or 1)
      local damage_roll = D(10)
      if health.attack(entity, target, attack_roll, damage_roll) then
        animated.add_fx("engine/assets/animations/eldritch_blast_target", target.position, "fx_over")
      end
    end)
    return true
  end),
}

----------------------------------------------------------------------------------------------------
-- [SECTION] Level 1
----------------------------------------------------------------------------------------------------

--- @type action_factory
spells.healing_word = Memoize(function(mod, cast_level)
  cast_level = cast_level or 1
  return {
    name = ("Лечащее слово (ур. %s)"):format(cast_level),
    codename = "healing_word_" .. cast_level,

    cost = {
      bonus_actions = 1,
      ["spell_slots_" .. cast_level] = 1,
    },

    range = 40,

    parameters = {
      entity_target = function(self, entity, target)
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
    },

    is_available = action.make_is_available(),

    act = action.make_act(function(self, entity, target)
      api.rotate(entity, target)
      entity:animate("gesture")
      health.heal(target, (D(4) * cast_level + entity:get_modifier(mod)):roll())
      animated.add_fx("engine/assets/animations/healing_word_target", target.position)
      animated.add_fx("engine/assets/animations/healing_word_spell", entity.position)
      return true
    end),
  }
end)

----------------------------------------------------------------------------------------------------
-- [SECTION] Level 3
----------------------------------------------------------------------------------------------------

-- NEXT upcasting
--- @type action
spells.animate_dead = {
  codename = "animate_dead",

  cost = {
    actions = 1,
    spell_slots_3 = 1,
  },

  is_available = action.make_is_available(),

  parameters = {
    entity_target = function(self, entity, target)
      return State:exists(target) and target.body_flag
    end,
  },

  act = action.make_act(function(self, entity, target)
    local position = State.grids.solids:find_free_position(target.position)
    if not position then return false end

    State:remove(target)
    entity:animate("gesture")
    local fx = animated.add_fx("engine/assets/animations/skeleton_raise", position, "solids")
    fx.on_remove = function()
      local e = State:add_at(monsters.skeleton_heavy(), position, "solids")
      e.faction = entity.faction
    end
    return true
  end),
}

Ldump.mark(spells, {}, ...)
return spells
