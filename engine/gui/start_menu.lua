local ui = require("engine.tech.ui")
local tcod = require("engine.tech.tcod")


local start_menu = {}

--- @class gui_start_menu
--- @field type "start_menu"
local methods = {}
local mt = {__index = methods}

start_menu.new = function()
  return setmetatable({
    type = "start_menu",
  }, mt)
end

local display_tcod_error = not tcod.ok

methods.draw_gui = function()
  if display_tcod_error then
    display_tcod_error = false
    Kernel.gui:show_warning(
      "Невозможно загрузить библиотеку libtcod, поля зрения и поиск путей не будут работать." ..
      "\n\nВозможно, путь к папке с игрой содержит русские символы. Попробуйте " ..
      "переместить её в другое место."
    )
    return
  end

  ui.start_frame(0, 100)
  ui.start_font(72)
  ui.start_alignment("center")
    ui.text("The Fallen II")
  ui.finish_alignment()
  ui.finish_font()
  ui.finish_frame()

  ui.start_font(48)
  ui.start_frame(100, 300, 500, 500)
    local choice = ui.choice({
      "Новая игра",
      "Загрузить игру",
      "Выход",
    })

    if choice then
      ui.reset_selection()
    end

    if choice == 1 then
      Kernel.gui:start_game()
    elseif choice == 2 then
      Kernel.gui:open_menu("load_menu")
    elseif choice == 3 then
      Log.info("Exiting from the main menu")
      love.event.quit()
    end
  ui.finish_frame()
  ui.finish_font()
end

Ldump.mark(start_menu, {}, ...)
return start_menu
