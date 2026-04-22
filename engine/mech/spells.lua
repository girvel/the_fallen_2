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
spells.eldritch_blast = action.plain {
  name = "мистический заряд",
  codename = "eldritch_blast",
  cost = {
    actions = 1,
  },

  parameters = {
    entity_targets = {
      max_n = function(self, entity)
        if not entity.level or entity.level < 5 then
          return 1
        elseif entity.level < 11 then
          return 2
        elseif entity.level < 17 then
          return 3
        else
          return 4
        end
      end,
      filter = action.filters.enemy(actions.BOW_ATTACK_RANGE),
    }
  },

  _act = function(self, entity, params)
    api.rotate(entity, params.entity_targets[1])

    local precogs = {}
    for _, target in ipairs(params.entity_targets) do
      local attack_roll = D(20)
        + entity:get_modifier("cha")
        + xp.get_proficiency_bonus(entity.level or 1)
      if api.distance(entity, target) == 1 then
        attack_roll = attack_roll:set("disadvantage")
      end
      local damage_roll = D(10)
      table.insert(precogs, {
        target, health.attack_precog(entity, target, attack_roll, damage_roll)
      })
    end

    entity:animate("fast_gesture"):next(function()
      for _, data in ipairs(precogs) do
        local target, did_hit, is_crit, damage = unpack(data)
        health.attack_enact(entity, target, did_hit, is_crit, damage)
        if did_hit then
          animated.add_fx("engine/assets/animations/eldritch_blast_target", target.position, "fx_over")
        end
      end
    end)

    return true
  end,
}

----------------------------------------------------------------------------------------------------
-- [SECTION] Level 1
----------------------------------------------------------------------------------------------------

spells.healing_word = action.leveled_spell(1, function(mod, cast_level)
  --- @type spell_prototype
  return {
    _name = "лечащее слово",
    _codename = "healing_word",
    _cost = {
      bonus_actions = 1,
    },

    range = 40,

    parameters = {
      entity_targets = {
        filter = function(self, entity, target)
          return target
            and target.hp
            and target.hp < target:get_max_hp()
            and api.can_see(entity, target, self.range)
        end,
        max_n = function() return 1 end,
      }
    },

    _act = function(self, entity, params)
      local target = params.entity_targets[1]
      api.rotate(entity, target)
      entity:animate("gesture")
      health.heal(target, (D(4) * cast_level + entity:get_modifier(mod)):roll())
      animated.add_fx("engine/assets/animations/healing_word_target", target.position)
      animated.add_fx("engine/assets/animations/healing_word_spell", entity.position)
      return true
    end,
  }
end)

----------------------------------------------------------------------------------------------------
-- [SECTION] Level 2
----------------------------------------------------------------------------------------------------

spells.spray_of_cards = action.leveled_spell(2, function(mod, cast_level)
  --- @type spell_prototype
  return {
    _name = "веер карт",
    _codename = "spray_of_cards",

    _cost = {
      actions = 1,
    },

    parameters = {
      direction = true,
    },

    _act = function(self, entity, params)
      local damage = (D(10) * cast_level):roll()
      local dc = entity:get_spell_dc(mod)

      local d = params.direction
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

      State.player:rotate(d)
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
    end,
  }
end)

----------------------------------------------------------------------------------------------------
-- [SECTION] Level 3
----------------------------------------------------------------------------------------------------

spells.animate_dead = action.leveled_spell(3, function(mod, cast_level)
  --- @type spell_prototype
  return {
    _codename = "animate_dead",
    _name = "Поднятие мертвеца",
    _cost = {
      actions = 1,
    },

    parameters = {
      entity_targets = {
        filter = function(self, entity, target)
          return State:exists(target) and target.body_flag
        end,
        max_n = function() return cast_level * 2 - 5 end,
      },
    },

    _act = function(self, entity, params)
      local final_positions = {}
      for _, target in ipairs(params.entity_targets) do
        local get_position = State.grids.solids:find_free_positions(target.position)
        local position
        repeat
          position = get_position()
          if not position then return false end
        until not final_positions[target]
        final_positions[position] = target
      end

      for position, target in pairs(final_positions) do
        State:remove(target)
        entity:animate("gesture")
        local fx = animated.add_fx("engine/assets/animations/skeleton_raise", position, "solids")
        fx.on_remove = function()
          local e = State:add_at(monsters.skeleton_heavy(), position, "solids")
          e.faction = entity.faction
        end
      end
      return true
    end,
  }
end)

Ldump.mark(spells, {}, ...)
return spells
