local animated = require("engine.tech.animated")
local action = require("engine.tech.action")


local animate_dead = {}

--- @class spells_animate_dead: action
--- @field target entity
local methods = {}
animate_dead.mt = {__index = methods}

--- @type spells_animate_dead|table
animate_dead.base = Table.extend({
  codename = "animate_dead",

  cost = {
    actions = 1,
    spell_slots_3 = 1,
  },
}, action.base)

--- @param target entity
--- @return spells_animate_dead
animate_dead.new = function(target)
  return setmetatable(Table.extend({
    target = target
  }, animate_dead.base), animate_dead.mt)
end

methods._is_available = function(self, entity)
  if not (State:exists(self.target) and self.target.body_flag) then return false end
  return true
end

methods._act = function(self, entity)
  -- TODO remove reference to game code by extracting commonly used monsters & items
  local npcs = require("level.palette.npcs")
  local position = State.grids.solids:find_free_position(self.target.position)
  if not position then return false end

  State:remove(self.target)
  entity:animate("gesture")
  local fx = animated.add_fx("engine/assets/sprites/animations/skeleton_raise", position, "solids")
  fx.on_remove = function()
    State:add(npcs.skeleton_heavy(), {
      position = position,
      grid_layer = "solids",
      faction = entity.faction
    })
  end
  return true
end

Ldump.mark(animate_dead, {mt = "const"}, ...)
return animate_dead
