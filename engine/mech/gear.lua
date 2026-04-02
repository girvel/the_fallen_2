local gear = {}

gear.medium = {
  modify_dex_armor_bonus = function(self, entity, bonus)
    return math.min(bonus, 2)
  end,
}

gear.heavy = {
  modify_dex_armor_bonus = function(self, entity, bonus)
    return 0
  end,
}

gear.helmet = {
  modify_armor = function(self, entity, armor)
    return armor + 1
  end,
}

gear.medium_helmet = Table.extend({
   modify_armor = function(self, entity, armor)
    return armor + 2
  end,
}, gear.medium)

gear.heavy_helmet = Table.extend({
   modify_armor = function(self, entity, armor)
    return armor + 3
  end,
}, gear.heavy)

gear.light_armor = {
  modify_armor = function(self, entity, armor)
    return armor + 1
  end,
}

gear.medium_armor = Table.extend({
   modify_armor = function(self, entity, armor)
    return armor + 2
  end,
}, gear.medium)

gear.heavy_armor = Table.extend({
   modify_armor = function(self, entity, armor)
    return armor + 4
  end,
}, gear.heavy)

gear.weak_shield = {
  modify_armor = function(self, entity, armor)
    return armor + 1
  end,
}

gear.shield = {
  modify_armor = function(self, entity, armor)
    return armor + 2
  end,
}

Ldump.mark(gear, "const", ...)
return gear
