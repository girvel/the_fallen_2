local shadow = {}

--- @class state_shadow
--- @field static grid<number>
local methods = {}
shadow.mt = {__index = methods}

--- @param grid_size vector
--- @return state_shadow
shadow.new = function(grid_size)
  return setmetatable({
    static = Grid.new(grid_size, function() return 0 end)
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
      love.graphics.print("Hello, world", 100, 100)
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
