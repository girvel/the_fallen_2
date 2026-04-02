local module_mt = {}
--- @overload fun(integer): d
local d = setmetatable({}, module_mt)

----------------------------------------------------------------------------------------------------
-- [SECTION] Die
----------------------------------------------------------------------------------------------------

--- @alias die_advantage "none"|"advantage"|"disadvantage"

--- @class die
--- @field sides_n integer
--- @field advantage die_advantage
--- @field reroll integer[]
local die_methods = {}
d.die_mt = {__index = die_methods}

d.die_new = function(sides_n)
  return setmetatable({
    sides_n = sides_n,
    advantage = "none",
    reroll = {},
  }, d.die_mt)
end

local ADVANTAGE_CHAR = {
  none = "",
  advantage = "↑",
  disadvantage = "↓",
}

d.die_mt.__tostring = function(self)
  return ("d%s%s%s"):format(
    self.sides_n,
    ADVANTAGE_CHAR[self.advantage],
    #self.reroll > 0 and ("🗘(%s)"):format(table.concat(self.reroll, ",")) or ""
  )
end

--- @return integer
die_methods.roll = function(self)
  local result = math.random(self.sides_n)
  if self.advantage == "advantage" then
    result = math.max(result, math.random(self.sides_n))
  elseif self.advantage == "disadvantage" then
    result = math.min(result, math.random(self.sides_n))
  end
  if Table.contains(self.reroll, result) then
    result = math.random(self.sides_n)
  end
  return result
end

----------------------------------------------------------------------------------------------------
-- [SECTION] Dice
----------------------------------------------------------------------------------------------------

--- @class d
--- @field dice die[]
--- @field bonus integer
--- @operator add(d): d
--- @operator add(integer): d
--- @operator sub(integer): d
--- @operator mul(integer): d
local methods = {}
d.mt = {__index = methods}

--- @param dice die[]
--- @param bonus integer
d.new = function(dice, bonus)
  return setmetatable({
    dice = dice,
    bonus = bonus,
  }, d.mt)
end

module_mt.__call = function(_, sides_n)
  return d.new({d.die_new(sides_n)}, 0)
end

d.mt.__add = function(self, other)
  if type(other) == "number" then
    return d.new(Table.deep_copy(self.dice), self.bonus + other)
  end

  if type(other) == "table" then
    return d.new(
      Table.concat(Table.deep_copy(self.dice), other.dice),
      self.bonus + other.bonus
    )
  end

  Error("Trying to add %s to a dice roll", type(other))
end

d.mt.__sub = function(self, other)
  if type(other) == "number" then
    return d.new(Table.deep_copy(self.dice), self.bonus - other)
  end

  Error("Trying to subtract %s to a dice roll", type(other))
end

d.mt.__mul = function(self, other)
  assert(type(other) == "number")
  return d.new(
    Fun.iter(self.dice)
      :cycle()
      :take_n(#self.dice * other)
      :map(function(die) return Table.deep_copy(die) end)
      :totable(),
    self.bonus * other
  )
end

d.mt.__tostring = function(self)
  local dice = table.concat(
    Fun.iter(self.dice)
      :map(tostring)
      :totable(),
    " + "
  )
  local bonus = ""
  if self.bonus ~= 0 then
    bonus = ("%+i"):format(self.bonus)
    bonus = " " .. bonus:sub(1, 1) .. " " .. bonus:sub(2)
  end
  return dice .. bonus
end

--- @return string
methods.simplified = function(self)
  local min = self:min()
  local max = self:max()
  if min == max then return tostring(min) end
  return ("%s–%s"):format(self:min(), self:max())
end

--- @return integer
methods.roll = function(self)
  local rolls = Fun.iter(self.dice)
    :map(function(die) return die:roll() end)
    :totable()
  local result = Fun.iter(rolls):sum() + self.bonus

  Log.debug(
    table.concat(
      Fun.zip(self.dice, rolls)
        :map(function(die, r)
          return ("%s (%s)"):format(r, tostring(die))
        end)
        :totable(),
      " + "
    ) .. " + " .. self.bonus .. " = " .. result
  )

  return result
end

--- @return integer
methods.max = function(self)
  return Fun.iter(self.dice)
    :map(function(die) return die.sides_n end)
    :sum() + self.bonus
end

--- @return integer
methods.min = function(self)
  return #self.dice + self.bonus
end

--- @generic T
--- @param self T
--- @param value die_advantage
--- @return T
methods.set = function(self, value)
  --- @cast self d
  for _, die in ipairs(self.dice) do
    if value == "advantage" and die.advantage == "disadvantage"
      or value == "disadvantage" and die.advantage == "advantage"
    then
      die.advantage = "none"
    else
      die.advantage = value
    end
  end
  return self
end

--- @param ... integer
methods.assign_reroll = function(self, ...)
  for i = 1, select("#", ...) do
    local to_reroll = select(i, ...)
    for _, die in ipairs(self.dice) do
      if not Table.contains(die.reroll, to_reroll) then
        table.insert(die.reroll, to_reroll)
      end
    end
  end
  return self
end

--- @generic T: d
--- @param self T
--- @return T
methods.copy = function(self)
  --- @cast self d
  return d.new(Table.deep_copy(self.dice), self.bonus)
end

return d
