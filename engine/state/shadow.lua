local level = require("engine.tech.level")
local sprite = require("engine.tech.sprite")


local shadow = {}

--- @class state_shadow
--- @field static grid<number>
local methods = {}
shadow.mt = {__index = methods}

--- @param base_grid grid<number>
--- @return state_shadow
shadow.new = function(base_grid)
  return setmetatable({
    static = base_grid,
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
        local vision_size = vision_end:copy():sub_mut(vision_start):add_mut(Vector.one)

        local light_grid = Grid.new(vision_size, function() return 0 end)

        for relx = 1, vision_size.x do
          for rely = 1, vision_size.y do
            local x = vision_start.x + relx - 1
            local y = vision_start.y + rely - 1

            local light_value = 0
            for _, layer_name in ipairs(level.grid_layers) do
              local e = State.grids[layer_name]:unsafe_get(x, y)
              if not e then goto continue end
              if e.light_intensity then
                light_value = math.max(light_value, e.light_intensity)
              end

              if not e.inventory then goto continue end
              for _, item in pairs(e.inventory) do
                if item.light_intensity then
                  light_value = math.max(light_value, item.light_intensity)
                end
              end

              ::continue::
            end

            -- NEXT optimize
            if light_value > 0 then
              local light_value_int = math.ceil(light_value / .1)
              for d in Iteration.rhombus(light_value_int) do
                local x1 = relx + d.x
                local y1 = rely + d.y
                if light_grid:can_fitn(x1, y1) then
                  local v = light_grid:unsafe_get(x1, y1) + (light_value_int - d:abs2()) * .1
                  light_grid:unsafe_set(x1, y1, v)
                end
              end
            end
          end
        end

        for x = vision_start.x, vision_end.x do
          for y = vision_start.y, vision_end.y do
            local relx = x - vision_start.x + 1
            local rely = y - vision_start.y + 1
            local shadow_value = State.shadow.static:unsafe_get(x, y)
            local light_value = light_grid:unsafe_get(relx, rely)
            shadow_value = math.max(0, shadow_value - light_value)

            love.graphics.setColor(0, 0, 0, shadow_value)
            love.graphics.rectangle(
              "fill",
              ox + (relx - 1) * k,
              oy + (rely - 1) * k,
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
