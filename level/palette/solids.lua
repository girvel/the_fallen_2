local abilities = require("engine.mech.abilities")
local humanoid = require("engine.mech.humanoid")
local player_base = require("engine.state.player.base")


local solids = {}

solids.player = function()
  local result = {
    name = "Протагонист",
    base_abilities = abilities.new(8, 8, 8, 8, 8, 8),
    level = 0,
    perks = {},
    faction = "player",
  }
  player_base.mix_in(result)
  humanoid.mix_in(result)
  return result
end

Ldump.mark(solids, {}, ...)
return solids
