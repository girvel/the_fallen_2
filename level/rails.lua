local async = require("engine.tech.async")
local api = require("engine.tech.api")
local cutscene = require("engine.tech.cutscene")
local spells = require("engine.mech.spells")
local class = require("engine.mech.class")
local items = require("level.palette.items")
local item = require("engine.tech.item")


local rails = {}

--- @class rails
local methods = {}
rails.mt = {__index = methods}

local init_debug

--- @return rails
rails.new = function(checkpoint)
  -- TODO replace
  -- if Kernel.debug then init_debug() end
  init_debug()
  return setmetatable({}, rails.mt)
end

--- @param checkpoint string
methods.init = function(self, checkpoint)
end

init_debug = function()
  item.give(State.player, State:add(items.short_bow()))
  State.player.hp = 100
  State.player.max_hp = 100
  State.player.resources.spell_slots_1 = 4
  State.player.resources.spell_slots_2 = 4
  State.player.resources.spell_slots_3 = 4
  State.player.resources.spell_slots_4 = 4
  State.player.perks = {
    class.spell(spells.eldritch_blast),
    class.spell(spells.animate_dead),
    class.spell(spells.healing_word, "wis"),
    class.spell(spells.spray_of_cards, "cha"),
    class.spell(spells.hold_person, "cha"),
  }
  State.player.level = 20
  State.player.base_abilities.cha = 20

  State.runner:extend {
    intro = cutscene.make {
      enabled = true,
      screenplay = "assets/screenplay/intro.ms",
      characters = {
        player = {},
      },

      _run = function(self, ch, ps, sp)
        api.fade_out(0):wait()
        local fade_in = api.fade_in(1)
        State.player:rotate(Vector.up)
        State.player:animate("lying", false, true)
        sp:lines()
        fade_in:wait()
        State.player:animate()
        local look_around = State.runner:run_task(function()
          async.sleep(.5)
          State.player:rotate(Vector.right)
          async.sleep(.8)
          State.player:rotate(Vector.left)
        end)

        sp:lines()
        look_around:wait()

        sp:start_single_branch()
          if State.player:saving_throw("wis", 13) then
            sp:lines()
          end
        sp:finish_single_branch()

        sp:lines()
      end,
    },
  }
end

Ldump.mark(rails, {mt = "const"}, ...)
return rails
