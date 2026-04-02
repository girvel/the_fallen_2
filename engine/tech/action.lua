local safety = require "engine.tech.safety"


local action = {}

--- @class action
--- @field cost? table<string, number>
--- @field _is_available? fun(self: action, entity: entity): boolean
--- @field _act? fun(self: action, entity: entity): boolean
action.base = {
  enough_resources = function(self, entity)
    return not self.cost
      or Fun.iter(self.cost):all(function(k, v) return (entity.resources[k] or 0) >= v end)
  end,

  is_available = function(self, entity)
    if not self:enough_resources(entity) then
      return false
    end

    if self._is_available and not self:_is_available(entity) then
      return false
    end

    return true
  end,

  act = function(self, entity)
    if entity.modify and not entity:modify("activation", true, self.codename) then return false end
    if not safety.call(self.is_available, self, entity) then return false end
    if self._act then
      local result = safety.call(self._act, self, entity)
      if not (result == true or result == false) then
        Error("action %s returned %s; actions must explicitly return true or false",
          Name.code(self), Inspect(result))
      end
      if not result then return false end
    end
    for k, v in pairs(self.cost or {}) do
      entity.resources[k] = entity.resources[k] - v
    end
    return true
  end,
}

Ldump.mark(action, "const", ...)
return action
