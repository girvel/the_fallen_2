--- @class shader
--- @field love_shader love.Shader
--- @field preprocess? fun(self: shader, entity: entity, dt: number)
--- @field update? fun(self: shader, dt: number)


local shaders = {}

local COLORS_N = 39

local get_stdlib = Memoize(function()
  return string.format(
    love.filesystem.read("engine/tech/shaders/stdlib.frag"),
    COLORS_N,
    COLORS_N
  )
end)

--- @param path string
--- @return love.Shader
shaders.build = function(path)
  local result = love.graphics.newShader(
    get_stdlib() .. love.filesystem.read(path),
  nil)  --- @diagnostic disable-line

  do
    local palette = {}
    local palette_image_data = love.image.newImageData("engine/assets/sprites/palette.png")
    for x = 0, COLORS_N - 1 do
      table.insert(palette, {palette_image_data:getPixel(x, 0)})
    end
    result:send("palette", unpack(palette))
  end

  Ldump.serializer.handlers[result] = function()
    return shaders.build(path)
  end
  return result
end

Ldump.mark(shaders, {}, ...)
return shaders
