local tk = require("engine.state.mode.tk")
local ui = require("engine.tech.ui")


local escape_menu = {}

--- @class state_mode_escape_menu
--- @field type "escape_menu"
--- @field has_saved boolean
--- @field _prev state_mode_game
local methods = {}
local mt = {__index = methods}

--- @param prev state_mode_game
--- @return state_mode_escape_menu
escape_menu.new = function(prev)
  return setmetatable({
    type = "escape_menu",
    has_saved = false,
    _prev = prev,
  }, mt)
end

tk.delegate(methods, "draw_entity", "preprocess", "postprocess")

methods.draw_gui = function(self, dt)
  local W = 400
  local H = 220

  tk.start_window("center", "center", W, H)
  ui.start_font(36)
    local n = ui.choice({
      "Продолжить",
      "Сохранить игру",
      "Загрузить игру",
      "Выход",
    })

    local escape_pressed = ui.keyboard("escape")

    if n == 1 or escape_pressed then
      State.mode:close_menu()
    elseif n == 2 then
      State.mode:open_menu("save_menu")
    elseif n == 3 then
      State.mode:open_menu("load_menu")
    elseif n == 4 then
      State.mode:attempt_exit()
    end
  ui.finish_font()
  tk.finish_window()
end

Ldump.mark(escape_menu, {}, ...)
return escape_menu
