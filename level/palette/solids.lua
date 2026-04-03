local health = require("engine.mech.health")
local factoring = require("engine.tech.factoring")
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
local packer = factoring.packer(solids.ATLAS_IMAGE)

packer.offset = 0
for y = 1, 4 do
  for x = 1, 4 do
    local i, this_sprite = packer:get(x, y)
    solids[i] = function()
      return {
        boring_flag = true,
        codename = "ancient_wall",
        name = "стена",
        sprite = this_sprite,
      }
    end
  end

  for x = 5, 8 do
    local i, this_sprite = packer:get(x, y)
    solids[i] = function()
      return {
        boring_flag = true,
        codename = "hut_wall",
        name = "стена",
        sprite = this_sprite,
      }
    end
  end
end

packer.offset = 32
for y = 1, 4 do
  for x = 1, 4 do
    local i, this_sprite = packer:get(x, y)
    solids[i] = function()
      return {
        boring_flag = true,
        codename = "ancient_wall_ornament",
        name = "стена",
        sprite = this_sprite,
      }
    end
  end

  for x = 5, 8 do
    local i, this_sprite = packer:get(x, y)
    solids[i] = function()
      return {
        boring_flag = true,
        low_flag = true,
        transparent_flag = true,
        codename = "stage",
        name = "платформа",
        sprite = this_sprite,
      }
    end
  end
end

packer.offset = 64
-- nothing yet --

packer.offset = 96
for y = 1, 4 do
  for x = 1, 4 do
    local i, this_sprite = packer:get(x, y)
    solids[i] = function()
      return {
        boring_flag = true,
        low_flag = true,
        transparent_flag = true,
        codename = "fence",
        name = "забор",
        sprite = this_sprite,
      }
    end
  end
end

--- @param factory function
--- @param grid_layer grid_layer
--- @param sound_path string?
local get_open = Memoize(function(factory, grid_layer, sound_path)
  local sounds = sound_path and sound.multiple(sound_path, .8)

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
  {5, "cabinet_green", "шкаф", "assets/sounds/cabinet/open"},
  {7, "shelf_green", "полки", "assets/sounds/cabinet/open"},
  {13, "cabinet_blue", "шкаф", "assets/sounds/cabinet/open"},
  {15, "shelf_blue", "полки", "assets/sounds/cabinet/open"},
  {21, "chest", "сундук", "assets/sounds/chest/open"},
  {23, "bin", "урна", false},
} do
  local index, codename, name, sound_path = unpack(tuple --[=[@as [integer, string, string, string]]=])
  local codename_open = codename .. "_open"

  local i_open, sprite_open = packer:geti(index + 1)
  solids[i_open] = function()
    return {
      boring_flag = true,
      low_flag = true,
      transparent_flag = true,
      codename = codename_open,
      name = name,
      sprite = sprite_open,
    }
  end

  local open = get_open(solids[i_open], "solids", sound_path)
  local i_closed, sprite_closed = packer:geti(index)
  solids[i_closed] = function()
    local e = {
      boring_flag = true,
      low_flag = true,
      transparent_flag = true,
      codename = codename,
      name = name,
      sprite = sprite_closed,
    }
    interactive.mix_in(e, open)
    return e
  end
end

packer.offset = 128

local cobweb_on_death = function(self)
  for _, d in ipairs(Vector.directions) do
    local e = State.grids[self.grid_layer]:slow_get(self.position + d)
    if e and e._cobweb_flag and e.hp > 0 then
      health.damage(e, 1)
    end
  end
end
for x = 1, 3 do
  for y = 1, 2 do
    local i, this_sprite = packer:get(x, y)
    solids[i] = function()
      return {
        boring_flag = true,
        low_flag = true,
        transparent_flag = true,
        _cobweb_flag = true,
        codename = "cobweb",
        name = "паутина",
        sprite = this_sprite,
        hp = 1,
        on_death = cobweb_on_death,
      }
    end
  end
end

for _, tuple in ipairs {
  {4, "table", "стол"},
  {5, "table", "стол"},
  {6, "stool", "табурет"},
  {7, "hut_wall_transparent", "стена"},
  {8, "hut_wall_transparent", "стена"},
  {12, "table", "стол"},
  {13, "bed", "кровать"},
  {14, "bed_rough", "кровать"},
  {18, "table", "стол"},
  {19, "table", "стол"},
  {20, "table", "стол"},
  {22, "candles", "свечи"},
  {23, "candles", "свечи"},
  {24, "candles", "свечи"},
} do
  local index, codename, name = unpack(tuple --[[@as table]])
  local i, this_sprite = packer:geti(index)
  solids[i] = function()
    return {
      boring_flag = true,
      transparent_flag = true,
      codename = codename,
      name = name,
      sprite = this_sprite,
    }
  end
end

packer.offset = 160

for _, index in ipairs {1, 2, 3, 4, 9, 10, 11, 12, 17, 18, 25, 26} do
  local i, this_sprite = packer:geti(index)
  solids[i] = function()
    return {
      boring_flag = true,
      transparent_flag = true,
      low_flag = true,
      codename = "slope",
      name = "склон",
      sprite = this_sprite,
    }
  end
end

for _, tuple in ipairs {
  {5, "campfire", "костёр", true},
  {6, "log", "бревно", true},
  {13, "rubble", "обломки", true},
  {14, "log", "бревно", true},
  {19, "bush", "куст", true},
  {20, "bush", "куст", true},
  {21, "bush", "куст", false},
  {22, "log", "бревно", true},
  {27, "bush", "куст", true},
  {28, "bush", "куст", true},
  {29, "bush", "куст", false},
  {30, "log", "бревно", true},
  {31, "log", "бревно", true},
  {32, "log", "бревно", true},
} do
  local index, codename, name, is_transparent = unpack(tuple --[[@as table]])
  local i, this_sprite = packer:geti(index)
  solids[i] = function()
    return {
      boring_flag = true,
      transparent_flag = is_transparent or nil,
      codename = codename,
      name = name,
      sprite = this_sprite,
    }
  end
end

for x = 7, 8 do
  for y = 1, 3 do
    local i, this_sprite = packer:get(x, y)
    solids[i] = function()
      return {
        boring_flag = true,
        _tree_flag = true,
        codename = "trunk",
        name = "Ствол",
        sprite = this_sprite,
      }
    end
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
