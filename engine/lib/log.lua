local inspect = require("engine.lib.inspect")
local name = require("engine.lib.name")


local log = {}

log.usecolor = true
log.level = "trace"

local levels, count, pretty


--- @param fmt any
--- @param ... any
--- @return string
log.format = function(fmt, ...)
  return fmt:format(pretty(...))
end

local _log = function(level, trace_shift, message)
  if count[level] then
    count[level] = count[level] + 1
  end

  if levels[level].index < levels[log.level].index then
    return
  end

  local info = debug.getinfo(2 + trace_shift, "Sl")
  local lineinfo = info.short_src .. ":" .. info.currentline
  local nameupper = (level --[[@as string]]):upper()
  local frame_number = Kernel and (" %03d"):format(Kernel.frame_n % 1000) or ""

  print(("%s[%-6s%s%s]%s %s: %s"):format(
    log.usecolor and levels[level].color or "",
    nameupper,
    os.date("%H:%M:%S"),
    frame_number,
    log.usecolor and "\27[0m" or "",
    lineinfo,
    message
  ))

  if log.outfile then
    love.filesystem.append(
      log.outfile, ("[%-6s%s%s] %s: %s\n"):format(
        nameupper,
        os.date("%H:%M:%S"),
        frame_number,
        lineinfo,
        message
      )
    )
  end
end

--- @generic T
--- @param level log_level
--- @param trace_shift integer
--- @param fmt any
--- @param ... T
--- @return T
log.log = function(level, trace_shift, fmt, ...)
  _log(level, trace_shift, log.format(fmt, ...))
  return ...
end

--- @generic T
--- @param ... T
--- @return T ...
log.traces = function(...)
  local to_log = {pretty(...)}
  for i, v in ipairs(to_log) do
    to_log[i] = tostring(v)
  end
  _log("trace", 1, table.concat(to_log, " "))
  return ...
end

--- @param line string
--- @return string
local extract_expr = function(line)
  local a, b = line:find(".tracel(", 1, true)
  if not a then return line end

  local depth = 1
  local expr = ""
  for i = b + 1, #line do
    local char = line:sub(i, i)
    if char == ")" then
      depth = depth - 1
      if depth == 0 then return expr end
    elseif char == "(" then
      depth = depth + 1
    end

    expr = expr .. char
  end

  return expr
end

--- @generic T
--- @param ... T
--- @return T
log.tracel = function(...)
  local repr do
    local to_log = {pretty(...)}
    for i, v in ipairs(to_log) do
      to_log[i] = tostring(v)
    end
    repr = table.concat(to_log, " ")
  end

  local info = debug.getinfo(2)
  if love.filesystem.getInfo(info.short_src) then
    local source = love.filesystem.read(info.short_src)
    if source then
      local lines = source:split("\n", true)
      local expr = extract_expr(lines[info.currentline])
      if select("#", ...) == 1 then
        log.log("trace", 1, "%s: %s", expr, repr)
      else
        log.log("trace", 1, "(%s): (%s)", expr, repr)
      end
      return ...
    end
  end

  _log("trace", 1, repr)
  return ...
end

--- @generic T
--- @param fmt any
--- @param ... T
--- @return T
log.trace = function(fmt, ...)
  return log.log("trace", 1, fmt, ...)
end

--- @generic T
--- @param fmt any
--- @param ... T
--- @return T
log.debug = function(fmt, ...)
  return log.log("debug", 1, fmt, ...)
end

--- @generic T
--- @param fmt any
--- @param ... T
--- @return T
log.info = function(fmt, ...)
  return log.log("info", 1, fmt, ...)
end

--- @generic T
--- @param fmt any
--- @param ... T
--- @return T
log.warn = function(fmt, ...)
  return log.log("warn", 1, fmt, ...)
end

local warned = {}

--- @generic T
--- @param fmt any
--- @param ... T
--- @return T
log.warn_once = function(fmt, ...)
  if select("#", ...) > 0 then
    fmt = fmt:format(...)
  end
  if warned[fmt] then return ... end
  warned[fmt] = true
  return log.log("warn", 1, fmt)
end

--- @generic T
--- @param fmt any
--- @param ... T
--- @return T
log.error = function(fmt, ...)
  return log.log("error", 1, fmt, ...)
end

--- @generic T
--- @param fmt any
--- @param ... T
--- @return T
log.fatal = function(fmt, ...)
  return log.log("fatal", 1, fmt, ...)
end

log.report = function()
  local level = "info"
  if count.fatal > 0 then
    level = "fatal"
  elseif count.error > 0 then
    level = "error"
  elseif count.warn > 0 then
    level = "warn"
  end

  levels.rep = levels[level]

  log.log("rep", 1, ("%s warnings, %s errors, %s fatal"):format(count.warn, count.error, count.fatal))
end

--- @enum (key) log_level
levels = {
  trace = {color = "\27[34m", index = 1},
  debug = {color = "\27[36m", index = 2},
  info = {color = "\27[32m", index = 3},
  warn = {color = "\27[33m", index = 4},
  error = {color = "\27[31m", index = 5},
  fatal = {color = "\27[35m", index = 6},
  rep = {},
}

count = {
  warn = 0,
  error = 0,
  fatal = 0,
}

pretty = function(...)
  local result = {}
  for i = 1, select('#', ...) do
    local x = select(i, ...)
    if type(x) == "table" then
      x = name.code(x, nil) or inspect(x, {depth = 3, keys_limit = 20})
    elseif x == nil then
      x = "nil"
    end
    result[i] = x
  end
  return unpack(result)
end

if love then
  local ok, res = pcall(function()
    local log_directory = "logs"
    local log_directory_abs = love.filesystem.getSaveDirectory() .. "/" .. log_directory
    if not love.filesystem.getInfo(log_directory_abs) then
      love.filesystem.createDirectory(log_directory)
    end
    log.outfile = log_directory .. "/" .. os.date("%Y-%m-%d_%H-%M-%S") .. ".txt"

    local MB = 1024 * 1024
    local MAX_FILE_SIZE = 1 * MB
    local MAX_FOLDER_SIZE = 16 * MB

    local existing_logs = love.filesystem.getDirectoryItems(log_directory)
    table.sort(existing_logs)

    local total_size = 0
    for _, filename in ipairs(existing_logs) do
      local full_path = log_directory .. "/" .. filename
      local info = love.filesystem.getInfo(full_path, "file")
      if not info then goto continue end

      if info.size <= MAX_FILE_SIZE then
        total_size = total_size + info.size
      else
        local content = love.filesystem.read(full_path)
        local half = MAX_FILE_SIZE / 2
        local placeholder = "\n[truncated]\n"
        local content_truncated = content:sub(1, half - #placeholder - 1)
          .. placeholder
          .. content:sub(info.size - half)
        love.filesystem.write(full_path, content_truncated)

        log.info("Truncated %s from %.2ff MB to 1.00 MB", full_path, #content / MB)
        total_size = total_size + MB
      end

      ::continue::
    end

    for _, filename in ipairs(existing_logs) do
      if total_size <= MAX_FOLDER_SIZE then break end

      local full_path = log_directory .. "/" .. filename
      local size = love.filesystem.getInfo(full_path, "file").size
      love.filesystem.remove(full_path)
      log.info("Removed %s", full_path)
      total_size = total_size - size
    end

    log.info("Log folder is %.2f MB", total_size / MB)
  end)

  if not ok then
    log.error("Log cleanup error: %s", res)
  end
end

return log
