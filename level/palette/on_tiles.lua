local factoring = require("engine.tech.factoring")
local on_tiles = {}

----------------------------------------------------------------------------------------------------
-- [SECTION] Atlas
----------------------------------------------------------------------------------------------------

on_tiles.ATLAS_IMAGE = love.graphics.newImage("assets/atlases/on_tiles.png")
local packer = factoring.packer(on_tiles.ATLAS_IMAGE)

packer.offset = 0

do
  local i, this_sprite = packer:geti(1)
  on_tiles[i] = function()
    return {
      boring_flag = true,
      codename = "fern",
      sprite = this_sprite,
    }
  end
end

for index = 2, 4 do
  local i, this_sprite = packer:geti(index)
  on_tiles[i] = function()
    return {
      boring_flag = true,
      codename = "horsetail",
      sprite = this_sprite,
    }
  end
end

for index = 5, 7 do
  local i, this_sprite = packer:geti(index)
  on_tiles[i] = function()
    return {
      boring_flag = true,
      codename = "mushroom",
      sprite = this_sprite,
    }
  end
end

for index = 9, 11 do
  local i, this_sprite = packer:geti(index)
  on_tiles[i] = function()
    return {
      boring_flag = true,
      codename = "bones",
      sprite = this_sprite,
    }
  end
end

for index = 17, 18 do
  local i, this_sprite = packer:geti(index)
  on_tiles[i] = function()
    return {
      boring_flag = true,
      codename = "bone_flour",
      sprite = this_sprite,
    }
  end
end

for index = 19, 20 do
  local i, this_sprite = packer:geti(index)
  on_tiles[i] = function()
    return {
      boring_flag = true,
      codename = "poodle",
      sprite = this_sprite,
    }
  end
end

for index = 25, 26 do
  local i, this_sprite = packer:geti(index)
  on_tiles[i] = function()
    return {
      boring_flag = true,
      codename = "sandcastle",
      sprite = this_sprite,
      ai = {
        observe = function(self, entity)
          if State.grids.solids[entity.position] then
            State:remove(entity)
          end
        end,
      },
    }
  end
end

Ldump.mark(on_tiles, {}, ...)
return on_tiles
