local saves = {}

local SLASH = love.system.getOS() == "Windows" and "\\" or "/"

love.filesystem.createDirectory("saves")

--- @param target any
--- @param path string
saves.write = function(target, path)
  local base = love.filesystem.getSaveDirectory()
  Log.info("Saving to %s%s%s", base, SLASH, path)

  local t = love.timer.getTime()
  love.filesystem.write(path, love.data.compress("string", "gzip", Ldump(target)))
  t = love.timer.getTime() - t

  Fun.iter(Ldump.get_warnings()):each(Log.warn)
  local size_kb = love.filesystem.getInfo(path).size / 1024
  Log.info("Saved in %.2f s, file size %.2f KB", t, size_kb)
end

--- @nodiscard
--- @param path string
--- @return any
saves.read = function(path)
  local base = love.filesystem.getSaveDirectory()
  Log.info("Loading from %s%s%s", base, SLASH, path)

  local t = love.timer.getTime()
  local result = assert(loadstring(
    love.data.decompress(
      "string", "gzip", love.filesystem.read(path)
    ) --[[@as string]],
    path
  ))()
  t = love.timer.getTime() - t

  Log.info("Loaded in %.2f s", t)
  return result
end

return saves
