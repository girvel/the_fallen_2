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

Ldump.mark(class, "const", ...)
return class
