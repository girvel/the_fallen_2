local safety = require "engine.tech.safety"


local systems = {
  -- love.keypressed
  {codename = "ui_keypressed"},
  {codename = "debug_exit"},

  -- love.textinput
  {codename = "ui_textinput"},

  -- love.mousemoved
  {codename = "ui_mousemoved"},

  -- love.mousepressed
  {codename = "ui_mousepressed"},

  -- love.mousereleased
  {codename = "ui_mousereleased"},

  -- love.update
  {codename = "genesis"},
  {codename = "update_sound", live = true},
  {codename = "update_runner", live = true},  -- together with acting
  {codename = "acting", live = true},
  {codename = "animation", live = true},
  {codename = "ui_update"},
  {codename = "drifting", live = true},
  {codename = "timed_death", live = true},
  {codename = "running", live = true},

  -- love.draw
  {codename = "drawing"},
}

return Fun.iter(systems)
  :map(function(e)
    local system = assert(love.filesystem.load("engine/systems/" .. e.codename .. ".lua"))()
    if e.live then
      system = safety.live_system(system)
    end
    return safety.for_system(system)
  end)
  :totable()
