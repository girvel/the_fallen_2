local ui = require("engine.tech.ui")
local tk = require("engine.gui.tk")


local confirmation = {}

--- @class gui_confirmation
--- @field type "confirmation"
--- @field message string
--- @field f fun()
--- @field _prev table
local methods = {}
confirmation.mt = {__index = methods}

--- @return gui_confirmation
confirmation.new = function(prev, message, f)
  return setmetatable({
    type = "confirmation",
    message = message,
    f = f,
    _prev = prev,
  }, confirmation.mt)
end

tk.delegate(methods, "draw_entity", "preprocess", "postprocess")

local h = 100

methods.draw_gui = function(self)
  tk.start_window("center", "center", 550, h + 2 * tk.WINDOW_PADDING)
  ui.start_font(28)
  ui.start_alignment("center")
    ui.text(self.message)
    ui.br()

    local n = ui.choice({"OK", "Отмена"})

    if n == 1 then
      Kernel.gui:close_menu()
      self.f()
    elseif n == 2 or ui.keyboard("escape") then
      Kernel.gui:close_menu()
    end

    h = ui.get_height()
  ui.finish_alignment()
  ui.finish_font()
  tk.finish_window()
end

Ldump.mark(confirmation, {mt = "const"}, ...)
return confirmation
