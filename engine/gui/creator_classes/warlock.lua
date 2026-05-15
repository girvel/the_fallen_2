local spells = require("engine.mech.spells")
local class = require("engine.mech.class")
local ui = require("engine.tech.ui")
local gui_elements = require("engine.gui.gui_elements")
local warlock_class = require("engine.mech.class.warlock")


local warlock = {}

--- @param data creator_pane
warlock.init_data = function(data)
  
end

--- @param creator gui_creator
--- @param dt number
--- @param data creator_pane
warlock.draw_pane = function(creator, dt, data)
  if data.class_level == 1 then
    creator:start_ability(gui_elements.eldritch_blast)
      ui.text("Заклинание: Мистический взрыв")
    creator:finish_ability("Дистанционная атака, 1d10 урона")
  end
end

--- @param creator gui_creator
--- @param data creator_pane
warlock.submit = function(creator, data)
  local result = {}
  if data.class_level == 1 then
    table.insert(result, class.spell(spells.eldritch_blast, "cha"))
    table.insert(result, warlock_class.dark_ones_blessing)
  end
  return result
end

Ldump.mark(warlock, {}, ...)
return warlock
