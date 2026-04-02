local ui = require("engine.tech.ui")


local ending = {}

--- @class state_mode_ending
--- @field is_good boolean
local methods = {}
ending.mt = {__index = methods}

methods.draw_gui = function(self)
  local w, h = love.graphics.getDimensions()

  ui.start_frame(nil, h / 2)
  ui.start_alignment("center")
    ui.start_font(88)
      ui.text("Конец")
    ui.finish_font()

    ui.start_font(24)
      ui.text(self.is_good and "(2/2)" or "(1/2)")
    ui.finish_font()

    ui.br()
    ui.br()
    ui.br()

    ui.start_font(36)
      if ui.choice({"Продолжить"}) then
        State.mode:to_start_screen()
      end
    ui.finish_font()
  ui.finish_alignment()
  ui.finish_frame()
end

--- @return state_mode_ending
ending.new = function(is_good)
  return setmetatable({
    type = "ending",
    is_good = is_good,
  }, ending.mt)
end

Ldump.mark(ending, {mt = "const"}, ...)
return ending
