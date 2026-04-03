local sound = require("engine.tech.sound")
local async = require("engine.tech.async")
local interactive = require("engine.tech.interactive")
local factoring = require("engine.tech.factoring")
local abilities = require("engine.mech.abilities")
local humanoid = require("engine.mech.humanoid")
local player_base = require("engine.state.player.base")


local solids = {}

----------------------------------------------------------------------------------------------------
-- [SECTION] Atlas
----------------------------------------------------------------------------------------------------

local containers = "cab1 cab2 shelf1 shelf2 chest bin"

local opening_sounds = {
  cabinet = sound.multiple("assets/sounds/cabinet/open", .8),
  shelf   = sound.multiple("assets/sounds/cabinet/open", .8),
  chest   = sound.multiple("assets/sounds/chest/open",   .8),
}

--- @param prefix string
--- @param type "container"
local get_open = Memoize(function(prefix, type)
  local sounds = opening_sounds[prefix]
  local factory, layer
  if type == "container" then
    factory = solids[prefix .. "o"]
    layer = "solids"
  else
    assert(false)
  end

  return function(self)
    local open_itself = function()
      State:remove(self)
      local e = factory()
      e.position = self.position
      e.grid_layer = layer
      State:add(e)
    end

    local _, scene = State.runner:run_task(function()
      if sounds then
        sounds:play_at(self.position)
      end
      async.sleep(.18)
      open_itself()
    end)
    scene.on_cancel = open_itself
  end
end)

factoring.use_atlas(solids, "assets/atlases/solids.png", {
  false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false,

  false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false,

  false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false,
  false, false, false, false, false, false, false, false,

  false, false, false, false, "cab1c", "cab1o", "shelf1c", "shelf1o",
  false, false, false, false, "cab2c", "cab2o", "shelf2c", "shelf2o",
}, function(codename)
  local e = {}
  e.boring_flag = true

  -- NEXT it's really inefficient
  for _, prefix in ipairs(containers:tokens()) do
    if codename == prefix .. "c" then
      interactive.mix_in(e, get_open(prefix, "container"))
      break
    end
  end

  return e
end)

----------------------------------------------------------------------------------------------------
-- [SECTION] Entities
----------------------------------------------------------------------------------------------------

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
