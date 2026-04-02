local memory = {
  love_shader = love.graphics.newShader(
    love.filesystem.read("engine/tech/shaders/memory.frag"),
    nil  --- @diagnostic disable-line
  ),
}

Ldump.mark(memory, "const", ...)
return memory
