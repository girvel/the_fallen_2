local level = require "engine.tech.level"
local interactive = {}

--- @class _interactive_methods
local methods = {}

--- @param interactor entity
--- @return entity?
interactive.get_for = function(interactor)
  for _, x in ipairs {
    State.grids.items[interactor.position] or false,
    State.grids.tiles[interactor.position] or false,
    State.grids.solids:slow_get(interactor.position + interactor.direction) or false,
    State.grids.on_solids:slow_get(interactor.position + interactor.direction) or false,
  } do
    if x and x.interact then
      return x
    end
  end
end

--- @param position vector
--- @return entity?
interactive.get_at = function(position)
  for _, layer in ipairs(level.grid_layers) do
    local e = State.grids[layer]:slow_get(position)
    if e and e.interact then
      return e
    end
  end
end

--- @param callback? fun(entity, entity)
interactive.mixin = function(callback)
  return Table.extend({
    on_interact = callback,
  }, methods)
end

--- @param self entity
--- @param other entity
methods.interact = function(self, other)
  local item = require("engine.tech.item")
  Log.debug("%s interacts with %s", Name.code(other), Name.code(self))

  local _, scene = State.runner:run_task(function()
    self.was_interacted_by = other
    coroutine.yield()
    self.was_interacted_by = nil
  end, "set_interacted_by")

  scene.on_cancel = function()
    self.was_interacted_by = nil
  end

  item.set_cue(self, "highlight", false)
  if self.on_interact then
    self:on_interact(other)
  end
end

Ldump.mark(interactive, {
  mixin = {methods = "const"},
}, ...)
return interactive
