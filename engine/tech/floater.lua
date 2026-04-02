local sprite = require("engine.tech.sprite")


local floater = {}

--- Floating text for damage & such
--- @param text string|number
--- @param grid_position vector
--- @param color vector
floater.new = function(text, grid_position, color)
  return {
    boring_flag = true,
    codename = "floater",
    position = grid_position
      + V(math.random() * .5 + .25, math.random() * .5 + .25),
    drift = V(0, -.25),
    sprite = sprite.text(tostring(text), 20, color),
    life_time = 3,
    layer = "fx_over_shadows",
  }
end

Ldump.mark(floater, {}, ...)
return floater
