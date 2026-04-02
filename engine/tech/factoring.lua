local sprite = require "engine.tech.sprite"
--- Module for simplifying palette creation
local factoring = {}

--- @param atlas_path string
--- @param codenames (string | boolean)[]
--- @param mixin? fun(string): table
--- @return {[string | integer]: function}
factoring.from_atlas = function(atlas_path, cell_size, codenames, mixin)
  local result = {ATLAS_IMAGE = love.graphics.newImage(atlas_path)}
  for i, codename in ipairs(codenames) do
    if not codename then goto continue end
    local factory = function()
      local e = mixin and mixin(codename) or {}
      e.codename = codename
      e.sprite = sprite.from_atlas(i, cell_size, result.ATLAS_IMAGE)
      return e
    end

    result[i] = factory
    result[codename] = factory
    ::continue::
  end
  return result
end

Ldump.mark(factoring, {}, ...)
return factoring
