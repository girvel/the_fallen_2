local tk = require("engine.state.mode.tk")


--- @param self state_mode_game
--- @param entity table
--- @param dt number
local draw_entity = function(self, entity, dt)
  if entity.sprite.type == "grid" then
    return self:draw_grid(entity.layer, entity.sprite.grid, dt)
  end

  local x, y = unpack(entity.position)
  local dx, dy = unpack(State.camera.offset)
  local k = State.camera.SCALE * Constants.cell_size
  x = dx + x * k
  y = dy + y * k

  local canvas
  if entity.shader then
    canvas = love.graphics.getCanvas()
    love.graphics.setShader(entity.shader.love_shader)
    love.graphics.setCanvas(self._temp_canvas)
    -- OPT isn't it too expensive to draw the image the size of the screen?
    love.graphics.clear()
    if entity.shader.preprocess then
      entity.shader:preprocess(entity, dt)
    end
  end

  if State.shader and State.shader.preprocess then
    State.shader:preprocess(entity, dt)
  end

  local sprite = entity.sprite
  if sprite.type == "image"
    or (sprite.type == "atlas" and (entity.shader or entity.inventory or entity.layer))
  then
    tk.draw_entity(entity, x, y, State.camera.SCALE)
  elseif sprite.type == "atlas" then
    self._sprite_batches[entity.grid_layer]:add(sprite.quad, x, y, 0, State.camera.SCALE)
  elseif sprite.type == "text" then
    love.graphics.setFont(sprite.font)
    love.graphics.print({sprite.color, sprite.text}, x, y)
  elseif sprite.type == "rendered" then
    local drawable = sprite:render(entity, dt)
    love.graphics.draw(drawable, x, y, 0, State.camera.SCALE)
  else
    Error("Unknown sprite type %q", sprite.type)
  end

  if entity.shader then
    love.graphics.setCanvas(canvas)
    --- @diagnostic disable-next-line
    love.graphics.setShader(State.shader and State.shader.love_shader)
    love.graphics.draw(self._temp_canvas)
  end
end

Ldump.mark(draw_entity, {}, ...)
return draw_entity
