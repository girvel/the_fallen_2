--- Module that fixes LuaJIT's FFI
local ffi = require("ffi")


local ffi_fix = {}

ffi_fix.load = function(name)
  local extension if love.system.getOS() == "Windows" then
    extension = ".dll"
  else
    extension = ".so"
  end

  for _, path in ipairs({
    love.filesystem.getSource() .. "/engine/lib/" .. name .. extension,
    love.filesystem.getSourceBaseDirectory() .. "/" .. name .. extension,
    -- the top two alone should do the trick
    -- but +1 ms load time is better than a crash in production
    "engine/lib/" .. name,
    love.filesystem.getSource() .. "/engine/lib/" .. name,
    love.filesystem.getSourceBaseDirectory() .. "/" .. name,
    "engine/lib/" .. name .. extension,
  }) do
    local ok, result = pcall(ffi.load, path)
    Log.info("Loading %s @ %s: %s, %s", name, path, ok, result)
    if ok then return result end
  end

  -- TODO russian characters in path
end

Ldump.mark(ffi_fix, {}, ...)
return ffi_fix
