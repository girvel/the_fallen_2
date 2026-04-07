local sprite = require("engine.tech.sprite")
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
  local k = State.camera.SCALE * sprite.cell_size
  x = x * k - dx
  y = y * k - dy

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

  local this_sprite = entity.sprite
  if this_sprite.type == "image"
    or (this_sprite.type == "atlas" and (entity.shader or entity.inventory or entity.layer))
  then
    tk.draw_entity(entity, x, y, State.camera.SCALE)
  elseif this_sprite.type == "atlas" then
    self._sprite_batches[entity.grid_layer]:add(this_sprite.quad, x, y, 0, State.camera.SCALE)
  elseif this_sprite.type == "text" then
    love.graphics.setFont(this_sprite.font)
    love.graphics.print({this_sprite.color, this_sprite.text}, x, y)
  elseif this_sprite.type == "rendered" then
    local drawable = this_sprite:render(entity, dt)
    love.graphics.draw(drawable, x, y, 0, State.camera.SCALE)
  else
    Error("Unknown sprite type %q", this_sprite.type)
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
