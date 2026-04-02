local is_blind_for = function(x, y)
  local player = State.player
  if not player.is_blind then return false end

  local dx, dy = unpack(player.direction)
  local px, py = unpack(player.position)
  x = x - px
  y = y - py
  if dx == 0 then
    return dy * y > math.abs(x)
  else
    return dx * x > math.abs(y)
  end
end


--- @param self state_mode_game
--- @param grid grid<entity>
--- @param dt number
local draw_grid = function(self, layer, grid, dt)
  if State.player.fov_r == 0 then
    if grid[State.player.position] == State.player then
      self:draw_entity(State.player, dt)
    end
    return
  end

  local vision_map = State.player.ai._vision_map
  if not vision_map then return end

  local sprite_batch = self._sprite_batches[layer]
  if sprite_batch then
    sprite_batch:clear()
  end

  for x = State.camera.vision_start.x, State.camera.vision_end.x do
    for y = State.camera.vision_start.y, State.camera.vision_end.y do
      if not vision_map:is_visible_unsafe(x, y)
        or is_blind_for(x, y)
      then goto continue end

      local e = grid:unsafe_get(x, y)
      if not e or not e.sprite then goto continue end

      local is_hidden_by_perspective = (
        not vision_map:is_transparent_unsafe(x, y)
        and e.perspective_flag
        and e.position.y > State.player.position.y
      )
      if is_hidden_by_perspective then goto continue end

      self:draw_entity(e, dt)
      ::continue::
    end
  end

  if sprite_batch then
    love.graphics.draw(sprite_batch)
  end
end

Ldump.mark(draw_grid, {}, ...)
return draw_grid
