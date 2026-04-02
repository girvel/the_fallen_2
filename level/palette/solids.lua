local abilities = require("engine.mech.abilities")
local humanoid = require("engine.mech.humanoid")
local creature = require("engine.mech.creature")
local player_base = require("engine.state.player.base")


local solids = {}

solids.player = function()
  local result = Table.extend(player_base.mixin(), humanoid.mixin(), {
    name = "Протагонист",
    base_abilities = abilities.new(8, 8, 8, 8, 8, 8),
    level = 0,
    perks = {},
    faction = "player",
  })

  creature.init(result)
  return result
end

Ldump.mark(solids, {}, ...)
return solids
