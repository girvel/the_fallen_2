local ui = require("engine.tech.ui")

return Tiny.system {
  codename = "ui_mousemoved",
  base_callback = "mousemoved",
  update = function(self, x, y)
    ui.handle_mousemove(x, y)
  end,
}
