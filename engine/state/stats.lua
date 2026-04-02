local stats = {}

--- @class state_stats
--- @field active_ais string[]
--- @field ai_frame_time number
local methods = {}
stats.mt = {__index = methods}

--- @return state_stats
stats.new = function()
  return setmetatable({
    active_ais = {},
    ai_frame_time = 1,
  }, stats.mt)
end

Ldump.mark(stats, {mt = "const"}, ...)
return stats
