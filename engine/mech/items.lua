local animated = require("engine.tech.animated")
local item = require("engine.tech.item")


local items = {}

--- @alias hair_type "hair_short_1"|"hair_short_2"|"hair_short_3"|"hair_long"
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
  local e = {
    anchor = "head"
  }
  item.mix_min(e, "hair")
  animated.mix_in(e, "engine/assets/animations/" .. type, "directional", color)
  return e
end

--- @param type "tatoo_snake"|"scar_cheek"|"scar_eye"
items.skin = function(type)
  local e = {
    codename = type,
    slot = "skin",
    anchor = "head",
  }
  item.mix_in(e, "engine/assets/animations/" .. type)
  return e
end

return items
