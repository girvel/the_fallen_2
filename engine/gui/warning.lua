local ui = require("engine.tech.ui")
local tk = require("engine.gui.tk")


local warning = {}

--- @class gui_warning
--- @field type "warning"
--- @field message string
--- @field _prev table
local methods = {}
warning.mt = {__index = methods}

--- @return gui_warning
warning.new = function(prev, message)
  ui.reset_selection()
  return setmetatable({
    type = "warning",
    message = message,
    _prev = prev,
  }, warning.mt)
end

tk.delegate(methods, "draw_entity", "preprocess", "postprocess")

local h = 100

methods.draw_gui = function(self)
  tk.start_window("center", "center", 550, h + 2 * tk.WINDOW_PADDING)
  ui.start_font(28)
  ui.start_alignment("center")
    ui.text(self.message)
    ui.br()

    local n = ui.choice({"OK"})

    if n == 1 or ui.keyboard("escape") then
      Kernel.gui:close_menu()
    end

    h = ui.get_height()
  ui.finish_alignment()
  ui.finish_font()
  tk.finish_window()
end

Ldump.mark(warning, {mt = "const"}, ...)
return warning
