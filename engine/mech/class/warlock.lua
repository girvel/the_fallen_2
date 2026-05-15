local health = require("engine.mech.health")
local warlock = {
  name = "Колдун",
  codename = "warlock",
  hit_die = 8
}

warlock.dark_ones_blessing = {
  name = "Благословение Тёмного",
  codename = "dark_ones_blessing",
  modify_on_kill = function(self, entity, _, target)
    -- originally used warlock level, but classes have levels only for State.player
    health.push_temp_hp(entity, math.max(1, entity:get_modifier("cha") + (entity.level or 1)))
  end,
}

Ldump.mark(warlock, {}, ...)
return warlock
