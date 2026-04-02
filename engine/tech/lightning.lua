local colors = require("engine.tech.colors")
local lightning = {}

--- @alias lightning lightning_strict|table
--- @class lightning_strict: entity_strict
--- @field _lightning_state lightning_state

--- @class lightning_state
--- @field from vector
--- @field to vector
--- @field canvas love.Canvas

--- @param from vector
--- @param to vector
--- @return lightning
lightning.new = function(from, to)
  local start = Vector.use(math.min, from, to)
  local finish = Vector.use(math.max, from, to)
  return {
    codename = "lightning",
    position = start,
    layer = "weather",
    sprite = {
      type = "rendered",
      render = lightning.render,
    },

    _lightning_state = {
      from = (from - start + V(.5, .5)) * Constants.cell_size,
      to = (to - start + V(.5, .5)) * Constants.cell_size,
      canvas = love.graphics.newCanvas(unpack((finish - start + Vector.one) * Constants.cell_size)),
    },
  }
end

--- @param self sprite_rendered
--- @param entity lightning
--- @param dt number
--- @return love.Canvas
lightning.render = function(self, entity, dt)
  local state = entity._lightning_state

  local canvas = love.graphics.getCanvas()
  love.graphics.setCanvas(state.canvas)
    love.graphics.clear()
    love.graphics.setColor(colors.white)
      love.graphics.line(state.from.x, state.from.y, state.to.x, state.to.y)
    love.graphics.setColor(Vector.white)
  love.graphics.setCanvas(canvas)

  return state.canvas
end

Ldump.mark(lightning, {render = {}}, ...)
return lightning
