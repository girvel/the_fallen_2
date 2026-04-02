local ffi = require("ffi")


local sprite = {utility = {}}

local transform_colors, cut_out

--- @alias sprite sprite_image | sprite_atlas | sprite_text | sprite_grid | sprite_rendered

--- @class sprite_rendered
--- @field type "rendered"
--- @field render fun(self: sprite_rendered, entity: entity, dt: number): love.Drawable

--- @class sprite_image
--- @field type "image"
--- @field image love.Image
--- @field anchors table<anchor, vector>
--- @field color vector

--- @param base string|love.ImageData
--- @param color vector?
--- @return sprite_image
sprite.image = Memoize(function(base, color)
  if type(base) == "string" then
    base = love.image.newImageData(base)
  else
    base = base:clone()  --[[@as love.ImageData]]
  end

  local main_color, anchors = transform_colors(base, color)
  return {
    type = "image",
    anchors = anchors or {},
    image = love.graphics.newImage(base),
    color = main_color or Vector.white,
  }
end)

--- @class sprite_atlas NOTICE shared pointer, do not mutate
--- @field type "atlas"
--- @field quad love.Quad
--- @field image love.Image

--- @return sprite_atlas
sprite.from_atlas = Memoize(function(index, cell_size, atlas_image)
  local quad = sprite.utility.get_atlas_quad(index, cell_size, atlas_image:getDimensions())
  local image_data = cut_out(atlas_image, quad)
  local main_color, anchors = transform_colors(image_data)
  return {
    type = "atlas",
    quad = quad,
    image = love.graphics.newImage(image_data),
    anchors = anchors,
    color = main_color,
  }
end)

--- @class sprite_text
--- @field type "text"
--- @field text string
--- @field font love.Font
--- @field color vector

--- @param text string
--- @param size integer
--- @param color vector
--- @return sprite_text
sprite.text = function(text, size, color)
  return {
    type = "text",
    text = text,
    font = love.graphics.newFont("engine/assets/fonts/clacon2.ttf", size),
    color = color,
  }
end

--- @class sprite_grid
--- @field type "grid"
--- @field grid grid<entity>

--- @param grid grid<entity>
--- @return sprite_grid
sprite.grid = function(grid)
  return {
    type = "grid",
    grid = grid,
  }
end

--- @param base love.ImageData
--- @param n integer
sprite.utility.select = function(base, n)
  local w, h = Constants.cell_size, Constants.cell_size
  local result = love.image.newImageData(w, h)
  local base_w = base:getWidth()

  local dx = ((n - 1) * w) % base_w
  local dy = math.floor(((n - 1) * w) / base_w) * h

  local base_ptr = ffi.cast("Color*", base:getFFIPointer())
  local result_ptr = ffi.cast("Color*", result:getFFIPointer())

  for x = 0, w - 1 do
    for y = 0, h - 1 do
      result_ptr[y * w + x] = base_ptr[(dy + y) * base_w + (dx + x)]
    end
  end

  return result
end

--- @param index integer
--- @param cell_size integer
--- @param atlas_w integer
--- @param atlas_h integer
--- @return love.Quad
sprite.utility.get_atlas_quad = function(index, cell_size, atlas_w, atlas_h)
  local w = atlas_w
  local x = (index - 1) * cell_size
  return love.graphics.newQuad(
    x % w, math.floor(x / w) * cell_size, cell_size, cell_size, atlas_w, atlas_h
  )
end

local image_to_canvas = Memoize(function(image)
  local result = love.graphics.newCanvas(image:getDimensions())
  local canvas = love.graphics.getCanvas()
  love.graphics.setCanvas(result)
  love.graphics.draw(image)
  love.graphics.setCanvas(canvas)
  return result
end)

--- @param image love.Image
--- @param quad love.Quad
--- @return love.ImageData
cut_out = function(image, quad)
  local canvas = image_to_canvas(image)
  return canvas:newImageData(0, nil, quad:getViewport())
end

--- @alias anchor "parent"|"hand"|"offhand"|"head"|"right_pocket"
local anchors = {
  parent       = Vector.hex("ff0000"):mul_mut(256):map(math.floor),
  hand         = Vector.hex("fb0000"):mul_mut(256):map(math.floor),
  offhand      = Vector.hex("f70000"):mul_mut(256):map(math.floor),
  head         = Vector.hex("f30000"):mul_mut(256):map(math.floor),
  right_pocket = Vector.hex("ef0000"):mul_mut(256):map(math.floor),
}

local color_eq = function(v, color)
  return (
    math.abs(v[1] - color.r) <= 2 and
    math.abs(v[2] - color.g) <= 2 and
    math.abs(v[3] - color.b) <= 2 and
    (not v[4] or math.abs(v[4] - color.a) <= 2)
  )
end

ffi.cdef [[
  typedef struct {
    uint8_t r;
    uint8_t g;
    uint8_t b;
    uint8_t a;
  } Color;
]]

--- @param base love.ImageData
--- @param target_color vector?
transform_colors = function(base, target_color)
  target_color = target_color and target_color:copy():mul_mut(255):map_mut(math.ceil)
  local w, h = base:getDimensions()
  if w > 128 then return Vector.white, {} end
  local pixels = ffi.cast("Color*", base:getFFIPointer())

  local main_color
  for i = 0, w * h - 1 do
    local color = pixels[i]
    if color.a > 0
      and Fun.iter(anchors):all(function(_, a) return not color_eq(a, color) end)
    then
      main_color = color
      break
    end
  end

  if not main_color then return end

  local result = {}

  for x = 0, w - 1 do
    for y = 0, h - 1 do
      local i = y * w + x
      local color = pixels[i]
      local anchor_name = Fun.iter(anchors)
        :filter(function(_, v) return color_eq(v, color) end)
        :nth(1)

      if anchor_name then
        result[anchor_name] = V(x, y)
        if target_color then
          color.r = target_color.r
          color.g = target_color.g
          color.b = target_color.b
          color.a = target_color.a
        else
          color.r = main_color.r
          color.g = main_color.g
          color.b = main_color.b
          color.a = main_color.a
        end
      elseif target_color and color.a > 0 then
        color.r = target_color.r
        color.g = target_color.g
        color.b = target_color.b
        color.a = target_color.a
      end
    end
  end

  if target_color then
    return V(target_color.r, target_color.g, target_color.b):div_mut(255), result
  else
    return V(main_color.r, main_color.g, main_color.b):div_mut(255), result
  end
end

Ldump.mark(sprite, {}, ...)
return sprite
