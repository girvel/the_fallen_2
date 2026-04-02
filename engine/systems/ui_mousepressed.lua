local ui = require("engine.tech.ui")

return Tiny.system {
  codename = "ui_mousepressed",
  base_callback = "mousepressed",
  update = function(self, x, y, button)
    ui.handle_mousepress(button)
  end,
}
