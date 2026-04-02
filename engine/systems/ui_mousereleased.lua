local ui = require("engine.tech.ui")

return Tiny.system {
  codename = "ui_mousereleased",
  base_callback = "mousereleased",
  update = function(self, x, y, button)
    ui.handle_mouserelease(button)
  end,
}
