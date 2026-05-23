local systems = {
  -- love.update
  "genesis",
  "update_sound",
  "update_runner",
  "acting",
  "animation",
  "drifting",
  "timed_death",
  "running",

  -- love.draw
  "drawing",
}

return Fun.iter(systems)
  :map(function(name)
    return assert(love.filesystem.load("engine/systems/" .. name .. ".lua"))()
  end)
  :totable()
