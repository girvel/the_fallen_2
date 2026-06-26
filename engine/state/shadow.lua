local sprite = require("engine.tech.sprite")
local shadow = {}

--- @class state_shadow
--- @field static grid<number>
local methods = {}
shadow.mt = {__index = methods}

local VALUE_HOUSE = .3

--- @param grid_size vector
--- @return state_shadow
shadow.new = function(grid_size)
  local static = Grid.new(grid_size, function() return 0 end)
  -- NEXT shadows in houses should be manual
  local house_starts = State.level:position_sequence("house")
  local house_ends = State.level:position_sequence("house_end")
  assert(#house_starts == #house_ends)
  for i = 1, #house_starts do
    for x = house_starts[i].x, house_ends[i].x do
      for y = house_starts[i].y, house_ends[i].y do
        static:unsafe_set(x, y, VALUE_HOUSE)
      end
    end
  end
  return setmetatable({
    static = static,
  }, shadow.mt)
end

local shadow_sprite = {
  type = "rendered",
  anchor = "screen",
  --- @param entity entity
  --- @param dt number
  render = function(self, entity, dt)
    local prev_canvas = love.graphics.getCanvas()
    love.graphics.setCanvas(entity._shadow_canvas)
      love.graphics.clear(Vector.transparent)

      local k = State.camera.scale * sprite.cell_size
      local ox, oy = unpack(State.camera.offset:map(function(a) return (-a) % k - k end))

      local prev_color = {love.graphics.getColor()}
        local vision_start = State.camera.vision_start
        local vision_end = State.camera.vision_end

        for x = vision_start.x, vision_end.x do
          for y = vision_start.y, vision_end.y do
            local shadow_value = State.shadow.static:unsafe_get(x, y)
            love.graphics.setColor(0, 0, 0, shadow_value)
            love.graphics.rectangle(
              "fill",
              ox + (x - vision_start.x) * k,
              oy + (y - vision_start.y) * k,
              k, k
            )
          end
        end
        love.graphics.rectangle("fill", ox, oy, k, k)
      love.graphics.setColor(prev_color)
    love.graphics.setCanvas(prev_canvas)
    return entity._shadow_canvas
  end,
}

shadow.new_entity = function()
  return {
    codename = "shadow_render",
    sprite = shadow_sprite,
    layer = "shadows",
    position = Vector.zero,
    _shadow_canvas = love.graphics.newCanvas(),
  }
end

Ldump.mark(shadow, {
  mt = "const",
  construct_object = {shadow_sprite = {}},
},...)
return shadow
