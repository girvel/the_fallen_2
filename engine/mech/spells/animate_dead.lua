local monsters = require("engine.mech.monsters")
local animated = require("engine.tech.animated")
local action = require("engine.tech.action")


local animate_dead = {
  codename = "animate_dead",

  cost = {
    actions = 1,
    -- NEXT uncomment
    -- spell_slots_3 = 1,
  },

  is_available = action.make_is_available(),

  parameter_type = "entity_target",
  target_filter = function(self, entity, target)
    return State:exists(target) and target.body_flag
  end,

  act = action.make_act(function(self, entity, target)
    -- TODO remove reference to game code by extracting commonly used monsters & items
    local position = State.grids.solids:find_free_position(target.position)
    if not position then return false end

    State:remove(target)
    entity:animate("gesture")
    local fx = animated.add_fx("engine/assets/animations/skeleton_raise", position, "solids")
    fx.on_remove = function()
      local e = State:add_at(monsters.skeleton_heavy(), position, "solids")
      e.faction = entity.faction
    end
    return true
  end),
}

Ldump.mark(animate_dead, "const", ...)
return animate_dead
