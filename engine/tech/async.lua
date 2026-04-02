local async = {}

async.lag_threshold = 1

--- @param coroutine_ thread
--- @param ... any
--- @return any ...
async.resume = function(coroutine_, ...)
  local t = love.timer.getTime()
  local result = {coroutine.resume(coroutine_, ...)}
  t = love.timer.getTime() - t
  if t > async.lag_threshold then
    Log.warn("Coroutine lags (%.2f s)\n%s", t, debug.traceback())
  end

  local ok = table.remove(result, 1)
  if not ok then
    local message = ("Coroutine error: %s\ncoroutine %s"):format(result[1], debug.traceback(coroutine_))
    if State.debug then
      error(message)
    else
      Log.error(message)
    end
  end

  return unpack(result)
end

--- @async
--- @param seconds number
async.sleep = function(seconds)
  local t = love.timer.getTime()
  while love.timer.getTime() - t < seconds do
    coroutine.yield()
  end
end

--- @class async_sometimes
--- @field counter integer
--- @field k integer
--- @field last_t number
local sometimes_methods = {}
async.sometimes_mt = {__index = sometimes_methods}

async.sometimes = function(k)
  return setmetatable({
    counter = 0,
    k = k or 100,
    last_t = love.timer.getTime(),
  }, async.sometimes_mt)
end

sometimes_methods.yield = function(self, ...)
  self.counter = self.counter + 1
  if self.counter % self.k ~= 0 then return end

  local now = love.timer.getTime()
  if now - self.last_t >= Constants.yield_period then
    self.last_t = now
    coroutine.yield(...)
  end
end

Ldump.mark(async, {sometimes_mt = {}}, ...)
return async
