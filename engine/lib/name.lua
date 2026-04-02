--- Module for displaying names
local name = {}

local NO_ENTITY = "<none>"
local NO_NAME = "<no name>"

--- @class name_pair
--- @field name string
--- @field codename string

--- Get best possible in-game naming; prefers .name, then .codename, then the default value
--- @param entity entity?
--- @param ... any default value
--- @return string|any
name.game = function(entity, ...)
  if not entity then return NO_ENTITY end
  local default if select("#", ...) > 0 then
    default = select(1, ...)
  else
    default = NO_NAME
  end
  return rawget(entity, "name") or rawget(entity, "codename") or default
end

--- Get best possible in-code naming; prefers .codename, then .name, then the default value
--- @param entity entity?
--- @param ... any default value
--- @return string|any
name.code = function(entity, ...)
  if not entity then return NO_ENTITY end
  local default if select("#", ...) > 0 then
    default = select(1, ...)
  else
    default = NO_NAME
  end
  return rawget(entity, "codename") or rawget(entity, "name") or default
end

return name
