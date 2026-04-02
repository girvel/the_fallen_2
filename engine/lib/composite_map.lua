local composite_map = {}

--- @class composite_map
--- @field _items table<any, composite_map>
--- @field _value any
--- @field _weakness? "weak"
local methods = {}
composite_map.mt = {__index = methods}
composite_map._weak_items_mt = {__mode = "k"}

--- @param weakness? "weak"
--- @return composite_map
composite_map.new = function(weakness)
  local items = {}
  if weakness == "weak" then
    setmetatable(items, composite_map._weak_items_mt)
  end
  return setmetatable({_items = items, _weakness = weakness}, composite_map.mt)
end

--- @param value any
--- @param head any
--- @param ... any
methods.set = function(self, value, head, ...)
  if head == nil then
    self._value = value
    return
  end

  if not self._items[head] then
    self._items[head] = composite_map.new(self._weakness)
  end

  self = self._items[head]
  methods.set(self, value, ...)
end


--- @param head any
--- @param ... any
--- @return any
methods.get = function(self, head, ...)
  if head == nil then
    return self._value
  end

  if not self._items[head] then
    return nil
  end

  self = self._items[head]
  return methods.get(self, ...)
end

local iter

--- NOTICE returned keys should not be mutated
methods.iter = function(self)
  return coroutine.wrap(function() iter(self, {}) end)
end

iter = function(self, base)
  if self._value then
    coroutine.yield(base, self._value)
  end
  for k, v in pairs(self._items) do
    table.insert(base, k)
    iter(v, base)
    table.remove(base)
  end
end

return composite_map
