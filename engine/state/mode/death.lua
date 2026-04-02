local ui = require("engine.tech.ui")
local tk = require("engine.state.mode.tk")


local death = {}

--- @class state_mode_death
--- @field type "death"
local methods = {}
local mt = {__index = methods}

local SCALE = Constants.cell_size

methods.draw_gui = function(self)
  local w, h = love.graphics.getDimensions()
  local sprite_w = State.player.sprite.image:getWidth() * SCALE
  local sprite_h = State.player.sprite.image:getHeight() * SCALE
  local x = (w - sprite_w) / 2
  local y = (h - sprite_h) / 2 - 200
  tk.draw_entity(State.player, x, y, SCALE)

  ui.start_frame(nil, h / 2)
  ui.start_alignment("center")
    ui.start_font(88)
      ui.text("GAME OVER")
    ui.finish_font()
    ui.start_font(36)
      if ui.choice({"Продолжить"}) then
        State.mode:to_start_screen()
      end
    ui.finish_font()
  ui.finish_alignment()
  ui.finish_frame()
end

--- @return state_mode_death
death.new = function()
  return setmetatable({
    type = "death",
  }, mt)
end

Ldump.mark(death, {}, ...)
return death
