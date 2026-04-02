local feats = {}

feats.savage_attacker = {
  name = "Неистовый атакующий",
  codename = "savage_attacker",
  description = "Атаки наносят больше урона",

  modify_damage_roll = function(self, entity, roll, slot)
    if entity.inventory[slot] then
      return roll:set("advantage")
    end
    return roll
  end,
}

-- TODO bonus action attack
-- TODO passive
feats.great_weapon_master = {
  name = "Мастер большого оружия",
  codename = "great_weapon_master",
  description = "Шанс попадания двуручным оружием меньше на 25%, урон выше на 10",

  modify_attack_roll = function(self, entity, roll, slot)
    local item = entity.inventory[slot]
    if item and item.tags.heavy then
      return roll - 5
    end
    return roll
  end,

  modify_damage_roll = function(self, entity, roll, slot)
    local item = entity.inventory[slot]
    if item and item.tags.heavy then
      return roll + 10
    end
    return roll
  end,
}

feats.sharpshooter = {
  name = "Меткий стрелок",
  codename = "sharpshooter",
  description = "Шанс попадания дальнобойным оружием меньше на 25%, урон выше на 10",

  modify_attack_roll = function(self, entity, roll, slot)
    local item = entity.inventory[slot]
    if item and item.tags.ranged then
      return roll - 5
    end
    return roll
  end,

  modify_damage_roll = function(self, entity, roll, slot)
    local item = entity.inventory[slot]
    if item and item.tags.ranged then
      return roll + 10
    end
    return roll
  end,
}

feats.dual_wielder = {
  name = "Мастер двух оружий",
  codename = "dual_wielder",
  description = "Два оружия в руках дают +1 к броне, можно держать более тяжёлое оружие в двух руках",

  modify_armor = function(self, entity, armor)
    local hand = entity.inventory.hand
    local offhand = entity.inventory.offhand
    if hand and hand.damage_roll and offhand and offhand.damage_roll then
      return armor + 1
    end

    return armor
  end,

  modify_light = function(self, entity, value, item)
    return not item.tags.two_handed
  end,
}

feats.durable = {
  name = "Стойкий",
  codename = "durable",
  description = "+1 к Телосложению, перевязывание ран работает стабильнее",

  modify_hit_dice_result = function(self, entity, value)
    local con = entity:get_modifier("con")
    return math.max(con * 2, value)
  end,

  modify_ability_score = function(self, entity, score, ability)
    if ability == "con" then
      return score + 1
    end
    return score
  end,
}

feats.tough = {
  name = "Крепкий",
  codename = "tough",
  description = "+2 ХП за уровень",

  modify_max_hp = function(self, entity, value)
    return value + entity.level * 2
  end,
}

Ldump.mark(feats, "const", ...)
return feats
