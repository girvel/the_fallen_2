local xp = require("engine.mech.xp")
local health = require "engine.mech.health"
local abilities = require "engine.mech.abilities"
local sound     = require "engine.tech.sound"
local creature = {}


--- @class _creature_methods
local methods = {}

--- @return entity
creature.mixin = function()
  local result = Table.extend({
    resources = {},
    inventory = {},
    perks = {},
    conditions = {},
    sounds = {
      hit = sound.multiple("engine/assets/sounds/hit/body", .3),
    },
    transparent_flag = true,
    moving_flag = true,
    xp = 0,
  }, methods)

  return result
end

--- @param entity entity
creature.init = function(entity)
  Table.assert_fields(entity, {"base_abilities", "level"})
  entity:rest("full")
  entity:rotate(entity.direction or Vector.right)
end

--- @param ... table
--- @return entity
creature.make = function(...)
  local result = Table.extend(creature.mixin(), ...)
  creature.init(result)
  return result
end

--- @alias creature_modification
--- | '"resources"'
--- | '"max_hp"'
--- | '"ability_score"'
--- | '"skill_score"'
--- | '"attack_roll"'
--- | '"damage_roll"'
--- | '"opportunity_attack_trigger"'
--- | '"initiative_roll"'
--- | '"armor"'
--- | '"dex_armor_bonus"'
--- | '"activation"'
--- | '"hp"'
--- | '"outgoing_damage"'
--- | '"saving_throw"'
--- | '"light"'
--- | '"additional_actions"'
--- | '"hit_dice_result"'

--- @param self entity
--- @param modname creature_modification
--- @param value any
--- @param ... any
methods.modify = function(self, modname, value, ...)
  modname = "modify_" .. modname
  for _, p in ipairs(self.perks) do
    local mod = p[modname]
    if mod then
      value = mod(p, self, value, ...)
    end
  end

  for _, p in ipairs(self.conditions) do
    local mod = p[modname]
    if mod then
      value = mod(p, self, value, ...)
    end
  end

  for _, it in pairs(self.inventory) do
    if it.perks then
      for _, p in ipairs(it.perks) do
        local mod = p[modname]
        if mod then
          value = mod(p, self, value, ...)
        end
      end
    end
  end

  return value
end

--- @alias rest_type "move"|"short"|"long"|"full"

--- @param self entity
--- @param rest_type rest_type
methods.get_resources = function(self, rest_type)
  local result = {}
  if rest_type == "move" then
    result = {
      actions = 1,
      bonus_actions = 1,
      reactions = 1,
      movement = 6,
    }
  elseif rest_type == "short" then
    result = {}
  elseif rest_type == "long" then
    result =  {}
  elseif rest_type == "full" then
    return Table.extend(
      self:get_resources("move"),
      self:get_resources("short"),
      self:get_resources("long")
    )
  else
    Error("Unknown rest type %q", rest_type)
  end

  return self:modify("resources", result, rest_type)
end

--- @param self entity
methods.get_max_hp = function(self)
  return math.max(1, self:modify("max_hp", self.max_hp or self.level * self:get_modifier("con")))
end

--- @param self entity
--- @param rest_type rest_type
methods.rest = function(self, rest_type)
  if rest_type == "long" or rest_type == "full" then
    health.set_hp(self, self:get_max_hp())
  end

  Table.extend(self.resources, self:get_resources(rest_type))
end

--- @param self entity
--- @param direction? vector
methods.rotate = function(self, direction)
  if direction then
    self.direction = direction
  else
    direction = self.direction
  end

  for _, item in pairs(self.inventory) do
    item.direction = direction
  end
  if self.animate then
    self:animate()
  end
end

--- Compute armor class; doesn't take priority over .armor
--- @param self entity
methods.get_armor = function(self)
  return self.armor
    or self:modify("armor", 10 + self:modify("dex_armor_bonus", self:get_modifier("dex")))
end

--- @param self entity
--- @param ability ability|skill
--- @return number
methods.get_modifier = function(self, ability)
  if abilities.set[ability] then
    return abilities.get_modifier(self:modify(
      "ability_score",
      self.base_abilities[ability],
      ability
    ))
  end

  if not abilities.skill_bases[ability] then
    Error("%s is not a skill nor an ability", ability)
  end

  return self:modify(
    "skill_score",
    self:get_modifier(abilities.skill_bases[ability]),
    ability
  )
end

--- @param self entity
--- @param ability ability|skill
--- @return d
methods.get_roll = function(self, ability)
  return D(20) + self:get_modifier(ability) + xp.get_proficiency_bonus(self.level or 1)
end

local SUCCESS = sound.multiple("engine/assets/sounds/check_succeeded")
local FAILURE = sound.multiple("engine/assets/sounds/check_failed")

--- @param self entity
--- @param to_check ability|skill
--- @param dc integer difficulty class
--- @return boolean
methods.ability_check = function(self, to_check, dc)
  local roll = D(20) + self:get_modifier(to_check)
  local result = roll:roll()

  Log.debug("%s rolls check %s: %s against %s",
    Name.code(self), to_check, result, dc
  )

  local success = result >= dc

  local sounds = success and SUCCESS or FAILURE
  sounds:play_at(self.position)

  return success
end

--- @param self entity
--- @param to_check ability
--- @param dc integer difficulty class
--- @return boolean
methods.saving_throw = function(self, to_check, dc)
  local roll = self:modify("saving_throw", D(20) + self:get_modifier(to_check), to_check)
  local result = roll:roll()
  local success = result >= dc

  Log.debug(
    "%s %s / %s %s | Saving throw for %s",
    to_check:utf_upper(), result, dc, success and "" or "", self
  )

  local sounds = success and SUCCESS or FAILURE
  sounds:play_at(self.position)

  return success
end

--- @param self entity
--- @param weapon item?
--- @return integer
methods.get_combat_modifier = function(self, weapon)
  local str = self:get_modifier("str")
  if not weapon then return str end

  if weapon.tags.ranged then
    return self:get_modifier("dex")
  end

  if weapon.tags.finesse then
    return math.max(str, self:get_modifier("dex"))
  end

  return str
end

--- @param self entity
--- @param slot string
--- @return d
methods.get_attack_roll = function(self, slot)
  local weapon = self.inventory[slot]
  local roll = D(20)
    + xp.get_proficiency_bonus(self.level)
    + self:get_combat_modifier(weapon)

  if weapon then
    roll = roll + (weapon.bonus or 0)
  end

  return self:modify("attack_roll", roll, slot)
end

--- @param self entity
--- @param slot string
--- @return d
methods.get_damage_roll = function(self, slot)
  local weapon = self.inventory[slot]
  if not weapon then
    return D.new({}, self:get_modifier("str") + 1)
  end

  local roll
  if weapon.tags.versatile and not self.inventory.offhand then
    roll = D(weapon.damage_roll.dice[1].sides_n + 2)
  else
    roll = weapon.damage_roll
  end

  roll = roll + (weapon.bonus or 0)

  if slot == "hand" or weapon.tags.ranged then
    roll = roll + self:get_combat_modifier(weapon)
  end

  return self:modify("damage_roll", roll, slot)
end

--- @param self entity
methods.get_initiative_roll = function(self)
  return self:modify("initiative_roll", D(20) + self:get_modifier("dex"))
end

--- Whether the entity can use actions at this moment
methods.can_act = function(self)
  return not State.runner.locked_entities[self] and not (State.combat and State.combat:get_current() ~= self)
end

--- Whether the entity is free from cutscenes/combat
methods.is_free = function(self)
  return not State.runner.locked_entities[self] and not (State.combat and State:in_combat(self))
end

Ldump.mark(creature, {
  mixin = {methods = "const"},
}, ...)
return creature
