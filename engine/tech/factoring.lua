local sprite = require "engine.tech.sprite"


--- Module for simplifying palette creation
local factoring = {}

--- @class factoring_packer
--- @field offset integer
--- @field _atlas_image love.Image
local packer_methods = {}
factoring.packer_mt = {__index = packer_methods}

--- @param atlas_image love.Image
--- @return factoring_packer
factoring.packer = function(atlas_image)
  return setmetatable({
    offset = 0,
    _atlas_image = atlas_image,
  }, factoring.packer_mt)
end

--- @param x integer
--- @param y integer
--- @return integer i
--- @return sprite_atlas this_sprite
packer_methods.get = function(self, x, y)
  local i = x + (y - 1) * 8
  return self:geti(i)
end

--- @param local_i integer
--- @return integer i
--- @return sprite_atlas this_sprite
packer_methods.geti = function(self, local_i)
  return self.offset + local_i, sprite.from_atlas(self.offset + local_i, Constants.cell_size, self._atlas_image)
end

Ldump.mark(factoring, {}, ...)
return factoring
