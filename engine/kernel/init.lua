local kernel = {}

--- @class kernel middleware between fallen engine and LOVE
--- @field _save? string
--- @field _load? string
--- @field _specific_key_rates table<love.KeyConstant, number>
--- @field _delays table<love.KeyConstant, number>
--- @field _is_active boolean
--- @field frame_n integer
--- @field cpu_time number
--- @field start_time number
--- @field screenshot love.Canvas
local methods = {}
local mt = {__index = methods}

--- @return kernel
kernel.new = function()
  return setmetatable({
    _specific_key_rates = {},
    _delays = {},
    frame_n = 0,
    cpu_time = 0,
    start_time = 0,
    _is_active = false,
    screenshot = love.graphics.newCanvas(),
  }, mt)
end

--- @param name string
methods.plan_save = function(self, name)
  self._save = "saves/" .. name .. ".ldump.gz"
end

--- @param name string
methods.plan_load = function(self, name)
  self._load = "saves/" .. name .. ".ldump.gz"
end

--- @param key love.KeyConstant
--- @param value number
methods.set_key_rate = function(self, key, value)
  self._specific_key_rates[key] = value
end

local DEFAULT_KEY_RATE = 5

--- @param key love.KeyConstant
--- @return number
methods.get_key_rate = function(self, key)
  return self._specific_key_rates[key] or DEFAULT_KEY_RATE
end

methods.report = function(self)
  if State.args.profiler then
    Log.info(Profile.report(100))
  end

  local line_report = Lp.report()
  if #line_report > 0 then
    Log.info("Line profile:\n%s", line_report)
  end

  Log.info("Play time %s s, average FPS is %.2f", math.floor(love.timer.getTime() - self.start_time), self.frame_n / self.cpu_time)
  Log.info("Saved log to %s/%s", love.filesystem.getRealDirectory(Log.outfile), Log.outfile)
  Log.report()
end

return kernel
