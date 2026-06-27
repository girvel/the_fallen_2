local preload = require("engine.tech.ldtk.preload")
local generate_entities = require("engine.tech.ldtk.generate_entities")
local read_json         = require("engine.tech.ldtk.read_json")


--- LDtk driver
local ldtk = {}

--- @alias palette table<string, table<string | integer, function>>

--- Level's init.lua return
--- @class level_definition
--- @field ldtk_path string
--- @field palette palette entity factories by layer and then name
--- @field rails_new fun(checkpoint: string): rails
--- @field level_mix_in fun(t: level_base)

--- @alias ch table<string, entity>
--- @alias ps table<string, vector>

--- @class level_base
--- @field atlases table<string, love.Image> atlas images for each grid_layer that uses them
--- @field grid_size vector
--- @field positions ps
--- @field entities ch
--- @field locked_entities table<entity, true>
local level_methods = {}

--- @class load_result
--- @field entities entity[]
--- @field rails_new fun(checkpoint: string): rails
--- @field level level
--- @field shadows grid<number>

--- Read LDtk level file
--- @async
--- @param path string
--- @return load_result
ldtk.load = function(path)
  local init_path = path .. "/init.lua"
  if not love.filesystem.getInfo(init_path) then
    error(string.format(
      "There is no level definition at %q. The file should return a table of type level_definition.",
      init_path
    ))
  end

  local definition = love.filesystem.load(init_path)() --[[@as level_definition]]
  local json = read_json(definition.ldtk_path)
  coroutine.yield("json", 1)
  local preload_data = preload(json)
  coroutine.yield("preload", 1)
  local generation_data = generate_entities(definition.palette, preload_data.entities)

  local level = {
    entities = Table.strict(generation_data.captured_entities, "captured entities"),
    positions = Table.strict(preload_data.positions, "captured positions"),
    locked_entities = {},
    atlases = generation_data.atlases,
    grid_size = preload_data.size,
  }
  Table.extend(level, level_methods)
  definition.level_mix_in(level)

  return {
    entities = generation_data.entities,
    rails_new = definition.rails_new,
    level = level,
    shadows = preload_data.shadows,
  }
end

--- @param prefix string
--- @return vector[]
level_methods.position_sequence = function(self, prefix)
  local result = {}
  local count = 0
  for name, position in pairs(self.positions) do
    if not name:starts_with(prefix .. "_") then goto continue end
    local index = tonumber(name:sub(#prefix + 2))
    if not index then goto continue end
    result[index] = position
    count = count + 1

    ::continue::
  end

  if count ~= #result then
    Error("Hole in position sequence %q: %i is missing", prefix, #result + 1)
  end

  return result
end

Ldump.mark(ldtk, {}, ...)
return ldtk
