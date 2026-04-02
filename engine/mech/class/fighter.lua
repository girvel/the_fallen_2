local health = require("engine.mech.health")
local action = require("engine.tech.action")
local sound  = require("engine.tech.sound")
local animated = require("engine.tech.animated")


local fighter = {}

fighter.name = "Воин"
fighter.codename = "fighter"
fighter.hit_die = 10

fighter.action_surge = Table.extend({
  name = "всплеск действий",
  codename = "action_surge",

  modify_resources = function(self, entity, resources, rest_type)
    if rest_type == "short" or rest_type == "long" then
      resources.action_surge = (resources.action_surge or 0) + 1
    end
    return resources
  end,

  modify_additional_actions = function(self, entity, list)
    table.insert(list, self)
    return list
  end,

  cost = {
    actions = -1,
    action_surge = 1,
  },

  sounds = sound.multiple("engine/assets/sounds/action_surge", .3),

  _is_available = function() return State.combat end,

  _act = function(self, entity)
    State:add(animated.fx("engine/assets/animations/action_surge", entity.position))
    self.sounds:play_at(entity.position)
    return true
  end,
}, action.base)

fighter.second_wind = Table.extend({
  name = "второе дыхание",
  codename = "second_wind",

  modify_resources = function(self, entity, resources, rest_type)
    if rest_type == "short" or rest_type == "long" then
      resources.second_wind = (resources.second_wind or 0) + 1
    end
    return resources
  end,

  modify_additional_actions = function(self, entity, list)
    table.insert(list, self)
    return list
  end,

  cost = {
    second_wind = 1,
    bonus_actions = 1,
  },

  sounds = sound.multiple("engine/assets/sounds/second_wind", .3),

  _is_available = function(self, entity) return entity.hp < entity:get_max_hp() end,

  _act = function(self, entity)
    State:add(animated.fx("engine/assets/animations/second_wind", entity.position))
    self.sounds:play_at(entity.position)
    health.heal(entity, self:get_roll(entity.level):roll())
    return true
  end,

  get_roll = function(self, level)
    return D(10) + level
  end,
}, action.base)

local fighting_spirit_condition = function()
  return {
    codename = "fighting_spirit_condition",

    life_time = 6,

    modify_attack_roll = function(self, entity, roll, slot)
      return roll:set("advantage")
    end,
  }
end

fighter.fighting_spirit = Table.extend({
  name = "боевой дух",
  codename = "fighting_spirit",

  modify_resources = function(self, entity, resources, rest_type)
    if rest_type == "long" then
      resources.fighting_spirit = (resources.fighting_spirit or 0) + 3
    end
    return resources
  end,

  modify_additional_actions = function(self, entity, list)
    table.insert(list, self)
    return list
  end,

  cost = {
    fighting_spirit = 1,
    bonus_actions = 1,
  },

  sounds = sound.multiple("engine/assets/sounds/fighting_spirit", .3),

  _is_available = function(self, entity) return State.combat end,

  _act = function(self, entity)
    State:add(animated.fx("engine/assets/animations/fighting_spirit", entity.position))
    self.sounds:play_at(entity.position)
    table.insert(entity.conditions, fighting_spirit_condition())
    health.set_hp(entity, entity.hp + 5)
    return true
  end,
}, action.base)

fighter.fighting_styles = {}

fighter.fighting_styles.two_weapon_fighting = {
  name = "Бой двумя оружиями",
  description = "Удар оружием во второй руке наносит больше урона",
  codename = "two_weapon_fighting",

  modify_damage_roll = function(self, entity, roll, slot)
    if slot ~= "offhand" then return roll end
    local offhand = entity.inventory.offhand
    if not offhand or offhand.tags.ranged then return roll end
    return roll + entity:get_combat_modifier(offhand)
  end,
}

fighter.fighting_styles.defence = {
  name = "Оборона",
  description = "+1 к классу брони при наличии шлема/доспеха",
  codename = "defence",

  modify_armor = function(self, entity, value)
    if entity.inventory.body or entity.inventory.head then
      return value + 1
    end
    return value
  end,
}

fighter.fighting_styles.archery = {
  name = "Стрельба",
  description = "+10% к попаданию дальнобойным оружием",
  codename = "archery",

  modify_attack_roll = function(self, entity, roll, slot)
    local weapon = entity.inventory[slot]
    if weapon and weapon.tags.ranged then
      return roll + 2
    end
    return roll
  end,
}

fighter.fighting_styles.duelist = {
  name = "Дуэлянт",
  description = "+2 к урону единственным одноручным оружием",
  codename = "duelist",

  modify_damage_roll = function(self, entity, roll, slot)
    local other_weapon = entity.inventory[slot == "hand" and "offhand" or "hand"]
    if not other_weapon or not other_weapon.damage_roll then
      return roll + 2
    end
    return roll
  end,
}

fighter.fighting_styles.great_weapon_master = {
  name = "Бой двуручным оружием",
  description = "Увеличенный средний урон двуручным оружием",
  codename = "great_weapon_master",

  modify_damage_roll = function(self, entity, roll, slot)
    if slot ~= "hand" then return roll end

    local hand = entity.inventory.hand
    local offhand = entity.inventory.offhand
    if hand and not offhand and (hand.tags.two_handed or hand.tags.versatile) then
      return roll:assign_reroll(1, 2)
    end
    return roll
  end,
}

Ldump.mark(fighter, "const", ...)
return fighter
