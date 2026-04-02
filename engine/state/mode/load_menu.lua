local tk = require("engine.state.mode.tk")
local ui = require("engine.tech.ui")


local load_menu = {}

--- @class state_mode_load_menu
--- @field type "load_menu"
--- @field _prev table
local methods = {}
local mt = {__index = methods}

--- @param prev table
--- @return state_mode_load_menu
load_menu.new = function(prev)
  return setmetatable({
    type = "load_menu",
    _prev = prev,
  }, mt)
end

tk.delegate(methods, "draw_entity", "preprocess", "postprocess")

methods.draw_gui = function(self, dt)
  tk.start_window("center", "center", "read_max", "max")
  ui.start_font(24)
    ui.h1("Загрузить игру")

    local save = tk.choose_save(false)
    local escape_pressed = ui.keyboard("escape")

    if save then
      Kernel:plan_load(save)
    end

    if save or escape_pressed then
      ui.reset_selection()
      State.mode:close_menu()
    end
  ui.finish_font()
  tk.finish_window()
end

Ldump.mark(load_menu, {}, ...)
return load_menu
