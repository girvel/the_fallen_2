local safety = {}

--- Prevents the system from running if the level is not fully loaded
--- @generic T
--- @param system T
--- @return T
safety.live_system = function(system)
  --- @cast system table
  local prev = system.update
  system.update = function(...)
    if not State.is_loaded then return end
    return prev(...)
  end
  return system
end

local built_in_assert = assert

--- Normal assert in debug mode, just a warning in release
--- @generic T
--- @param condition T
--- @param message? string
--- @return T
safety.assert = function(condition, message)
  if State.debug then
    -- without this if, single argument assert attaches no stacktrace
    if message then
      return built_in_assert(condition, message)
    else
      return built_in_assert(condition)
    end
  end

  if condition then
    return condition
  end

  Log.error("Assert failed: %s", message)
  return condition
end

--- Errors in debug mode, warns in release
--- @param fmt any
--- @param ... any
safety.error = function(fmt, ...)
  local message
  if fmt == nil and select("#", ...) == 0 then
    message = ""
  else
    message = Log.format(fmt, ...)
  end

  if State.debug then
    error(message, 1)
  else
    Log.log("error", 1, message)
  end
end

--- @param f function
--- @param ... any
--- @return any
safety.call = function(f, ...)
  if State.debug then
    return f(...)
  end

  local ok, result = xpcall(f, function(msg)
    return tostring(msg) .. "\n" .. debug.traceback()
  end, ...)
  if ok then return result end

  Log.error("safety.call error: %s", result)
end

--- Prevents the system from running if the level is not fully loaded
--- @generic T
--- @param system T
--- @return T
safety.for_system = function(system)
  for _, key in ipairs {"update", "process", "preProcess", "postProcess", "onAdd", "onRemove"} do
    local inner = system[key]
    if inner then
      system[key] = Ldump.ignore_upvalue_size(function(...)
        return safety.call(inner, ...)
      end)
    end
  end

  return system
end

Ldump.mark(safety, {}, ...)
return safety
