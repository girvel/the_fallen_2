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

    creator:start_ability(gui_elements.dark_ones_blessing)
      ui.text("Способность: Благословение Тёмного")
    creator:finish_ability("Временное здоровье при убийстве")
  end
end

--- @param creator gui_creator
--- @param datas creator_pane[]
--- @param perks table[]
warlock.submit = function(creator, datas, perks)
  for _, data in ipairs(datas) do
    if data.class_level == 1 then
      table.insert(perks, class.spell(spells.eldritch_blast, "cha"))
    end
  end
  local class_level = #datas
  table.insert(perks, warlock_class.spell_slots(class_level))
  table.insert(perks, warlock_class.dark_ones_blessing(class_level))
end

Ldump.mark(warlock, {}, ...)
return warlock
