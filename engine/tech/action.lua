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

--- @class action_params
--- @field entity_targets entity[] guaranteed # >= 1
--- @field direction vector

--- @alias filter_f fun(self: action, entity: entity, target: entity): any

--- @class action_params_def
--- @field entity_targets? {filter: filter_f, max_n: integer}
--- @field direction? true

--- @alias action table|action_strict
--- @class action_strict
--- @field codename? string
--- @field name? string
--- @field upcast_from? action
--- @field cost? table<string, number>
--- @field parameters? action_params_def
--- @field get_hint? fun(self: action, entity: entity): string
local action_methods = {
  --- @param entity entity
  is_available = function(self, entity) end,

  --- @param entity entity
  --- @param parameter? action_params
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

--- @alias action_prototype action_prototype_strict|table
--- @class action_prototype_strict: action_strict
--- @field _act? fun(self: action, entity: entity, params: action_params): boolean
--- @field _is_available? fun(self: action, entity: entity): any

--- @param prototype action_prototype
--- @return action
action.plain = function(prototype)
  if not prototype.act then
    prototype.act = action.make_act(prototype._act)
  end

  if not prototype.is_available then
    prototype.is_available = action.make_is_available(prototype._is_available)
  end

  return prototype
end

--- @alias spell_prototype spell_prototype_strict|table
--- @class spell_prototype_strict: action_prototype_strict
--- @field _codename? string
--- @field _name? string
--- @field _cost? table<string, number>

--- @alias action_factory fun(mod?: ability, upcast_level?: integer): action
--- @alias prototype_factory fun(mod?: ability, cast_level: integer): spell_prototype

--- @param base_level integer
--- @param prototype_factory prototype_factory
--- @return action_factory
action.leveled_spell = function(base_level, prototype_factory)
  return Memoize(function(mod, cast_level)
    if not cast_level then
      cast_level = base_level
    elseif cast_level < base_level then
      Error("Upcast %s is lower than the base level %s", cast_level, base_level)
    end

    local t = prototype_factory(mod, cast_level)
    action.plain(t)

    if not t.name and t._name then
      if cast_level == base_level then
        t.name = t._name
      else
        t.name = ("%s (ур. %s)"):format(t._name, cast_level)
      end
    end

    if not t.codename and t._codename then
      t.codename = t._codename.."_"..cast_level
    end

    if not t.cost and t._cost then
      t.cost = t._cost
      t.cost["spell_slots_"..cast_level] = 1
    end

    return t
  end)
end

Ldump.mark(action, "const", ...)
return action
