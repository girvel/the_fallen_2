local health = require("engine.mech.health")


local warlock = {
  name = "Колдун",
  codename = "warlock",
  hit_die = 8
}

warlock.dark_ones_blessing = function(class_level)
  return {
    name = "Благословение Тёмного",
    codename = "dark_ones_blessing",
    modify_on_kill = function(self, entity, _, target)
      health.push_temp_hp(entity, math.max(1, entity:get_modifier("cha") + class_level))
    end,
  }
end

warlock.spell_slots = function(class_level)
  return {
    name = "Ячейки заклинаний",
    codename = "spell_slots",
    modify_resources = function(self, entity, resources, rest_type)
      if rest_type == "short" or rest_type == "long" then
        local key = "spell_slots_"..math.min(5, math.ceil(class_level / 2))
        local amount
        if class_level <= 1 then
          amount = 1
        elseif class_level <= 10 then
          amount = 2
        elseif class_level <= 16 then
          amount = 3
        else
          amount = 4
        end
        resources[key] = (resources[key] or 0) + amount
      end
      return resources
    end,
  }
end

warlock.agonizing_blast = {
  codename = "agonizing_blast",
  modify_eldritch_blast_damage = function(self, entity, damage_roll)
    return damage_roll + entity:get_modifier("cha")
  end,
}

warlock.repelling_blast = {
  codename = "repelling_blast",
  modify_eldritch_blast_shove_distance = function(self, entity, distance)
    return 2
  end,
}

Ldump.mark(warlock, {}, ...)
return warlock
