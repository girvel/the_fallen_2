local class = require("engine.mech.class")
local fighter_class = require("engine.mech.class.fighter")
local gui_elements = require("engine.gui.gui_elements")
local ui = require("engine.tech.ui")


local fighter = {}

local FIGHTING_STYLES = Fun.pairs(fighter_class.fighting_styles)
  :map(function(k, v) return v end)
  :totable()
table.sort(FIGHTING_STYLES, function(a, b) return Name.game(a) < Name.game(b) end)

-- There was a mutex issue
local _SAMURAI_SKILLS = {
  class.skill_proficiency("performance"),
  class.skill_proficiency("history"),
  class.skill_proficiency("insight"),
}

fighter.init_data = function(data)
  if data.class_level == 1 then
    data.fighting_style = FIGHTING_STYLES[1]
  end
end

--- @param creator gui_creator
fighter.draw_pane = function(creator, dt, data)
  if data.class_level == 1 then
    creator:start_ability(gui_elements.fighting_styles, true)
      ui.text("Боевой стиль:")
      creator:switch(FIGHTING_STYLES, "fighting_style")
    creator:finish_ability(data.fighting_style.description)
    -- NEXT description is shifted wrong

    creator:start_ability(gui_elements.second_wind)
      ui.text("Способность: Второе дыхание")
      local roll = fighter_class.second_wind:get_roll(#creator.model)
    creator:finish_ability(
      "Раз за бой бонусным действием восстанавливает %d-%d здоровья",
      roll:min(), roll:max()
    )
  elseif data.class_level == 2 then
    creator:start_ability(gui_elements.action_surge)
      ui.text("Способность: Всплеск действий")
    creator:finish_ability("Раз за бой даёт одно дополнительное действие")
  elseif data.class_level == 3 then
    creator:start_ability(gui_elements.fighting_spirit)
      ui.text("Способность: Боевой дух")
    creator:finish_ability(
      "Три раза за игру бонусным действием даёт 5 ед. временного здоровья; атаки в этот ход " ..
      "попадают чаще."
    )
  end
end

--- @param creator gui_creator
--- @param datas creator_pane[]
--- @param perks table[]
fighter.submit = function(creator, datas, perks)
  for _, data in ipairs(datas) do
    if data.class_level == 1 then
      table.insert(perks, data.fighting_style)
      table.insert(perks, fighter_class.second_wind)
    elseif data.class_level == 2 then
      table.insert(perks, fighter_class.action_surge)
    elseif data.class_level == 3 then
      table.insert(perks, fighter_class.fighting_spirit)
    end
  end
end

Ldump.mark(fighter, {}, ...)
return fighter
