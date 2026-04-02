local memory = require("engine.tech.shaders.memory")


--- @param self state_mode_game
--- @param dt number
local postprocess = function(self, dt)
  love.graphics.setShader()
  if State.player.is_memory_enabled then
    love.graphics.setCanvas(State.player.memory)
    love.graphics.draw(self._main_canvas, unpack(-State.camera.offset))
  end

  love.graphics.setCanvas(Kernel.screenshot)
  if State.player.is_memory_enabled then
    love.graphics.setShader(memory.love_shader)
    love.graphics.draw(State.player.memory, unpack(State.camera.offset))
  end
  love.graphics.setShader()
  love.graphics.draw(self._main_canvas)
end

return postprocess
