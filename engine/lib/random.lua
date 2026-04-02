--- Convience module for randomization
local random = {}

--- Returns true with given chance
--- @param chance number
--- @return boolean
random.chance = function(chance)
	return math.random() < chance
end

--- @generic T
--- @param ... T
--- @return T
random.choice = function(...)
  local len = select("#", ...)
  assert(len > 0, "Can not random.choice with empty list")
  return select(math.random(len), ...)
end

--- Chooses random element from the list
--- @generic T
--- @param list T[]
--- @return T
random.item = function(list)
  assert(#list > 0, "Can not random.choice with empty list")
  return list[math.random(#list)]
end

--- Random float in range
--- @param a number
--- @param b number
--- @return number
random.float = function(a, b)
  return math.random() * (b - a) + a
end

--- @param total_amount integer
--- @param collection_length integer
--- @return integer[]
random.distribute = function(total_amount, collection_length)
  local splits = {}
  for _ = 1, collection_length - 1 do
    table.insert(splits, math.random(total_amount))
  end
  table.sort(splits)

  local result = {}
  local prev = 0
  for _, split in ipairs(splits) do
    table.insert(result, split - prev)
    prev = split
  end
  table.insert(result, total_amount - prev)

  return result
end

--- @generic T
--- @param list T[]
--- @param collection_length integer
--- @return T[][]
random.distribute_items = function(list, collection_length)
  local result = random.distribute(#list, collection_length)
  for i, n in ipairs(result) do
    local l = {}
    for _ = 1, n do
      table.insert(l, table.remove(list))
    end

    --- @diagnostic disable-next-line
    result[i] = l
  end
  return result
end

return random
