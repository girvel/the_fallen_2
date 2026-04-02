local animated = require("engine.tech.animated")
local item = require("engine.tech.item")


local items = {}

--- @alias hair_type "short_hair_1"|"short_hair_2"|"short_hair_3"|"long_hair"
--- @enum (key) hair_color
local hair_colors = {
  gray = Vector.hex("4f5a5c"),
  red = Vector.hex("e86c46"),
  brown = Vector.hex("544747"),
}

--- @param type hair_type
--- @param color hair_color|vector
items.hair = function(type, color)
  color = hair_colors[color] or color  --- @cast color vector

  return Table.extend(
    item.mixin_min("hair"),
    animated.mixin("assets/animations/" .. type, "directional", color),
    {
      anchor = "head",
    }
  )
end

--- @param type "snake_tatoo"|"cheek_scar"|"eye_scar"
items.skin = function(type)
  return Table.extend(item.mixin("assets/animations/" .. type), {
    codename = type,
    slot = "skin",
    anchor = "head",
  })
end

return items
