local constants = require("engine.tech.constants")


local winter = {}

local K = State.camera.SCALE * constants.cell_size

--- @param tint vector 3-dimensional
--- @param intensity number
--- @param brightness number
--- @param brightness_inside number
--- @param contrast_midpoint number
--- @param contrast_factor number
local build_love_shader = function(tint, intensity, brightness, brightness_inside, contrast_midpoint, contrast_factor)
  assert(#tint == 3)

  local result = love.graphics.newShader(
    love.filesystem.read("engine/tech/shaders/winter.frag"),
    nil  --- @diagnostic disable-line
  )
  result:send("tint", tint)
  result:send("intensity", intensity)
  result:send("brightness", brightness)
  result:send("brightness_inside", brightness_inside)
  result:send("contrast_midpoint", contrast_midpoint)
  result:send("contrast_factor", contrast_factor)

  local ignore do
    local canvas = love.graphics.newCanvas(unpack(State.level.grid_size * K))
    local prev_canvas = love.graphics.getCanvas()
    love.graphics.setCanvas(canvas)
    love.graphics.setColor(Vector.red)
      love.graphics.clear(0, 0, 0)

      local starts = State.runner:position_sequence("house")
      local ends = State.runner:position_sequence("house_end")

      for _, start, finish in Fun.zip(starts, ends) do
        local size = finish:copy()
          :sub_mut(start)
          :add_mut(Vector.one)
          :mul_mut(K)

        start = start * K

        love.graphics.rectangle("fill", start.x, start.y, size.x, size.y)
      end

      local no_winter_shader = State.runner:position_sequence("no_winter_shader")
      for _, p in ipairs(no_winter_shader) do
        local x, y = unpack(p * K)
        love.graphics.rectangle("fill", x, y, K, K)
      end
    love.graphics.setColor(Vector.white)
    love.graphics.setCanvas(prev_canvas)
    ignore = canvas
  end
  result:send("ignore", ignore)
  result:send("ignore_size", {ignore:getDimensions()})

  return result
end

local methods = {}
winter.mt = {__index = methods}

--- @return shader
winter.new = function()
  local result = setmetatable({
    love_shader = build_love_shader(
      Vector.hex("3e4957"):swizzle("rgb"),
      .6, 1.2, .8,
      V(.5, .5, .5), 1.5
    )
  }, winter.mt)

  Ldump.serializer.handlers[result] = winter.new
  return result
end

methods.update = function(self, dt)
  self.love_shader:send("offset", -State.camera.offset)
end

Ldump.mark(winter, "const", ...)
return winter

