local vector = require("engine.lib.vector")
local mathx = require("engine.lib.math")


local polygon = {}

--- @class polygon
--- @field vertices vector[]
--- @field start vector
--- @field finish vector
local methods = {}
polygon.mt = {__index = methods}

--- @param vertices vector[]
--- @return polygon
polygon.new = function(vertices)
  return setmetatable({
    vertices = vertices,
    start = vector.use(math.min, unpack(vertices)),
    finish = vector.use(math.max, unpack(vertices)),
  }, polygon.mt)
end

local probe, inside_polygon

--- @param point vector
methods.includes = function(self, point)
  return self.start <= point
    and self.finish >= point
    and inside_polygon(point, self.vertices)
end

--- @param start vector
--- @param p1 vector
--- @param p2 vector
--- @return boolean
probe = function(start, p1, p2)
  local xr, yr = unpack(start)
  local x1, y1 = unpack(p1)
  local x2, y2 = unpack(p2)

  if not ((y1 <= yr and y2 > yr) or (y2 <= yr and y1 > yr)) then
    return false
  end

  if y1 == y2 then return yr == y1 and xr <= math.max(x1, x2) end

  local x_intersect
  if x1 == x2 then
    x_intersect = x1
  else
    local k = (x2 - x1) / (y2 - y1)
    x_intersect = (yr - y1) * k + x1
  end

  return x_intersect > xr
end

--- @param p vector
--- @param vertices vector[]
--- @return boolean
inside_polygon = function(p, vertices)
  local count = 0
  for i = 1, #vertices do
    if probe(p, vertices[i], vertices[mathx.loopmod(i + 1, #vertices)]) then
      count = count + 1
    end
  end

  return count % 2 == 1
end

return polygon
