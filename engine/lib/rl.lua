local ffi = require("ffi")

ffi.cdef [[
  char *readline(const char *);
  void free(void *);
]]
local lib = ffi.load("engine/lib/libreadline.so")

local rl = {}

--- @param prompt string
--- @return string?
rl.readline = function(prompt)
  local raw = lib.readline(prompt)
  if raw == nil then return nil end
  local s = ffi.string(raw)
  lib.free(raw)
  return s
end

return rl

