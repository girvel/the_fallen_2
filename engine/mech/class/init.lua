local translation = require("engine.tech.translation")
local xp = require("engine.mech.xp")
local action = require("engine.tech.action")
local health = require("engine.mech.health")
local sound  = require("engine.tech.sound")


local class = {}

--- @param die integer
--- @param is_base? boolean
--- @return action
class.hit_dice = Memoize(function(die, is_base)
  return Table.extend({
    name = "перевязать раны",
    codename = "hit_dice",

    modify_max_hp = function(self, entity, value)
      if is_base then
        return value + die
      else
        return value + math.floor(die / 2) + 1
      end
    end,

    modify_resources = function(self, entity, resources, rest_type)
      if rest_type == "long" then
        resources.hit_dice = (resources.hit_dice or 0) + 1
      end
      return resources
    end,

    cost = {
      hit_dice = 1,
    },

    sounds = sound.multiple("engine/assets/sounds/hit_dice", .3),

    _is_available = function(self, entity)
      return not State.combat and entity.hp < entity:get_max_hp()
    end,

    _act = function(self, entity)
      self.sounds:play_at(entity.position)
      local to_heal_raw = (D(die) + entity:get_modifier("con")):roll()
      health.heal(entity, entity:modify("hit_dice_result", to_heal_raw))
      return true
    end,
  }, action.base)
end)

--- @param skill skill
--- @return table
class.skill_proficiency = Memoize(function(skill)
  --- @cast skill string
  return {
    name = translation.skills[skill]:utf_capitalize(),
    codename = skill .. "_proficiency",

    modify_skill_score = function(self, entity, score, this_skill)
      if this_skill == skill then
        score = score + xp.get_proficiency_bonus(entity.level)
      end
      return score
    end,
  }
end)

--- @param ability ability
--- @return table
class.save_proficiency = function(ability)
  return {
    codename = ability .. "_save_proficiency",

    modify_saving_throw = function(self, entity, roll, this_ability)
      if ability == this_ability then
        return roll + xp.get_proficiency_bonus(entity.level)
      end
      return roll
    end,
  }
end

--- @return integer?
local parse_slot_level = function(str)
  local PREFIX = "spell_slots_"
  if str:starts_with(PREFIX) then
    return tonumber(str:sub(#PREFIX + 1))
  end
  return nil
end

--- @alias action_factory fun(mod?: ability, upcast_level?: integer): action
--- @param spell action|action_factory
--- @param mod? ability
class.spell = Memoize(function(spell, mod)
  local base_spell, base_slot_n
  if type(spell) == "table" then
    base_spell = spell
  else
    base_spell = spell(mod)
    for resource_name in pairs(base_spell.cost) do
      base_slot_n = parse_slot_level(resource_name)
      if base_slot_n then break end
    end
  end

  return {
    modify_additional_actions = function(self, entity, list)
      table.insert(list, base_spell)
      if not base_slot_n then return list end
      for resource_name in pairs(entity.resources) do
        local spell_slot_n = parse_slot_level(resource_name)
        if spell_slot_n and spell_slot_n > base_slot_n then
          local this_spell = spell(mod, spell_slot_n)
          this_spell.upcast_from = base_spell
          table.insert(list, this_spell)
        end
      end
      return list
    end,
  }
end)

Ldump.mark(class, "const", ...)
return class
