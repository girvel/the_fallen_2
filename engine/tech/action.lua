local safety = require "engine.tech.safety"


local action = {
  default = {}
}

--- @deprecated
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

--- @deprecated
action.mix_in = function(t)
  Table.defaults(t, action.base)
end

--- @alias action table|action_strict
--- @class action_strict
--- @field codename? string
--- @field upcast_from? action
--- @field cost? table<string, number>
--- @field parameters? {entity_target: fun(self: action, entity: entity, target: entity): any}
local action_methods = {
  --- @param entity entity
  is_available = function(self, entity) end,

  --- @param entity entity
  --- @param parameter any
  act = function(self, entity, parameter) end,
}

action.enough_resources = function(this_action, entity)
  return not this_action.cost
    or Fun.iter(this_action.cost):all(function(k, v) return (entity.resources[k] or 0) >= v end)
end

--- @alias act_function fun(self: action, entity: entity, parameter: any): boolean
--- @alias is_available_function fun(self: action, entity: entity): boolean

--- @param f? act_function
--- @return act_function
action.make_act = function(f)
  return function(self, entity, parameter)
    if entity.modify and not entity:modify("activation", true, self.codename) then return false end
    if not safety.call(self.is_available, self, entity) then return false end
    if f then
      local result = safety.call(f, self, entity, parameter)
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
  end
end

--- @param f? is_available_function
--- @return is_available_function
action.make_is_available = function(f)
  return function(self, entity)
    if not action.enough_resources(self, entity) then
      return false
    end

    if f and not f(self, entity) then
      return false
    end

    return true
  end
end

Ldump.mark(action, "const", ...)
return action
