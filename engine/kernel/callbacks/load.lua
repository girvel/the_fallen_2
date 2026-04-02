local state = require("engine.state")
local safety = require "engine.tech.safety"
local cli = require "engine.kernel.cli"
local async = require "engine.tech.async"


return function(args)
  Log.info("Started love.load")

  args = cli.parse(args)
  Log.info("CLI args: %s", args)

  if args.profiler then
    Profile.start()
    async.lag_threshold = 1
  end

  if args.mobdebug then
    local ok, mobdebug = pcall(require, "mobdebug")
    assert(
      ok,
      "-debug option provided, but mobdebug is not found. Are you running this from ZeroBrane?"
    )

    mobdebug.start()
    async.lag_threshold = 2
  end

  if args.debug then
    Kernel:set_key_rate("space", 15)
  else
    Lp = {
      start = function() end,
      stop = function() end,
      report = function() return "" end,
    }
  end

  if args.resolution then
    love.window.updateMode(args.resolution[1], args.resolution[2], {fullscreen = false, minheight = 200, minwidth = 200})
  else
    love.window.updateMode(0, 0, {fullscreen = true, minheight = 200, minwidth = 200})
  end

  State = state.new(assert(love.filesystem.load("engine/systems/init.lua"))(), args)
  assert = safety.assert
  Error = safety.error

  Log.info("Finished love.load")
end
