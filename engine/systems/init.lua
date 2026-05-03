local safety = require "engine.tech.safety"


-- NEXT move systems out
-- NEXT no live systems
local systems = {
  -- love.update
  {codename = "genesis"},  -- non-kernel, but State:new flushes ECS manually
  {codename = "update_sound", live = true},
  {codename = "update_runner", live = true},  -- together with acting
  {codename = "acting", live = true},
  {codename = "animation", live = true},
  {codename = "drifting", live = true},
  {codename = "timed_death", live = true},
  {codename = "running", live = true},

  -- love.draw
  {codename = "drawing"},  -- partially kernel
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
