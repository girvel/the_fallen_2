local sound = require("engine.tech.sound")
local factoring = require("engine.tech.factoring")


local tiles = {}

tiles.ATLAS_IMAGE = love.graphics.newImage("assets/atlases/tiles.png")
local packer = factoring.packer(tiles.ATLAS_IMAGE)

packer.offset = 0
local walk_sounds do
  local stone = sound.multiple("assets/sounds/walk/stone", .0125)
  local walkway = sound.multiple("assets/sounds/walk/walkway", .02)
  local planks = sound.multiple("assets/sounds/walk/planks", .02)

  walk_sounds = {
    dirt = walkway,
    walkway = walkway,
    planks = planks,
    stone = stone,
    bricks = stone,
    ornament = stone,
  }
end

for index, codename in ipairs {
  "stone_bricks", "stone_bricks", "stone", "sand", "roots", "leaves", "grass", "grass",
  "stone_bricks", "stone_bricks", "wtf", "dirt", false, "leaves", "flowers_red", "flowers_red",
  false, "planks", "walkway_stone", "walkway", false, false, "flowers_blue", "flowers_blue",
  false, false, false, false, false, false, false, false,
  "ornament", "ornament", "ornament", "ornament", false, false, false, false,
  "ornament", "ornament", "ornament", "ornament", false, false, false, false,
  "ornament", "ornament", "ornament", "ornament", false, false, false, false,
  "ornament", "ornament", "ornament", "ornament", false, false, false, false,
} do
  if not codename then goto continue end
  local i, this_sprite = packer:geti(index)
  local s = walk_sounds[codename]
  local sounds = s and {walk = s}
  tiles[i] = function()
    return {
      boring_flag = true,
      sounds = sounds,
      sprite = this_sprite,
    }
  end

  ::continue::
end

Ldump.mark(tiles, {}, ...)
return tiles
