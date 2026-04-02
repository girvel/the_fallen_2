--- @param self state_mode_game
--- @param dt number
local preprocess = function(self, dt)
  local resolution = V(love.graphics.getDimensions())

  do
    local canvas_resolution = V(self._temp_canvas:getDimensions())
    if resolution ~= canvas_resolution then
      self._temp_canvas = love.graphics.newCanvas(unpack(resolution))
    end
  end

  do
    local canvas_resolution = V(self._main_canvas:getDimensions())
    if resolution ~= canvas_resolution then
      self._main_canvas = love.graphics.newCanvas(unpack(resolution))
    end
  end

  love.graphics.setCanvas(self._main_canvas)
  love.graphics.clear(0, 0, 0, 0)

  local shader = State.shader
  if shader then
    love.graphics.setShader(shader.love_shader)
    if shader.update then
      shader:update(dt)
    end
  end
end

return preprocess
