local shaders = require("engine.tech.shaders.init")


local water = {}

--- @param palette_path string
--- @param palette_real_colors_n number
--- @return shader
water.new = Memoize(function(palette_path, palette_real_colors_n)
  return {
    love_shader = shaders.build("engine/tech/shaders/water.frag"),

    preprocess = function(self, entity, dt)
      local offset = ((love.timer.getTime() * entity.water_velocity) % Constants.cell_size):map(math.floor) / Constants.cell_size
      self.love_shader:send("offset", offset)
      local image = self:_get_reflection_image(entity)
      self.love_shader:send("reflects", image ~= nil)
      if not image then return end
      self.love_shader:send("reflection", image)
    end,

    _get_reflection_image = function(_, entity)
      local reflected = State.grids.solids:slow_get(entity.position + Vector.up)
      if not reflected or reflected.low_flag then return nil end
      return reflected.sprite.image
    end,
  }
end)

Ldump.mark(water, {}, ...)
return water
