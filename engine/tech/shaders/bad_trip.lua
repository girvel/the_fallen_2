local bad_trip = {}

--- @class shaders_bad_trip: shader
--- @field now number
--- @field duration number
local methods = {}
bad_trip.mt = {__index = methods}

--- @return shaders_bad_trip
bad_trip.new = function(duration)
  local result = setmetatable({
    duration = duration,
    now = 0,
    love_shader = love.graphics.newShader(
      love.filesystem.read("engine/tech/shaders/bad_trip.frag"),
      nil  --- @diagnostic disable-line
    ),
  }, bad_trip.mt)

  return result
end

bad_trip.mt.__serialize = function(self)
  local duration = self.duration
  local now = self.now
  return function()
    local result = bad_trip.new(duration)
    result.now = now
    return result
  end
end

--- @param x number
--- @param a number left-side slope proportion
--- @param b number right-side slope proportion
local pcurve = function(x, a, b)
  local k = (a + b)^(a + b) / a^a / b^b
  return k * x^a * (1 - x)^b
end

methods.update = function(self, dt)
  self.now = self.now + dt
  local degree
  if self.now <= self.duration then
    degree = pcurve(self.now / self.duration, 3, 1)
  else
    degree = 0
  end
  self.love_shader:send("degree", degree)
end

Ldump.mark(bad_trip, {mt = "const"}, ...)
return bad_trip
