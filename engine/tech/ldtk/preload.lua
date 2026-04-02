----------------------------------------------------------------------------------------------------
-- [SECTION] External API
----------------------------------------------------------------------------------------------------

--- @class preload_level
--- @field size vector
--- @field positions table<string, vector>
--- @field entities table<string, preload_entity[]>

--- @class preload_entity
--- @field position vector
--- @field identifier string
--- @field runner_name? string
--- @field args? string

local put_positions, put_entities, put_tiles

--- @param root table
--- @return preload_level
local preload = function(root)
  local start_t = love.timer.getTime()
  local result = {
    size = Vector.zero,
    positions = {},
    entities = {},
  }  --[[@as preload_level]]

  for _, ldtk_level in ipairs(root.levels) do
    local offset = V(ldtk_level.worldX, ldtk_level.worldY) / Constants.cell_size
    local size   = V(ldtk_level.pxWid,  ldtk_level.pxHei)  / Constants.cell_size
    result.size = Vector.use(math.max, result.size, offset + size)

    local captures = Grid.new(size)  --[[@as grid<preload_capture>]]
    for _, layer in ipairs(ldtk_level.layerInstances) do
      if layer.__identifier == "positions" then
        put_positions(layer, offset, result.positions, captures)
        goto continue
      end

      if layer.__type == "Entities" then
        put_entities(layer, offset, captures, result.entities)
      elseif layer.__type == "Tiles" then
        put_tiles(layer, offset, captures, result.entities, false)
      elseif layer.__type == "IntGrid" then
        put_tiles(layer, offset, captures, result.entities, true)
      else
        Error("Unsupported error type %s", layer.__type)
      end

      ::continue::
    end

    if Table.count(captures._inner_array) > 0 then
      local missed_captures = Fun.pairs(captures._inner_array)
        :map(function(i, capture)
          return ("%s %s@%s"):format(
            capture.runner_name, capture.layer, V(captures:_get_outer_index(i))
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
--- @field runner_name string
--- @field layer string

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
    instance.__worldX / Constants.cell_size + 1,
    instance.__worldY / Constants.cell_size + 1
  )
end

local relative_position = function(instance)
  return Vector.own(instance.__grid):add_mut(Vector.one)
end

local tile_relative_position = function(instance)
  return Vector.own(instance.px):div_mut(Constants.cell_size):add_mut(Vector.one)
end

local insert_position = function(collection, runner_name, position)
  if collection[runner_name] then
    Error(
      "Name collision: positions %s and %s both have a runner_name %s",
      collection[runner_name], position, runner_name
    )
  end

  collection[runner_name] = position
end

--- @param layer table
--- @param offset vector
--- @param positions table<string, vector>
--- @param captures grid<preload_capture>
put_positions = function(layer, offset, positions, captures)
  local last_index = {}

  for _, instance in ipairs(layer.entityInstances) do
    if instance.__identifier == "position" then
      local position = absolute_position(instance)

      local runner_name = fields(instance, "runner_name")
      if runner_name == nil or runner_name == "" then
        Error("No runner_name for position %s", position)
      end

      insert_position(positions, runner_name, position)
    elseif instance.__identifier == "entity_capture" then
      local position = relative_position(instance)

      local runner_name, this_layer = fields(instance, "runner_name", "layer")
      if runner_name == nil or runner_name == "" then
        Error("No runner_name for entity_capture @local:%s", position)
      end
      if this_layer == nil or this_layer == "" then
        Error("No layer for entity_capture @local:%s", position)
      end

      captures[position] = {
        runner_name = runner_name,
        layer = this_layer,
      }
    elseif instance.__identifier:ends_with("_N") then
      local position = absolute_position(instance)
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
      local runner_name = prefix .. "_" .. index

      insert_position(positions, runner_name, position)

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

--- @param captures grid<preload_capture>
--- @param entity preload_entity
--- @param layer string
local use_captures = function(captures, entity, layer)
  local capture = captures[entity.position]
  if capture and capture.layer == layer then
    if entity.runner_name then
      Error("Attempt to capture an entity as %q, when it already has runner_name %s",
        capture.runner_name, entity.runner_name)
    end
    entity.runner_name = capture.runner_name
    captures[entity.position] = nil
  end
end

--- @param layer table
--- @param offset vector
--- @param captures grid<preload_capture>
--- @param entities table<string, preload_entity[]>
put_entities = function(layer, offset, captures, entities)
  local layer_name do
    layer_name = layer.__identifier
    local PREFIX = "_entities"
    if not layer_name:ends_with(PREFIX) then
      Error("Expected Entities layer identfier to end with %q, got %q", PREFIX, layer_name)
    else
      layer_name = layer_name:sub(1, -#PREFIX - 1)
    end
  end

  entities[layer_name] = entities[layer_name] or {}

  for _, instance in ipairs(layer.entityInstances) do
    local entity = {
      position = relative_position(instance),
      identifier = instance.__identifier,
    }

    entity.runner_name, entity.args = fields(instance, "runner_name", "args")

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
  local layer_name do
    layer_name = layer.__identifier
    if is_auto then
      local PREFIX = "_auto"
      if not layer_name:ends_with(PREFIX) then
        Error("Expected IntGrid layer identfier to end with %q, got %q", PREFIX, layer_name)
      else
        layer_name = layer_name:sub(1, -#PREFIX - 1)
      end
    end
  end

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
