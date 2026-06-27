local level = require("engine.tech.level")
local sprite = require("engine.tech.sprite")
----------------------------------------------------------------------------------------------------
-- [SECTION] External API
----------------------------------------------------------------------------------------------------

--- @class preload_level
--- @field size vector
--- @field positions table<string, vector>
--- @field entities table<string, preload_entity[]>
--- @field shadows grid<number>

--- @class preload_entity
--- @field position vector
--- @field identifier string
--- @field capture_name? string
--- @field args? string

local put_positions, put_shadows, put_entities, put_tiles

--- @param root table
--- @return preload_level
local preload = function(root)
  local start_t = love.timer.getTime()

  local total_offset = Vector.zero
  local total_size = Vector.zero
  for _, ldtk_level in ipairs(root.levels) do
    local offset = V(ldtk_level.worldX, ldtk_level.worldY):div_mut(-sprite.cell_size)
    total_offset = Vector.use(math.max, total_offset, offset)
    local size = V(ldtk_level.pxWid, ldtk_level.pxHei):div_mut(sprite.cell_size)
    total_size = Vector.use(math.max, total_size, offset + size)
  end

  local result = {
    size = total_size,
    positions = {},
    entities = {},
    shadows = Grid.new(total_size, function() return 0 end),
  }  --[[@as preload_level]]

  for _, ldtk_level in ipairs(root.levels) do
    local offset = V(ldtk_level.worldX, ldtk_level.worldY)
      :div_mut(sprite.cell_size)
      :add_mut(total_offset)
    local size = V(ldtk_level.pxWid, ldtk_level.pxHei)
      :div_mut(sprite.cell_size)

    local captures = Grid.new(size)  --[[@as grid<preload_capture>]]
    for _, layer in ipairs(ldtk_level.layerInstances) do
      if layer.__identifier == "positions" then
        put_positions(layer, offset, result.positions, captures)
      elseif layer.__identifier == "shadows" then
        put_shadows(layer, offset, result.shadows)
      elseif layer.__type == "Entities" then
        put_entities(layer, offset, captures, result.entities)
      elseif layer.__type == "Tiles" then
        put_tiles(layer, offset, captures, result.entities, false)
      elseif layer.__type == "IntGrid" then
        put_tiles(layer, offset, captures, result.entities, true)
      else
        Error("Unsupported layer type %s", layer.__type)
      end
    end

    if Table.count(captures._inner_array) > 0 then
      local missed_captures = Fun.pairs(captures._inner_array)
        :map(function(i, capture)
          return ("%s %s@%s"):format(
            capture.capture_name, capture.layer, V(captures:_get_outer_index(i))
          )
        end)
        :totable()
      Error("Entity capture misses: %s", table.concat(missed_captures, ", "))
    end
  end

  Log.info("%.2f s | Preloaded the level", love.timer.getTime() - start_t)
  return result
end

----------------------------------------------------------------------------------------------------
-- [SECTION] Implementation
----------------------------------------------------------------------------------------------------

--- @class preload_capture
--- @field capture_name string
--- @field layer string

--- @return string?
--- @return string?
local fields = function(instance, ...)
  local len = select("#", ...)
  assert(len <= 2)

  local r = {}
  for _, field in ipairs(instance.fieldInstances) do
    for i = 1, len do
      local requested_field = select(i, ...)
      if requested_field == field.__identifier then
        r[i] = field.__value
        break
      end
    end
  end

  return r[1], r[2]
end

local absolute_position = function(instance)
  return V(
    instance.__worldX / sprite.cell_size + 1,
    instance.__worldY / sprite.cell_size + 1
  )
end

local relative_position = function(instance)
  return Vector.own(instance.__grid):add_mut(Vector.one)
end

local tile_relative_position = function(instance)
  return Vector.own(instance.px):div_mut(sprite.cell_size):add_mut(Vector.one)
end

local insert_position = function(collection, capture_name, position)
  if collection[capture_name] then
    Error(
      "Name collision: positions %s and %s both have a capture_name %s",
      collection[capture_name], position, capture_name
    )
  end

  collection[capture_name] = position
end

--- @param layer table
--- @param offset vector
--- @param positions table<string, vector>
--- @param captures grid<preload_capture>
put_positions = function(layer, offset, positions, captures)
  local last_index = {}

  for _, instance in ipairs(layer.entityInstances) do
    if instance.__identifier == "position" then
      local position = relative_position(instance)
        :add_mut(offset)

      local capture_name = fields(instance, "capture_name")
      if capture_name == nil or capture_name == "" then
        Error("No capture_name for position %s", position)
      end

      insert_position(positions, capture_name, position)
    elseif instance.__identifier == "entity_capture" then
      local position = relative_position(instance)

      local capture_name, this_layer = fields(instance, "capture_name", "layer")
      if capture_name == nil or capture_name == "" then
        Error("No capture_name for entity_capture @local:%s", position)
      end  --- @cast capture_name string
      if this_layer == nil or this_layer == "" then
        Error("No layer for entity_capture @local:%s", position)
      end  --- @cast this_layer string

      captures[position] = {
        capture_name = capture_name,
        layer = this_layer,
      }
    elseif instance.__identifier:ends_with("_N") then
      local position = relative_position(instance)
        :add_mut(offset)
      local prefix = instance.__identifier:sub(1, -3)

      if not last_index[prefix] then
        local value = 0
        for name in pairs(positions) do
          if not name:starts_with(prefix .. "_") then goto continue end
          local n = tonumber(name:sub(#prefix + 2))
          if not n then goto continue end
          value = math.max(value, n)

          ::continue::
        end
        last_index[prefix] = value
      end

      local index = (last_index[prefix] or 0) + 1
      last_index[prefix] = index
      local capture_name = prefix .. "_" .. index

      insert_position(positions, capture_name, position)

      for _, field in ipairs(instance.fieldInstances) do
        if field.__identifier:starts_with("_") then
          if field.__type == "Point" then
            local subposition = V(field.__value.cx, field.__value.cy)
              :add_mut(offset)
              :add_mut(Vector.one)

            insert_position(positions, prefix .. field.__identifier .. "_" .. index, subposition)
          else
            Error(
              'Fields, starting with "_" in entities of layer "positions" are reserved for ' ..
              'generating positions and should be of type "Point", got type %q in %q instead',
              field.__type, field.__identifier
            )
          end
        end
      end
    else
      Error("Unknown position layer entity %q", instance.__identifier)
    end
  end
end

--- @param layer table
--- @param offset vector
--- @param shadows grid<number>
put_shadows = function(layer, offset, shadows)
  if layer.__type ~= "Tiles" then
    Error("Expected shadow layer to be of type \"tiles\"")
  end

  for _, instance in ipairs(layer.gridTiles) do
    local pos = tile_relative_position(instance)
    local intensity = 1 - instance.t / 10
    shadows[pos] = intensity
  end
end

--- @param identifier string
--- @return string
local parse_layer_name = function(identifier)
  for _, candidate in ipairs(level.grid_layers) do
    if identifier:starts_with(candidate) then
      return candidate
    end
  end
  Error("Layer name %s does not start with any known grid layer identifiers", identifier)
  return "solids"
end

--- @param captures grid<preload_capture>
--- @param entity preload_entity
--- @param layer string
local use_captures = function(captures, entity, layer)
  local capture = captures[entity.position]
  if capture and capture.layer == layer then
    if entity.capture_name then
      Error("Attempt to capture an entity as %q, when it already has capture_name %s",
        capture.capture_name, entity.capture_name)
    end
    entity.capture_name = capture.capture_name
    captures[entity.position] = nil
  end
end

--- @param layer table
--- @param offset vector
--- @param captures grid<preload_capture>
--- @param entities table<string, preload_entity[]>
put_entities = function(layer, offset, captures, entities)
  local layer_name = parse_layer_name(layer.__identifier)
  entities[layer_name] = entities[layer_name] or {}

  for _, instance in ipairs(layer.entityInstances) do
    local entity = {
      position = relative_position(instance),
      identifier = instance.__identifier,
    }

    entity.capture_name, entity.args = fields(instance, "capture_name", "args")

    use_captures(captures, entity, layer_name)
    entity.position:add_mut(offset)

    table.insert(entities[layer_name], entity)
  end
end

--- @param layer table
--- @param offset vector
--- @param captures grid<preload_capture>
--- @param entities table<string, preload_entity[]>
--- @param is_auto boolean
put_tiles = function(layer, offset, captures, entities, is_auto)
  local layer_name = parse_layer_name(layer.__identifier)
  entities[layer_name] = entities[layer_name] or {}

  for _, instance in ipairs(layer[is_auto and "autoLayerTiles" or "gridTiles"]) do
    local entity = {
      position = tile_relative_position(instance),
      identifier = instance.t + 1,
    }

    use_captures(captures, entity, layer_name)
    entity.position:add_mut(offset)

    table.insert(entities[layer_name], entity)
  end
end

Ldump.mark(preload, "const", ...)
return preload
