--- Module for level grid logic
local level = {}

--- @alias grid_layer "tiles"|"on_tiles"|"items"|"marks"|"solids"|"on_solids"|"on2_solids"
level.grid_layers = {
  "tiles",
  "on_tiles",
  "marks",
  "items",
  "solids",
  "on_solids",
  "on2_solids",
}

for i, l1 in ipairs(level.grid_layers) do
  for j, l2 in ipairs(level.grid_layers) do
    if i ~= j and l1:starts_with(l2) then
      error(
        ("Grid layer id %q starts with grid layer id %q; may cause ambiguity in ldtk layer parsing")
          :format(l1, l2)
      )
    end
  end
end

--- @alias layer "tiles"|"on_tiles"|"marks"|"fx_under"|"items"|"solids"|"fx_over"|"on_solids"|"on2_solids"|"weather"|"shadows"|"fx_over_shadows"
level.layers = {
  "tiles",
  "on_tiles",
  "marks",
  "items",
  "fx_under",
  "solids",
  "fx_over",
  "on_solids",
  "on2_solids",
  "shadows",
  "fx_over_shadows",
  "weather",
}

do
  local missing = Fun.iter(level.grid_layers)
    :filter(function(l) return not Table.contains(level.layers, l) end)
    :totable()
  assert(#missing == 0, ("Grid layers %s not in level.layers"):format(Inspect(missing)))
end

--- Forcefully move entity to a new position
--- @param entity entity
--- @param position vector
--- @return boolean
level.unsafe_move = function(entity, position)
  assert(entity.position, "Can not move an entity without the current position")
  if entity.position == position then return false end

  local grid = State.grids[entity.grid_layer]
  if grid[position] then
    Log.warn("level.unsafe_move: replacing %s with %s", Name.code(grid[position]), Name.code(entity))
  end
  grid[entity.position] = nil
  grid[position] = entity
  entity.position = position
  return true
end

--- Safely move entity to a new position
--- @param entity entity
--- @param position vector
--- @return boolean # false if position is out of grid's bounds or the new position is occupied
level.slow_move = function(entity, position)
  local grid = State.grids[entity.grid_layer]
  if not grid:can_fit(position) or grid[position] then return false end
  level.unsafe_move(entity, position)
  return true
end

--- @param entity entity
--- @param target entity
level.switch_places = function(entity, target)
  State.grids[entity.grid_layer][entity.position] = target
  State.grids[target.grid_layer][target.position] = entity

  entity.position, target.position = target.position, entity.position
  entity.grid_layer, target.grid_layer = target.grid_layer, entity.grid_layer
end

--- Forcefully change entity's grid_layer
--- @param entity entity
--- @param new_grid_layer string
--- @return nil
level.change_grid_layer = function(entity, new_grid_layer)
  local grids = State.grids
  grids[entity.grid_layer][entity.position] = nil
  grids[new_grid_layer][entity.position] = entity
  entity.grid_layer = new_grid_layer
end

--- Put entity in its .position
--- @param entity entity
--- @return nil
level.put = function(entity)
  local grid = State.grids[entity.grid_layer]
  if not grid then
    Error("Invalid grid_layer %s", entity.grid_layer)
  end

  local prev = grid[entity.position]
  if prev then
    if prev == entity then return end
    if entity.bouncy_spawn_flag then
      entity.position = grid:find_free_position(entity.position) or entity.position
      prev = grid[entity.position]
    elseif State.is_loaded then
      Log.warn("Grid collision at %s[%s]: %s replaces %s",
        entity.grid_layer, entity.position, Name.code(entity), Name.code(grid[entity.position])
      )
    else
      State:remove(prev)
    end
  end

  grid[entity.position] = entity
end

--- Remove entity from its .position
--- @param entity entity
--- @return nil
level.remove = function(entity)
  if State.grids[entity.grid_layer]:slow_get(entity.position) ~= entity then return end
  State.grids[entity.grid_layer][entity.position] = nil
end

Ldump.mark(level, {}, ...)
return level
