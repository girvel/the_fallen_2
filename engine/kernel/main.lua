if not love then
  io.stderr:write(
    "Needs to be run with LOVE2D; install it from love2d.org, then run the game with `love .`\n"
  )
  os.exit(1)
end

love.graphics.setDefaultFilter("nearest", "nearest")
love.audio.setDistanceModel("exponent")
love.mouse.setVisible(false)
require("engine.kernel.globals")
require("engine.kernel.wrappers")
require("engine.kernel.callbacks")

Log.info("Initialized kernel setup")
