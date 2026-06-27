local animated = require("engine.tech.animated")
local item = require("engine.tech.item")


local items = {}
-- TODO think: maybe default weapons/armor should be a part of the engine?

local arrow = function()
  local e = {
    codename = "arrow",
    boring_flag = true,
  }
  animated.mix_in(e, "assets/animations/arrow")
  item.mix_min(e, "hand")
  return e
end

items.short_bow = function()
  local e = {
    name = "короткий лук",
    codename = "short_bow",
    damage_roll = D(6),
    tags = {
      two_handed = true,
      ranged = true,
    },
    slot = "offhand",
    projectile_factory = arrow,
  }
  item.mix_in(e, "assets/animations/short_bow")
  return e
end

items.axe = function()
  local e = {
    name = "топорик",
    codename = "axe",
    damage_roll = D(6),
    tags = {},
    slot = "hands",
  }
  item.mix_in(e, "assets/animations/axe")
  return e
end

items.knife = function()
  local e = {
    name = "кухонный нож",
    codename = "knife",
    damage_roll = D(4),
    tags = {
      finesse = true,
      light = true,
    },
    slot = "hands",
    light_intensity = .5,
  }
  item.mix_in(e, "assets/animations/knife")
  return e
end

Ldump.mark(items, {}, ...)
return items
