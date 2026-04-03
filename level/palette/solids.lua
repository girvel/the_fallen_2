local sprite = require("engine.tech.sprite")
local sound = require("engine.tech.sound")
local async = require("engine.tech.async")
local interactive = require("engine.tech.interactive")
local abilities = require("engine.mech.abilities")
local humanoid = require("engine.mech.humanoid")
local player_base = require("engine.state.player.base")


local solids = {}

----------------------------------------------------------------------------------------------------
-- [SECTION] Atlas
----------------------------------------------------------------------------------------------------

solids.ATLAS_IMAGE = love.graphics.newImage("assets/atlases/solids.png")

local offset = 0
for y = 1, 4 do
  for x = 1, 4 do
    local i = offset + x + (y - 1) * 8
    local this_sprite = sprite.from_atlas(i, Constants.cell_size, solids.ATLAS_IMAGE)
    solids[i] = function()
      return {
        boring_flag = true,
        codename = "ancient_wall",
        name = "Стена",
        sprite = this_sprite,
      }
    end
  end

  for x = 5, 8 do
    local i = offset + x + (y - 1) * 8
    local this_sprite = sprite.from_atlas(i, Constants.cell_size, solids.ATLAS_IMAGE)
    solids[i] = function()
      return {
        boring_flag = true,
        codename = "hut_wall",
        name = "Стена",
        sprite = this_sprite,
      }
    end
  end
end

offset = 32
for y = 1, 4 do
  for x = 1, 4 do
    local i = offset + x + (y - 1) * 8
    local this_sprite = sprite.from_atlas(i, Constants.cell_size, solids.ATLAS_IMAGE)
    solids[i] = function()
      return {
        boring_flag = true,
        codename = "ancient_wall_ornament",
        name = "Стена",
        sprite = this_sprite,
      }
    end
  end

  for x = 5, 8 do
    local i = offset + x + (y - 1) * 8
    local this_sprite = sprite.from_atlas(i, Constants.cell_size, solids.ATLAS_IMAGE)
    solids[i] = function()
      return {
        boring_flag = true,
        low_flag = true,
        transparent_flag = true,
        codename = "stage",
        name = "Платформа",
        sprite = this_sprite,
      }
    end
  end
end

offset = 64
-- nothing yet --

offset = 96
for y = 1, 4 do
  for x = 1, 4 do
    local i = offset + x + (y - 1) * 8
    local this_sprite = sprite.from_atlas(i, Constants.cell_size, solids.ATLAS_IMAGE)
    solids[i] = function()
      return {
        boring_flag = true,
        low_flag = true,
        transparent_flag = true,
        codename = "fence",
        name = "Забор",
        sprite = this_sprite,
      }
    end
  end
end

--- @param factory function
--- @param grid_layer grid_layer
--- @param sound_path string
local get_open = Memoize(function(factory, grid_layer, sound_path)
  local sounds = sound.multiple(sound_path, .8)

  return function(self)
    local open_itself = function()
      State:remove(self)
      State:add_at(factory(), self.position, grid_layer)
    end

    local _, scene = State.runner:run_task(function()
      if sounds then
        sounds:play_at(self.position)
      end
      async.sleep(.18)
      open_itself()
    end)
    scene.on_cancel = open_itself
  end
end)

for _, tuple in ipairs {
  {5, "cabinet_green", "Шкаф", "assets/sounds/cabinet/open"},
  {7, "shelf_green", "Полки", "assets/sounds/cabinet/open"},
  {13, "cabinet_blue", "Шкаф", "assets/sounds/cabinet/open"},
  {15, "shelf_blue", "Полки", "assets/sounds/cabinet/open"},
} do
  local i, codename, name, sound_path = unpack(tuple --[=[@as [integer, string, string, string]]=])
  local codename_open = codename .. "_open"
  i = i + offset

  solids[i + 1] = function()
    return {
      boring_flag = true,
      low_flag = true,
      transparent_flag = true,
      codename = codename_open,
      name = name,
      sprite = sprite.from_atlas(i + 1, Constants.cell_size, solids.ATLAS_IMAGE),
    }
  end

  local open = get_open(solids[i + 1], "solids", sound_path)
  solids[i] = function()
    local e = {
      boring_flag = true,
      low_flag = true,
      transparent_flag = true,
      codename = "cabinet_green",
      name = "Шкаф",
      sprite = sprite.from_atlas(i, Constants.cell_size, solids.ATLAS_IMAGE),
    }
    interactive.mix_in(e, open)
    return e
  end
end

----------------------------------------------------------------------------------------------------
-- [SECTION] Entities
----------------------------------------------------------------------------------------------------

solids.player = function()
  local result = {
    name = "Протагонист",
    base_abilities = abilities.new(8, 8, 8, 8, 8, 8),
    level = 0,
    perks = {},
    faction = "player",
  }
  player_base.mix_in(result)
  humanoid.mix_in(result)
  return result
end

Ldump.mark(solids, {}, ...)
return solids
