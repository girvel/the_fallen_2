--- Math extension module
---
--- Contains additional math functions
local mathx = {}

--- Returns 1 if x is positive, -1 if negative, 0 if 0
--- @param x number
--- @return number
mathx.sign = function(x)
  if x == 0 then return 0 end
  if x > 0 then return 1 end
  return -1
end

--- @param ... number
--- @return number
mathx.median = function(...)
  local t = {...}
  table.sort(t)
  return t[math.ceil(#t / 2)]
end

--- @param t number[]
--- @return number
mathx.average = function(t)
  return Fun.iter(t):sum() / #t
end

--- Loops a between 1 and b the same way a % b loops a in between 0 and b - 1 in 0-based indexing
--- @param a number
--- @param b number
--- @return number
mathx.loopmod = function(a, b)
  return (a - 1) % b + 1
end

return mathx
