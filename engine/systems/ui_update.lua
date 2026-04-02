local ui = require("engine.tech.ui")

return Tiny.system {
  codename = "ui_update",
  base_callback = "update",
  update = function(self, dt)
    ui.handle_update(dt)
  end,
}
