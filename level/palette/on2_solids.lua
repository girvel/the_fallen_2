local factoring = require("engine.tech.factoring")


local on2_solids = {}

on2_solids.ATLAS_IMAGE = love.graphics.newImage("assets/atlases/on2_solids.png")
local packer = factoring.packer(on2_solids.ATLAS_IMAGE)

for x = 1, 7 do
  for y = 1, 2 do
    local i, this_sprite = packer:get(x, y)
    on2_solids[i] = function()
      return {
        boring_flag = true,
        codename = "cobweb",
        sprite = this_sprite,
      }
    end
  end
end

for x = 1, 2 do
  local i, this_sprite = packer:get(x, 3)
  on2_solids[i] = function()
    return {
      boring_flag = true,
      codename = "herbs",
      sprite = this_sprite,
    }
  end
end

packer.offset = 32
do
  local i, this_sprite = packer:get(1, 1)
  on2_solids[i] = function()
    return {
      boring_flag = true,
      codename = "wine_glass",
      sprite = this_sprite,
    }
  end
end

packer.offset = 40
for x = 1, 6 do
  local i, this_sprite = packer:get(x, 1)
  on2_solids[i] = function()
    return {
      boring_flag = true,
      codename = "lamp",
      sprite = this_sprite,
    }
  end
end

Ldump.mark(on2_solids, {}, ...)
return on2_solids
