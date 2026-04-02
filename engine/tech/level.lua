--- Module for level grid logic
local level = {}

--- @alias grid_layer "tiles"|"on_tiles"|"items"|"marks"|"solids"|"on_solids"|"shadows"
level.grid_layers = {
  "tiles",
  "on_tiles",
  "marks",
  "items",
  "solids",
  "on_solids",
  "shadows",
}

--- @alias layer "tiles"|"on_tiles"|"marks"|"fx_under"|"items"|"solids"|"fx_over"|"on_solids"|"weather"|"shadows"|"fx_over_shadows"
level.layers = {
  "tiles",
  "on_tiles",
  "marks",
  "items",
  "fx_under",
  "solids",
  "fx_over",
  "on_solids",
  "weather",
  "shadows",
  "fx_over_shadows",
}

--- @alias grid_positioned {position: vector, grid_layer: string}

--- Forcefully move entity to a new position
--- @param entity grid_positioned
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
--- @param entity grid_positioned
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
--- @param entity grid_positioned
--- @param new_grid_layer string
--- @return nil
level.change_grid_layer = function(entity, new_grid_layer)
  local grids = State.grids
  grids[entity.grid_layer][entity.position] = nil
  grids[new_grid_layer][entity.position] = entity
  entity.grid_layer = new_grid_layer
end

--- Put entity in its .position
--- @param entity grid_positioned
--- @return nil
level.put = function(entity)
  local grid = State.grids[entity.grid_layer]
  if not grid then
    Error("Invalid grid_layer %s", entity.grid_layer)
  end

  local prev = grid[entity.position]
  if prev == entity then return end

  if State.is_loaded and prev then
    Log.warn("Grid collision at %s[%s]: %s replaces %s",
      entity.grid_layer, entity.position, Name.code(entity), Name.code(grid[entity.position])
    )
  end

  grid[entity.position] = entity
end

--- Remove entity from its .position
--- @param entity grid_positioned
--- @return nil
level.remove = function(entity)
  State.grids[entity.grid_layer][entity.position] = nil
end

Ldump.mark(level, {}, ...)
return level
