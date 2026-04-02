local xp = {}

--- @param level integer
--- @return integer
xp.get_proficiency_bonus = function(level)
  return 1 + math.ceil(level / 4)
end

xp.for_level = {[0] = 0, 0, 300, 900, 2700, 6500}

--- @param level integer
--- @return integer
xp.to_reach = function(level)
  local this = xp.for_level[level]
  local prev = xp.for_level[level - 1]
  if not this or not prev then return math.huge end
  return this - prev
end

xp.point_buy = {
  [8] = 0,
  [9] = 1,
  [10] = 2,
  [11] = 3,
  [12] = 4,
  [13] = 5,
  [14] = 7,
  [15] = 9,
}

Ldump.mark(xp, {}, ...)
return xp
