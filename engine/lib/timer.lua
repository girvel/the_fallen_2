--- @class timer
--- @field t number?
--- @field frame integer?
local timer = {}

timer.start = function()
  timer.t = love.timer.getTime()
  timer.frame = Kernel.frame_n
end

timer.stop = function()
  Log.log("trace", 1, "%.2f s, %s frames", love.timer.getTime() - timer.t, Kernel.frame_n - timer.frame + 1)
  timer.t = nil
  timer.frame = nil
end

return timer
