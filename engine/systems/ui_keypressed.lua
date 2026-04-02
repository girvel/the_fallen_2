local ui = require("engine.tech.ui")

return Tiny.system {
  codename = "ui_keypressed",
  base_callback = "keypressed",
  update = function(self, _, scancode)
    ui.handle_keypress(scancode)
  end,
}
