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
rails.new = function()
  return setmetatable({
    
  }, rails.mt)
end

--- @param checkpoint string
methods.init = function(self, checkpoint)
  if Kernel.debug then init_debug() end
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
  }
  State.player.level = 20
  State.player.base_abilities.cha = 20
end

Ldump.mark(rails, {mt = "const"}, ...)
return rails
