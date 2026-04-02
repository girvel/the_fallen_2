unpack = unpack or table.unpack

local vector = {}

--- @class vector: number[]
--- @field x number alias for `[1]`
--- @field y number alias for `[2]`
--- @field z number alias for `[3]`
--- @field w number alias for `[4]`
--- @field r number alias for `[1]`
--- @field g number alias for `[2]`
--- @field b number alias for `[3]`
--- @field a number alias for `[4]`
--- @operator add(vector): vector
--- @operator sub(vector): vector
--- @operator mul(number): vector
--- @operator div(number): vector
--- @operator unm(): vector
local vector_methods = {}
vector.mt = {}

--- @param ... number
--- @return vector
vector.new = function(...)
  return vector.own({...})
end

--- @param t number[]
--- @return vector
vector.own = function(t)
  return setmetatable(t, vector.mt)
end

--- @param size integer
--- @param f fun(): number
vector.filled = function(size, f)
  local result = {}
  for i = 1, size do
    result[i] = f()
  end
  return vector.own(result)
end

--- Creates vector from its hexadecimal representation; each coordinate is between 0 and 1
--- @param hex string
--- @return vector
vector.hex = function(hex)
  assert(#hex == 6 or #hex == 8)
  local base = {}
  local d = 256
  for i = 1, #hex, 2 do
    table.insert(base, tonumber(hex:sub(i, i + 1), 16) / d)
  end
  base[4] = base[4] or 1
  return vector.own(base)
end

vector.zero = vector.new(0, 0)
vector.one = vector.new(1, 1)
vector.up = vector.new(0, -1)
vector.down = vector.new(0, 1)
vector.left = vector.new(-1, 0)
vector.right = vector.new(1, 0)

vector.wasd = {
  w = vector.up,
  a = vector.left,
  s = vector.down,
  d = vector.right,
}

vector.white = vector.new(1, 1, 1, 1)
vector.black = vector.new(0, 0, 0, 1)
vector.transparent = vector.new(0, 0, 0, 0)
vector.red   = vector.new(1, 0, 0, 1)
vector.green = vector.new(0, 1, 0, 1)
vector.blue  = vector.new(0, 0, 1, 1)

--- @alias direction_name "up" | "left" | "down" | "right"

vector.direction_names = {"up", "left", "down", "right"}
vector.directions = {vector.up, vector.left, vector.down, vector.right}
vector.extended_directions = {
  vector.up, vector.left, vector.down, vector.right,
  vector.new(1, 1), vector.new(1, -1), vector.new(-1, -1), vector.new(-1, 1)
}

--- @param v vector
--- @return string?
vector.name_from_direction = function(v)
  if v == vector.up then return "up" end
  if v == vector.down then return "down" end
  if v == vector.left then return "left" end
  if v == vector.right then return "right" end
end

--- @param f fun(n: number): number
--- @param ... vector
--- @return vector
vector.use = function(f, ...)
  local zip = {}
  for i = 1, select("#", ...) do
    for j, value in ipairs(select(i, ...)) do
      if i == 1 then
        zip[j] = {}
      end
      zip[j][i] = value
    end
  end
  local result = {}
  for _, v in ipairs(zip) do
    table.insert(result, f(unpack(v)))
  end
  return vector.own(result)
end

vector.mt.__eq = function(self, other)
  if #self ~= #other then return false end
  for i = 1, #self do
    if self[i] ~= other[i] then return false end
  end
  return true
end

vector.mt.__add = function(self, other)
  return self:copy():add_mut(other)
end

vector.mt.__sub = function(self, other)
  return self:copy():sub_mut(other)
end

vector.mt.__mul = function(self, other)
  if type(self) == "number" then
    self, other = other, self
  end
  return self:copy():mul_mut(other)
end

vector.mt.__div = function(self, other)
  if type(self) == "number" then
    self, other = other, self
  end
  return self:copy():div_mut(other)
end

vector.mt.__mod = function(self, other)
  if type(self) == "number" then
    self, other = other, self
  end
  return self:copy():mod_mut(other)
end

vector.mt.__unm = function(self)
  return vector.new(unpack(self)):unm_mut()
end

vector.mt.__tostring = function(self)
  local result = "("
  for i, value in ipairs(self) do
    if i > 1 then
      result = result .. ", "
    end
    result = result .. value
  end
  return result .. ")"
end

vector.mt.__le = function(self, other)
  assert(#self == #other)
  for i, value in ipairs(self) do
    if value > other[i] then return false end
  end
  return true
end

vector.mt.__lt = function(self, other)
  assert(#self == #other)
  for i, value in ipairs(self) do
    if value >= other[i] then return false end
  end
  return true
end

vector.mt.__ge = function(self, other)
  return other <= self
end

vector.mt.__gt = function(self, other)
  return other < self
end


--- @generic T
--- @param self T
--- @return T
vector_methods.copy = function(self)
  return vector.new(unpack(self))
end

-- --- @param other vector
-- --- @return boolean
-- vector_methods.color_eq = function(self, other)
--   if rawequal(self, other) then return true end
--   for i, v in ipairs(self) do
--     if math.abs(v - (other[i] or 1)) > 1/256 then
--       return false
--     end
--   end
--   return true
-- end

--- @generic T
--- @param self T
--- @param other vector
--- @return T
vector_methods.add_mut = function(self, other)
  assert(#self == #other)
  for i, value in ipairs(other) do
    self[i] = self[i] + value
  end
  return self
end

--- @generic T
--- @param self T
--- @param other vector
--- @return T
vector_methods.sub_mut = function(self, other)
  assert(#self == #other)
  for i, value in ipairs(other) do
    self[i] = self[i] - value
  end
  return self
end

--- @generic T
--- @param self T
--- @param other number
--- @return T
vector_methods.mul_mut = function(self, other)
  for i = 1, #self do
    self[i] = self[i] * other
  end
  return self
end

--- @generic T
--- @param self T
--- @param other number
--- @return T
vector_methods.div_mut = function(self, other)
  for i = 1, #self do
    self[i] = self[i] / other
  end
  return self
end

--- @generic T
--- @param self T
--- @param other number
--- @return T
vector_methods.mod_mut = function(self, other)
  for i = 1, #self do
    self[i] = self[i] % other
  end
  return self
end

--- @generic T
--- @param self T
--- @return T
vector_methods.unm_mut = function(self)
  for i, value in ipairs(self) do
    self[i] = -value
  end
  return self
end

--- @param self vector
--- @param f fun(n: number): number
--- @return vector
vector_methods.map_mut = function(self, f)
  for i, value in ipairs(self) do
    self[i] = f(value)
  end
  return self
end

--- @param self vector
--- @param f fun(n: number): number
--- @return vector
vector_methods.map = function(self, f)
  return self:copy():map_mut(f)
end

--- @param self vector
--- @return number
vector_methods.square_abs = function(self)
  local result = 0
  for _, value in ipairs(self) do
    result = result + value^2
  end
  return result
end

--- @param self vector
--- @return number
vector_methods.abs = function(self)
  return math.sqrt(self:square_abs())
end

--- @param self vector
--- @return number
vector_methods.abs2 = function(self)
  local result = 0
  for _, value in ipairs(self) do
    result = result + math.abs(value)
  end
  return result
end

local sign = function(x)
  if x > 0 then return 1 end
  if x < 0 then return -1 end
  return 0
end

--- @param self vector
--- @return vector
vector_methods.normalized2 = function(self)
  assert(#self == 2)
  if math.abs(self[1]) > math.abs(self[2]) then
    return vector.new(sign(self[1]), 0)
  elseif self[2] ~= 0 then
    return vector.new(0, sign(self[2]))
  else
    error("Can not normalize vector.zero")
  end
end

--- @param self vector
--- @return vector
vector_methods.normalized = function(self)
  return self:copy():normalized_mut()
end

--- @param self vector
--- @return vector
vector_methods.normalized_mut = function(self)
  local abs = self:abs()
  for i, v in ipairs(self) do
    self[i] = abs == 0 and 0 or (v / abs)
  end
  return self
end

--- Rotate vector 90 degrees counterclockwise
--- @return vector
vector_methods.rotate_mut = function(self)
  assert(#self == 2)
  local t = self[1]
  self[1] = -self[2]
  self[2] = t
  return self
end

--- Rotate vector 90 degrees counterclockwise
--- @return vector
vector_methods.rotate = function(self)
  return self:copy():rotate_mut()
end

local SWIZZLE_BASES = {
  {
    x = 1,
    y = 2,
    z = 3,
    w = 4,
  },
  {
    r = 1,
    g = 2,
    b = 3,
    a = 4,
  },
}

--- @param pattern string
--- @return vector
vector_methods.swizzle = function(self, pattern)
  local base do
    local first_char = pattern:sub(1, 1)
    for _, potential_base in ipairs(SWIZZLE_BASES) do
      if potential_base[first_char] then
        base = potential_base
        goto found
      end
    end

    error(("No swizzle base contains character %q"):format(first_char))
    ::found::
  end

  local result = {}
  for i = 1, #pattern do
    local char = pattern:sub(i, i)
    local index = base[char] or error(("Invalid swizzle character %q"):format(char))
    result[i] = self[index] or error(("No .%s in vector %s"):format(char, self))
  end
  return vector.own(result)
end

vector.mt.__index = function(self, key)
  if type(key) == "number" then
    return rawget(self, key)
  end

  local method = vector_methods[key]
  if method then return method end

  for _, base in ipairs(SWIZZLE_BASES) do
    local index = base[key]
    if index then
      return rawget(self, index)
    end
  end

  error(("No .%s in vector"):format(key))
end

vector.mt.__newindex = function(self, key, value)
  if type(key) == "number" then
    rawset(self, key, value)
    return
  end

  for _, base in ipairs(SWIZZLE_BASES) do
    local index = base[key]
    if index then
      rawset(self, index, value)
      return
    end
  end

  error(("No .%s in vector"):format(key))
end

return vector
