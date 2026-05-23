local gui_elements = require("engine.gui.gui_elements")
local warlock = require("engine.mech.class.warlock")
local class = require("engine.mech.class")
local races = require("engine.mech.races")
local feats = require("engine.mech.class.feats")
local fighter = require("engine.mech.class.fighter")
local xp = require("engine.mech.xp")
local translation = require("engine.tech.translation")
local abilities = require("engine.mech.abilities")
local colors = require("engine.tech.colors")
local tk = require("engine.gui.tk")
local ui = require("engine.tech.ui")


local creator = {}

--- @class creator_base_pane
--- @field base_abilities abilities
--- @field points integer
--- @field race table
--- @field skill_1 table
--- @field skill_2 table
--- @field bonus_plus1_1 name_pair
--- @field bonus_plus1_2 name_pair
--- @field bonus_plus2 name_pair
--- @field feat table

--- @alias creator_pane creator_pane_strict|table
--- @class creator_pane_strict
--- @field class table
--- @field class_level integer
--- @field total_level integer

--- @alias creator_model {[0]: creator_base_pane, [1]: creator_pane, [2]: creator_pane, [3]: creator_pane, [4]: creator_pane, [5]: creator_pane, [6]: creator_pane, [7]: creator_pane, [8]: creator_pane, [9]: creator_pane}

--- @class gui_creator
--- @field type "creator"
--- @field _prev gui_game
--- @field model creator_model
--- @field pane_i integer
--- @field is_disabled boolean
local methods = {}
creator.mt = {__index = methods}

local ABILITIES = Fun.iter(abilities.list)
  :map(function(codename) return {
    codename = codename,
    name = assert(translation.abilities[codename]):utf_capitalize()
  } end)
  :totable()

local SKILLS = Fun.iter(abilities.skill_bases)
  :map(function(skill) return class.skill_proficiency(skill) end)
  :totable()
table.sort(SKILLS, function(a, b) return a.name < b.name end)

local FEATS = Fun.pairs(feats)
  :map(function(k, v) return v end)
  :totable()
table.sort(FEATS, function(a, b) return a.name < b.name end)

local RACES = {
  races.human,
  races.variant_human,
  races.custom_lineage,
}

local CLASSES = {
  fighter,
  warlock,
}

local CREATOR_CLASSES = Table.do_folder("engine/gui/creator_classes")

local draw_base_pane, draw_pane, submit, reassign_model

--- @param prev gui_game
--- @return gui_creator
creator.new = function(prev)
  local current_level = State.player.level

  local total_level, pane_i do
    total_level = current_level
    local xp_remains = State.player.xp
    while true do
      local delta = xp.to_reach(total_level + 1)
      if xp_remains < delta then break end

      xp_remains = xp_remains - delta
      total_level = total_level + 1
    end

    if current_level == 0 then
      pane_i = 0
    elseif total_level > current_level then
      pane_i = current_level + 1
    else
      pane_i = total_level
    end
  end

  local model do
    model = State.player.creator_model
    if not model then
      model = {
        [0] = {
          base_abilities = Kernel.debug
            and abilities.new(15, 15, 15, 8, 8, 8)
            or abilities.new(8, 8, 8, 8, 8, 8),
          points = Kernel.debug and 0 or 27,
          race = RACES[1],
          skill_1 = SKILLS[1],
          skill_2 = SKILLS[2],
          bonus_plus1_1 = ABILITIES[1],
          bonus_plus1_2 = ABILITIES[2],
          bonus_plus2 = ABILITIES[1],
          feat = FEATS[1],
        },
      }
    end

    reassign_model(model, model[#model].class or CLASSES[1], current_level + 1, total_level)
  end

  return setmetatable({
    type = "creator",
    _prev = prev,
    model = model,
    pane_i = pane_i,
    is_disabled = #model <= State.player.level or not State.player:is_free(),
  }, creator.mt)
end

tk.delegate(methods, "draw_entity", "preprocess", "postprocess")

methods.draw_gui = function(self, dt)
  if ui.keyboard("escape") or ui.keyboard("n") then
    Kernel.gui:close_menu()
  end

  if ui.keyboard("j") then
    Kernel.gui:close_menu()
    Kernel.gui:open_menu("journal")
  end

  if not self.is_disabled and ui.keyboard("return") then
    if self.model[0].points > 0 then
      Kernel.gui:show_warning(
        "Редактирование персонажа не закончено: не все очки способностей израсходованы"
      )
    else
      Kernel.gui:confirm(
        "Закончить создание персонажа?",
        function() submit(self) end
      )
    end
  end

  tk.start_window("center", "center", 780, 700)
    ui.h1("Персонаж")
    ui.start_font(24)
      ui.start_line()
        if ui.selector() then
          if ui.keyboard("left") then
            self.pane_i = (self.pane_i - 1) % (#self.model + 1)
          end

          if ui.keyboard("right") then
            self.pane_i = (self.pane_i + 1) % (#self.model + 1)
          end
        end

        ui.text("Уровень: ")
        for i = 0, #self.model do
          if i > 0 then
            ui.text(">")
          end
          if i == self.pane_i then
            ui.text(" [%s] ", i)
          else
            if i > State.player.level then ui.start_styles({link_color = colors.golden}) end
            if ui.text_button(" [%s] ", i).is_clicked then
              self.pane_i = i
            end
            if i > State.player.level then ui.finish_styles() end
          end
        end
      ui.finish_line()
      ui.br()

      if self.pane_i == 0 then
        draw_base_pane(self, dt)
      else
        draw_pane(self, dt)
      end
    ui.finish_font()
  tk.finish_window()
end

--- @param self gui_creator
--- @param dt number
draw_base_pane = function(self, dt)
  local data = self.model[0]
  local column1_length = Fun.iter(ABILITIES)
    :map(function(ab) return ab.name:utf_len() end)
    :max()

  local column2_length = 16

  local header = ("%s   %s МОДИФИКАТОР"):format(
    ("ХАР-КА"):ljust(column1_length, " "),
    ("ЗНАЧЕНИЕ"):ljust(column2_length, " ")
  )

  ui.text("  " .. header)
  ui.text("  " .. "-" * header:utf_len())

  for _, ability in ipairs(ABILITIES) do
    ui.start_line()
      local codename = ability.codename
      local name = ability.name

      local raw_score = data.base_abilities[codename]
      local bonus = self:get_bonus(codename)
      local score = raw_score + bonus
      local modifier = abilities.get_modifier(score)

      local is_selected = self:selector()
      ui.text("%s ", name:ljust(column1_length))

      local left_button
      if not self.is_disabled and raw_score > 8 then
        left_button = ui.text_button(" < ").is_clicked
          or is_selected and ui.keyboard("left")
      else
        ui.text("   ")
        left_button = false
      end

      ui.text("%02d", raw_score)

      local right_button
      if not self.is_disabled
        and raw_score < 15
        and xp.point_buy[raw_score + 1] - xp.point_buy[raw_score] <= data.points
      then
        right_button = ui.text_button(" > ").is_clicked
          or is_selected and ui.keyboard("right")
      else
        ui.text("   ")
        right_button = false
      end

      ui.text("+ %d = %02d  (%+d)", bonus, score, modifier)

      if left_button then
        data.points = data.points + (
          xp.point_buy[raw_score] - xp.point_buy[raw_score - 1]
        )
        data.base_abilities[codename] = raw_score - 1
      elseif right_button then
        data.points = data.points - (
          xp.point_buy[raw_score + 1] - xp.point_buy[raw_score]
        )
        data.base_abilities[codename] = raw_score + 1
      end
    ui.finish_line()
  end

  ui.start_line()
    ui.text("  %s    ", ("Очки:"):ljust(column1_length))
    if data.points > 0 then
      ui.start_color(colors.red)
    end
    ui.text("%02d", data.points)
    if data.points > 0 then
      ui.finish_color()
    end
  ui.finish_line()

  ui.br()

  ui.start_line()
  ui.start_font(30)
    self:selector()
    ui.start_color(colors.white_dim)
      ui.text("## ")
    ui.finish_color()
    ui.text("Раса: ")
    self:switch(RACES, "race")
  ui.finish_font()
  ui.finish_line()
  ui.br()

  ui.start_line()
    self:selector()
    ui.text("Навык: ")
    ui.switch(SKILLS, data, "skill_1", self.is_disabled, data.skill_2)
  ui.finish_line()

  ui.start_line()
    self:selector()
    ui.text("Навык: ")
    ui.switch(SKILLS, data, "skill_2", self.is_disabled, data.skill_1)
  ui.finish_line()

  if data.race == races.human then
    ui.text("  +1 ко всем характеристикам")
  else
    if data.race == races.custom_lineage then
      ui.start_line()
        self:selector()
        ui.text("+2: ")
        ui.switch(ABILITIES, data, "bonus_plus2", self.is_disabled)
      ui.finish_line()
    else
      ui.start_line()
        self:selector()
        ui.text("+1: ")
        ui.switch(ABILITIES, data, "bonus_plus1_1", self.is_disabled, data.bonus_plus1_2)
      ui.finish_line()

      ui.start_line()
        self:selector()
        ui.text("+1: ")
        ui.switch(ABILITIES, data, "bonus_plus1_2", self.is_disabled, data.bonus_plus1_1)
      ui.finish_line()
    end

    ui.br()
    ui.start_line()
      self:selector()
      ui.text("Черта: ")
      ui.switch(FEATS, data, "feat", self.is_disabled)
    ui.finish_line()

    local description = data.feat.description
    if description then
      ui.start_frame(ui.get_context().font:getWidth("w") * 4)
        ui.text(description)
      ui.finish_frame()
    end
  end
end

--- @param self gui_creator
--- @param dt number
draw_pane = function(self, dt)
  local data = self.model[self.pane_i]

  ui.br()

  ui.start_line()
    self:selector()
    ui.start_font(36)
      ui.start_color(colors.white_dim)
        ui.text("## ")
      ui.finish_color()
      ui.text("Класс: ")
      if self:switch(CLASSES, "class") then
        reassign_model(self.model, data.class, self.pane_i, #self.model)
        data = self.model[self.pane_i]
      end
      ui.text("(уровень %s)", data.class_level)
    ui.finish_font()
  ui.finish_line()
  ui.br()

  local con_mod = self:get_modifier("con")
  local is_tough = self:has_feat(feats.tough)
  local tough_bonus = is_tough and 2 or 0

  local prev_hp = 0
  for i = 1, self.pane_i - 1 do
    local this_data = self.model[i]
    prev_hp = prev_hp + con_mod + tough_bonus + (
      i == 1
        and this_data.class.hit_die
        or math.floor(data.class.hit_die / 2) + 1
    )
  end

  local hp_bonus = data.total_level == 1
    and data.class.hit_die
    or (math.floor(data.class.hit_die / 2) + 1)

  ui.text(
    "  %d + %d %s %d (Телосложение)%s = %d здоровья",
    prev_hp,
    hp_bonus,
    con_mod >= 0 and "+" or "-",
    math.abs(con_mod),
    is_tough and " + 2 (Крепкий)" or "",
    prev_hp + hp_bonus + con_mod + tough_bonus
  )
  ui.br()

  CREATOR_CLASSES[data.class.codename].draw_pane(self, dt, data)
end

--- @param self gui_creator
submit = function(self)
  local perks do
    local data = self.model[0]
    perks = {
      data.skill_1,
      data.skill_2,
    }

    if data.race == races.human then
      table.insert(perks, races.human.ability_bonus)
    elseif data.race == races.custom_lineage then
      table.insert(perks, data.feat)
      table.insert(perks, races.custom_lineage:ability_bonus(data.bonus_plus2.codename))
    elseif data.race == races.variant_human then
      table.insert(perks, data.feat)
      table.insert(perks, races.variant_human:ability_bonus(
        data.bonus_plus1_1.codename, data.bonus_plus1_2.codename
      ))
    else
      assert(false)
    end
  end

  local class_datas = {}
  for i, data in ipairs(self.model) do
    if not class_datas[data.class] then
      class_datas[data.class] = {}
    end
    table.insert(class_datas[data.class], data)
    table.insert(perks, class.hit_dice(data.class.hit_die, i == 1))
  end

  for this_class, datas in pairs(class_datas) do
    CREATOR_CLASSES[this_class.codename].submit(self, datas, perks)
  end

  local mixin = {
    level = #self.model,
    xp = State.player.xp - xp.for_level[#self.model] + xp.for_level[State.player.level],
    perks = perks,
    creator_model = self.model,
    base_abilities = self.model[0].base_abilities,
  }
  Log.info("Submitting a character build: %s", mixin)
  Table.extend(State.player, mixin)
  State.player:rest("full")
  Kernel.gui:close_menu()
end

reassign_model = function(model, assigned_class, level_from, level_to)
  if level_from > level_to then return end

  local class_levels = {}
  for i = 1, level_to do
    local this_class, class_level
    if i >= level_from then
      this_class = assigned_class
      class_level = (class_levels[this_class] or 0) + 1

      model[i] = {
        class = this_class,
        class_level = class_level,
        total_level = i,
      }
      local creator_class = CREATOR_CLASSES[this_class.codename]
      if not creator_class then
        Error("No creator class %q", this_class.codename)
      end
      creator_class.init_data(model[i])
    else
      this_class = model[i].class
      class_level = model[i].class_level
    end

    class_levels[this_class] = class_level
  end
end

--- @param possible_values any[]
--- @param key any
--- @param group? string
--- @return boolean did_switch
methods.switch = function(self, possible_values, key, group)
  local container = self.model[self.pane_i]
  return ui.switch(possible_values, container, key, self.is_disabled)
end

methods.selector = function(self)
  if self.is_disabled then
    ui.text("  ")
    return false
  else
    return ui.selector()
  end
end

--- @param image? love.Image|string
--- @param selector? boolean
methods.start_ability = function(self, image, selector)
  ui.start_line()
  if selector then
    self:selector()
  else
    ui.text("  ")
  end
  ui.image(image or gui_elements.generic_perk, 2)
  ui.start_font(32)
  ui.text(" ")
end

methods.finish_ability = function(self, fmt, ...)
  ui.finish_font()
  ui.finish_line()

  ui.start_frame(32 + ui.get_context().font:getWidth("w") * 3)
    ui.text(fmt, ...)
  ui.finish_frame("push_cursor")
  ui.br()
end

--- @param ability ability
methods.get_bonus = function(self, ability)
  local data = self.model[0]

  local bonus
  if data.race == races.human then
    bonus = 1
  elseif data.race == races.variant_human then
    bonus = (data.bonus_plus1_1.codename == ability or data.bonus_plus1_2.codename == ability)
      and 1 or 0
  else
    bonus = data.bonus_plus2.codename == ability and 2 or 0
  end

  if self:has_feat(feats.durable) and ability == "con" then
    bonus = bonus + 1
  end
  return bonus
end

--- @param ability ability
methods.get_modifier = function(self, ability)
  return abilities.get_modifier(
    self.model[0].base_abilities[ability] + self:get_bonus(ability)
  )
end

methods.has_feat = function(self, feat)
  return self.model[0].race ~= races.human and self.model[0].feat == feat
end


Ldump.mark(creator, {mt = "const"}, ...)
return creator
