local aquule = {
  love_shader = love.graphics.newShader(
    love.filesystem.read("engine/tech/shaders/aquule.frag"),
    nil  --- @diagnostic disable-line
  )
}

Ldump.mark(aquule, "const", ...)
return aquule
