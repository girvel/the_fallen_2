local hostility = {}

--- @alias hostility
--- | '"ally"' # allies are equivalent to members of the same faction
--- | '"enemy"' # attack on sight
--- | nil # can be attacked, can become enemies
---

--- @class state_hostility
--- @field _are_hostile table<string, hostility>
--- @field _aggression_subscriptions fun(entity, entity)[]
local methods = {}
local mt = {__index = methods}

--- @return state_hostility
hostility.new = function()
  return setmetatable({
    _are_hostile = {},
    _aggression_subscriptions = {},  -- TODO use weak tables?
  }, mt)
end

--- @param a entity
--- @param b entity
--- @return hostility # nil by default, "ally" if a.faction == b.faction
methods.get = function(self, a, b)
  if not a.faction or not b.faction then
    return nil
  end
  if a.faction == b.faction then return "ally" end
  return self._are_hostile[a.faction .. "_to_" .. b.faction]
end

--- @param faction_a string
--- @param faction_b string
--- @param value hostility
methods.set = function(self, faction_a, faction_b, value)
  local key = faction_a .. "_to_" .. faction_b
  if self._are_hostile[key] == value then return end

  Log.info("%s becomes %s towards %s",
    faction_a,
    value or "neutral",
    faction_b
  )
  self._are_hostile[key] = value
end

--- @param f fun(entity, entity)
--- @return fun(entity, entity)
methods.subscribe = function(self, f)
  Ldump.ignore_upvalue_size(f)
  table.insert(self._aggression_subscriptions, f)
  return f
end

--- @param f fun(entity, entity)
methods.unsubscribe = function(self, f)
  Table.remove(self._aggression_subscriptions, f)
end

--- @param entity entity the one attacking
--- @param target entity
methods.register = function(self, entity, target)
  for _, f in ipairs(self._aggression_subscriptions) do
    f(entity, target)
  end
end

Ldump.mark(hostility, {}, ...)
return hostility
