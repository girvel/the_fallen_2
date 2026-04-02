local level = require "engine.tech.level"


--- @class generation_data
--- @field entities entity[]
--- @field runner_entities table<string, entity>
--- @field atlases table<string, love.Image>

--- @async
--- @param palette palette
--- @param preload_entities table<layer|string, preload_entity[]>
--- @return generation_data
local generate_entities = function(palette, preload_entities)
  local start_t = love.timer.getTime()
  local last_yield_t = start_t
  local result = {
    entities = {},
    runner_entities = {},
    atlases = {},
  }

  local counter = 0
  local layers_n = Table.count(preload_entities)

  for layer, stream in pairs(preload_entities) do
    counter = counter + 1
    if #stream == 0 then goto continue end

    local subpalette = palette[layer]
    if not subpalette then
      Error("No subpalette for layer %q", layer)
      goto continue
    end

    local is_visible = Table.contains(level.layers, layer)
    local is_grid_layer = is_visible and Table.contains(level.grid_layers, layer)

    if subpalette.ATLAS_IMAGE then
      if not is_grid_layer then
        Error("Layer %q is not a grid_layer, no ATLAS_IMAGE required", layer)
      end
      result.atlases[layer] = subpalette.ATLAS_IMAGE
    end

    for i = #stream, 1, -1 do
      local entry = stream[i]

      local factory = subpalette[entry.identifier]
      if not factory then
        Error("Missing entity factory %q in layer %q", entry.identifier, layer)
        goto continue_stream
      end

      local entity = factory(entry.args and Common.eval(entry.args))

      if entry.runner_name then
        if not entity then
          Error("Entity capture at %s@%s attempted, but factory returned no entity",
            layer, entry.position)
        else
          result.runner_entities[entry.runner_name] = entity
        end
      end

      if not entity then goto continue_stream end

      if entity.player_flag then
        State.player = entity
      end

      entity.position = entry.position
      if is_grid_layer then
        entity.grid_layer = layer
      elseif is_visible then
        entity.layer = layer
      end

      table.insert(result.entities, entity)

      if i % 100 == 0 and love.timer.getTime() - last_yield_t >= Constants.yield_period then
        coroutine.yield("generate", counter / layers_n)
        last_yield_t = love.timer.getTime()
      end

      ::continue_stream::
    end

    ::continue::
  end

  Log.info("%.2f s | Generated entities", love.timer.getTime() - start_t)
  return result
end

Ldump.mark(generate_entities, "const", ...)
return generate_entities
