local combat = {}
-- TODO rename to round_robin?

--- @class state_combat
--- @field list entity[]
--- @field current_i integer
local methods = {}
local mt = {__index = methods}

--- @param list entity[]
--- @return state_combat
combat.new = function(list)
  assert(Fun.iter(list):all(function(e) return State:exists(e) end))
  return setmetatable({
    list = list,
    current_i = 1,
  }, mt)
end

methods.get_current = function(self)
  return self.list[self.current_i]
end

methods.remove = function(self, element)
  local i = Table.index_of(self.list, element)
  if not i then return end
  if i < self.current_i then
    self.current_i = self.current_i - 1
  end
  table.remove(self.list, i)
  self.current_i = Math.loopmod(self.current_i, #self.list)
end

methods._pass_turn = function(self)
  self.current_i = Math.loopmod(self.current_i + 1, #self.list)
end

Ldump.mark(combat, {}, ...)
return combat
