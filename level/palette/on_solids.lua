local health = require("engine.mech.health")
local interactive = require("engine.tech.interactive")
local factoring = require("engine.tech.factoring")


local on_solids = {}

----------------------------------------------------------------------------------------------------
-- [SECTION] Atlas
----------------------------------------------------------------------------------------------------

on_solids.ATLAS_IMAGE = love.graphics.newImage("assets/atlases/on_solids.png")
local packer = factoring.packer(on_solids.ATLAS_IMAGE)

packer.offset = 0

do
  local define_vines = function(x, y)
    local i, this_sprite = packer:get(x, y)
    on_solids[i] = function()
      return {
        boring_flag = true,
        codename = "vines",
        sprite = this_sprite,
      }
    end
  end

  for x = 1, 3 do
    for y = 1, 2 do
      define_vines(x, y)
    end
  end

  for x = 4, 5 do
    for y = 3, 4 do
      define_vines(x, y)
    end
  end
end

for x = 4, 5 do
  for y = 1, 2 do
    local i, this_sprite = packer:get(x, y)
    on_solids[i] = function()
      return {
        boring_flag = true,
        codename = "mold",
        sprite = this_sprite,
      }
    end
  end
end

for index = 6, 7 do
  local i, this_sprite = packer:geti(index)
  on_solids[i] = function()
    return {
      boring_flag = true,
      codename = "grass_high",
      sprite = this_sprite,
    }
  end
end

packer.offset = 16

local collect_berries = function(self, other)
  State:remove(self)
  health.heal(other, 1)
end

for x = 2, 3 do
  for y = 1, 2 do
    local i, this_sprite = packer:get(x, y)
    on_solids[i] = function()
      local e = {
        boring_flag = true,
        codename = "berries",
        name = "ягоды",
        sprite = this_sprite,
      }
      interactive.mix_in(e, collect_berries)
      return e
    end
  end
end

packer.offset = 32

-- empty --

packer.offset = 48

for index = 1, 2 do
  local i, this_sprite = packer:geti(index)
  on_solids[i] = function()
    return {
      boring_flag = true,
      codename = "door_open",
      sprite = this_sprite,
    }
  end
end

for index = 9, 12 do
  local i, this_sprite = packer:geti(index)
  on_solids[i] = function()
    return {
      boring_flag = true,
      codename = "plate",
      sprite = this_sprite,
    }
  end
end

on_solids.plate = on_solids[packer.offset + 10]
local collect_food = function(self, other)
  State:remove(self)
  State:add_at(on_solids.plate(), self.position, "on_solids")
  health.heal(other, 1)
end

for index = 13, 14 do
  local i, this_sprite = packer:geti(index)
  on_solids[i] = function()
    local e = {
      boring_flag = true,
      codename = "food",
      sprite = this_sprite,
    }
    interactive.mix_in(e, collect_food)
    return e
  end
end

for x = 1, 3 do
  for y = 3, 4 do
    local i, this_sprite = packer:get(x, y)
    on_solids[i] = function()
      return {
        boring_flag = true,
        codename = "vase",
        sprite = this_sprite,
      }
    end
  end
end

for index = 20, 22 do
  local i, this_sprite = packer:geti(index)
  on_solids[i] = function()
    return {
      boring_flag = true,
      codename = "candles",
      sprite = this_sprite,
    }
  end
end

-- TODO drinking beer?
do
  local i, this_sprite = packer:geti(28)
  on_solids[i] = function()
    return {
      boring_flag = true,
      codename = "beer",
      sprite = this_sprite,
    }
  end
end

do
  local i, this_sprite = packer:geti(29)
  on_solids[i] = function()
    return {
      boring_flag = true,
      codename = "newspaper",
      sprite = this_sprite,
    }
  end
end

do
  local i, this_sprite = packer:geti(30)
  on_solids[i] = function()
    return {
      boring_flag = true,
      codename = "wine_bottle",
      sprite = this_sprite,
    }
  end
end

packer.offset = 80

do
  local i, this_sprite = packer:geti(1)
  on_solids[i] = function()
    return {
      boring_flag = true,
      codename = "skull",
      sprite = this_sprite,
    }
  end
end

for index = 2, 4 do
  local i, this_sprite = packer:geti(index)
  on_solids[i] = function()
    return {
      boring_flag = true,
      codename = "bones",
      sprite = this_sprite,
    }
  end
end

for index = 5, 6 do
  local i, this_sprite = packer:geti(index)
  on_solids[i] = function()
    return {
      boring_flag = true,
      codename = "bone_flour",
      sprite = this_sprite,
    }
  end
end

do
  local i, this_sprite = packer:geti(9)
  on_solids[i] = function()
    return {
      boring_flag = true,
      codename = "sign",
      sprite = this_sprite,
    }
  end
end

do
  local i, this_sprite = packer:geti(10)
  on_solids[i] = function()
    return {
      boring_flag = true,
      codename = "stage",
      sprite = this_sprite,
    }
  end
end

do
  local i, this_sprite = packer:geti(11)
  on_solids[i] = function()
    return {
      boring_flag = true,
      codename = "window",
      sprite = this_sprite,
    }
  end
end

packer.offset = 96
for index = 1, 8 do
  local i, this_sprite = packer:geti(index)
  on_solids[i] = function()
    return {
      boring_flag = true,
      codename = "plaster",
      sprite = this_sprite,
    }
  end
end

Ldump.mark(on_solids, {}, ...)
return on_solids
