local blinded = require("engine.mech.conditions.blinded")
local monsters = require("engine.mech.monsters")
local api = require("engine.tech.api")
local animated = require("engine.tech.animated")
local health = require("engine.mech.health")
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
      return target
        and target.hp
        and State.hostility:get(entity, target) ~= "ally"
        and api.can_see(entity, target, actions.BOW_ATTACK_RANGE)
    end,
  },

  is_available = action.make_is_available(),

  act = action.make_act(function(self, entity, params)
    api.rotate(entity, params.entity_target)
    local attack_roll = D(20)
      + entity:get_modifier("cha")
      + xp.get_proficiency_bonus(entity.level or 1)
    if api.distance(entity, params.entity_target) == 1 then
      attack_roll = attack_roll:set("disadvantage")
    end
    local damage_roll = D(10)
    local did_hit, is_crit, damage = health.attack_precog(entity, params.entity_target, attack_roll, damage_roll)
    entity:animate("fast_gesture"):next(function()
      health.attack_enact(entity, params.entity_target, did_hit, is_crit, damage)
      if did_hit then
        animated.add_fx("engine/assets/animations/eldritch_blast_target", params.entity_target.position, "fx_over")
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
        return target
          and target.hp
          and target.hp < target:get_max_hp()
          and api.can_see(entity, target, self.range)
      end,
    },

    is_available = action.make_is_available(),

    act = action.make_act(function(self, entity, params)
      api.rotate(entity, params.entity_target)
      entity:animate("gesture")
      health.heal(params.entity_target, (D(4) * cast_level + entity:get_modifier(mod)):roll())
      animated.add_fx("engine/assets/animations/healing_word_target", params.entity_target.position)
      animated.add_fx("engine/assets/animations/healing_word_spell", entity.position)
      return true
    end),
  }
end)

----------------------------------------------------------------------------------------------------
-- [SECTION] Level 2
----------------------------------------------------------------------------------------------------

-- NEXT PLAN
-- + sketch
-- + saving throw
-- + exiting upcasting
-- + blinding
-- + split health.attack into health.attack_precog & health.attack_enact
-- + eldritch blast can be obstructed by melee
-- + target argument -> params table
-- + fx
-- + icons
-- - direction
-- - name formatting?
-- - level 5, eldritch blast x2

--- @type action_factory
spells.spray_of_cards = Memoize(function(mod, cast_level)
  cast_level = cast_level or 2
  return {
    name = ("Веер карт (ур. %s)"):format(cast_level),
    codename = "spray_of_cards_" .. cast_level,

    cost = {
      actions = 1,
      ["spell_slots_" .. cast_level] = 1,
    },

    is_available = action.make_is_available(),

    act = action.make_act(function(self, entity)
      local damage = (D(10) * cast_level):roll()
      local dc = entity:get_spell_dc(mod)

      local d = entity.direction
      local dr = d:rotate()
      local damages = {}
      for _, delta in ipairs {
        d, 2 * d, dr + d, -dr + d,
      } do
        local target = State.grids.solids:slow_get(delta + entity.position)
        if target and target.hp then
          damages[target] = {health.attack_save_precog(entity, target, "dex", dc, damage)}
        end
      end

      entity:animate("throw"):next(function()
        local offset
        if d == Vector.up then offset = V(-1, -2)
        elseif d == Vector.right then offset = V(3, -1)
        elseif d == Vector.down then offset = V(2, 3)
        elseif d == Vector.left then offset = V(-2, 2)
        else assert(false) end

        local fx = animated.add_fx(
          "engine/assets/animations/spray_of_cards", entity.position + offset, "fx_over"
        )
        fx.rotation = d:angle()

        for target, t in pairs(damages) do
          health.attack_save_enact(entity, target, unpack(t))
          if target.conditions then
            table.insert(target.conditions, blinded.new())
          end
        end
      end)
      return true
    end),
  }
end)

----------------------------------------------------------------------------------------------------
-- [SECTION] Level 3
----------------------------------------------------------------------------------------------------

-- TODO upcasting
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

  act = action.make_act(function(self, entity, params)
    local position = State.grids.solids:find_free_position(params.entity_target.position)
    if not position then return false end

    State:remove(params.entity_target)
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
