local animated = require("engine.tech.animated")
local async = require("engine.tech.async")
local ui = require("engine.tech.ui")


local loading_screen = {}

--- @class state_mode_loading_screen
--- @field type "loading_screen"
--- @field _loading_coroutine thread
--- @field _next_state fun()
local methods = {}
local mt = {__index = methods}

--- @param loading_coroutine thread
--- @param next_state fun()
loading_screen.new = function(loading_coroutine, next_state)
  return setmetatable({
    type = "loading_screen",
    _loading_coroutine = loading_coroutine,
    _next_state = next_state,
  }, mt)
end

local STAGES = {
  json = {start = 0, finish = .4},
  preload = {start = .4, finish = .5},
  generate = {start = .5, finish = .8},
  add = {start = .8, finish = .95},
  rails_init = {start = .95, finish = 1},
}

local bar_animation = animated.mixin("engine/assets/sprites/gui/loading_bar", "no_atlas").animation.pack.second

methods.draw_gui = function(self)
  local frame do
    local stage_id, value = async.resume(self._loading_coroutine)
    if stage_id then
      local stage = STAGES[stage_id]
      value = stage.start + (stage.finish - stage.start) * value
    else
      value = 1
    end
    frame = Math.median(1, math.ceil(value * #bar_animation), #bar_animation)
  end

  local bar_y = love.graphics.getHeight() * 4 / 5

  ui.start_alignment("center")
    ui.start_frame(nil, bar_y - 8)
      ui.image("engine/assets/sprites/gui/loading_bar_bg.png")
    ui.finish_frame()
    ui.start_frame(nil, bar_y)
      ui.image(bar_animation[frame].image)
    ui.finish_frame()
  ui.finish_alignment()

  if coroutine.status(self._loading_coroutine) == "dead" then
    self._next_state()
  end
end

Ldump.mark(loading_screen, {}, ...)
return loading_screen
