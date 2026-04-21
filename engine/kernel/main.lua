love.graphics.setDefaultFilter("nearest", "nearest")
love.audio.setDistanceModel("exponent")
love.mouse.setVisible(false)
require("engine.kernel.globals")
require("engine.kernel.wrappers")
require("engine.kernel.callbacks")

Log.info("Initialized kernel setup")
