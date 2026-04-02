local items = require("engine.mech.items")
local ui = require("engine.tech.ui")
local tk = require("engine.state.mode.tk")


local HAIR_TYPES = {
  {codename = "none", name = "Лысый"},
  {codename = "short_hair_1", name = "Короткие (1)"},
  {codename = "short_hair_2", name = "Короткие (2)"},
  {codename = "short_hair_3", name = "Короткие (3)"},
}

local HAIR_COLORS = {
  {codename = "red", name = "Рыжий"},
  {codename = "gray", name = "Седеющий"},
  {codename = "brown", name = "Русый"},
}

local SKIN = {
  {codename = "none", name = "Чистая"},
  {codename = "cheek_scar", name = "Шрам на щеке"},
  {codename = "eye_scar", name = "Шрам у глаза"},
  {codename = "snake_tatoo", name = "Татуировка змеи"},
}

local appearance_editor = {}

--- @class state_mode_appearance_editor
--- @field type "appearance_editor"
--- @field _prev state_mode_game
--- @field model table
local methods = {}
appearance_editor.mt = {__index = methods}

--- @return state_mode_appearance_editor
appearance_editor.new = function(prev)
  return setmetatable({
    type = "appearance_editor",
    _prev = prev,
    model = {
      name = "Протагонист",
      hair_type = HAIR_TYPES[1],
      hair_color = HAIR_COLORS[2],
      skin = SKIN[1],
    },
  }, appearance_editor.mt)
end

tk.delegate(methods, "draw_entity", "preprocess", "postprocess")

appearance_editor.w = 500
appearance_editor.padding = 20

methods.draw_gui = function(self, dt)
  if ui.keyboard("return") then
    State.mode:confirm(
      "Закончить редактирование внешности персонажа?",
      function() State.mode:close_menu() end
    )
  end

  if ui.keyboard("escape") then
    State.mode:open_menu("escape_menu")
  end

  local parent_w = love.graphics.getWidth()
  tk.start_window(
    parent_w - appearance_editor.w - appearance_editor.padding, "center",
    appearance_editor.w, 300
  )
    ui.h1("Внешность")
    ui.start_font(24)
      ui.start_line()
        ui.selector()
        ui.text("Имя:  ")
        ui.field(self.model, "name", 22)
      ui.finish_line()

      ui.start_line()
        ui.selector()
        ui.text("Тип волос:")
        local hair_type_changed = ui.switch(HAIR_TYPES, self.model, "hair_type")
      ui.finish_line()

      ui.start_line()
        ui.selector()
        ui.text("Цвет волос:")
        local hair_color_changed = ui.switch(HAIR_COLORS, self.model, "hair_color")
      ui.finish_line()

      ui.start_line()
        ui.selector()
        ui.text("Кожа:")
        local skin_changed = ui.switch(SKIN, self.model, "skin")
      ui.finish_line()
    ui.finish_font()
  tk.finish_window()

  local inventory = State.player.inventory
  if hair_type_changed or hair_color_changed then
    local hair_type = self.model.hair_type.codename
    local hair_color = self.model.hair_color.codename

    if inventory.hair then
      State:remove(inventory.hair, true)
    end

    inventory.hair = hair_type ~= "none"
      and State:add(items.hair(hair_type, hair_color))
      or nil

    State.player:rotate()
  end

  if skin_changed then
    local skin = self.model.skin.codename

    if inventory.skin then
      State:remove(inventory.skin, true)
    end

    inventory.skin = skin ~= "none"
      and State:add(items.skin(skin))
      or nil

    State.player:rotate()
  end

  for key, dir in pairs(Vector.wasd) do
    if ui.keyboard(key) then
      State.player:rotate(dir)
    end
  end
end

Ldump.mark(appearance_editor, {mt = "const"}, ...)
return appearance_editor
