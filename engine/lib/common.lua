--- Module with uncategorized utility functions
local common = {}

--- @generic T
--- @param value T
--- @return T
common.nil_serialized = function(value)
  Ldump.serializer.handlers[value] = "nil"
  return value
end

--- @param expression string
--- @return any
common.eval = function(expression)
  local f = loadstring("return " .. expression, expression)
  if not f then
    error(("Invalid syntax in %q"):format(expression), 1)
  end
  return f()
end

return common
