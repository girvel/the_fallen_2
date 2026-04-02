local ui = require("engine.tech.ui")


local ui_textinput = Tiny.system {}

ui_textinput.codename = "ui_textinput"
ui_textinput.base_callback = "textinput"

--- @param text string
ui_textinput.update = function(self, text)
  ui.handle_textinput(text)
end

return ui_textinput
