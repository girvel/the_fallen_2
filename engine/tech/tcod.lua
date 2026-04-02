local ffi = require("ffi")
local ffi_fix = require("engine.tech.ffi_fix")


local tcod = {}


----------------------------------------------------------------------------------------------------
-- [SECTION] C backend
----------------------------------------------------------------------------------------------------

ffi.cdef([[
  typedef enum {
    FOV_BASIC,
    FOV_DIAMOND,
    FOV_SHADOW,
    FOV_PERMISSIVE_0,FOV_PERMISSIVE_1,FOV_PERMISSIVE_2,FOV_PERMISSIVE_3,
    FOV_PERMISSIVE_4,FOV_PERMISSIVE_5,FOV_PERMISSIVE_6,FOV_PERMISSIVE_7,FOV_PERMISSIVE_8,
    FOV_RESTRICTIVE,
    NB_FOV_ALGORITHMS
  } TCOD_fov_algorithm_t;

  struct TCOD_Map *TCOD_map_new(int width, int height);
  void TCOD_map_clear(struct TCOD_Map *map, bool transparent, bool walkable);
  void TCOD_map_copy(struct TCOD_Map *source, struct TCOD_Map *dest);
  void TCOD_map_delete(struct TCOD_Map *map);

  void TCOD_map_set_properties(
    struct TCOD_Map *map, int x, int y, bool is_transparent, bool is_walkable
  );

  void TCOD_map_compute_fov(
    struct TCOD_Map *map, int player_x, int player_y, int max_radius, bool light_walls,
    TCOD_fov_algorithm_t algo
  );

  bool TCOD_map_is_transparent(struct TCOD_Map *map, int x, int y);
  bool TCOD_map_is_walkable(struct TCOD_Map *map, int x, int y);
  bool TCOD_map_is_in_fov(struct TCOD_Map *map, int x, int y);

  // struct TCOD_Dijkstra *TCOD_dijkstra_new(struct TCOD_Map *map, float diagonalCost);
  // void TCOD_dijkstra_delete(TCOD_Dijkstra *dijkstra);

  struct TCOD_Path *TCOD_path_new_using_map(struct TCOD_Map *map, float diagonalCost);
  void TCOD_path_delete(struct TCOD_Path *path);

  bool TCOD_path_compute(struct TCOD_Path *path, int ox, int oy, int dx, int dy);
  int TCOD_path_size(struct TCOD_Path *path);
  void TCOD_path_get(struct TCOD_Path *path, int index, int *x, int *y);
]])

tcod._c = ffi_fix.load("libtcod")
tcod.ok = not not tcod._c


----------------------------------------------------------------------------------------------------
-- [SECTION] Observer
----------------------------------------------------------------------------------------------------

--- @class tcod_observer
--- @field _maps table<tcod_map, true>
--- @field _grid grid<any>

tcod.observer_mt = {}

--- @param self tcod_observer
tcod.observer_mt.__index = function(self, index)
  return self._grid[index]
end

--- @param self tcod_observer
tcod.observer_mt.__newindex = function(self, index, value)
  self._grid[index] = value
  local x, y = unpack(index)

  for map in pairs(self._maps) do
    tcod._c.TCOD_map_set_properties(
      map._map, x - 1, y - 1,
      not value or not not value.transparent_flag, not value
    )
  end
end

--- To be called on empty grid
--- @generic T
--- @param grid T
--- @return T
tcod.observer = function(grid)
  --- @cast grid grid
  local result = setmetatable({
    _maps = setmetatable({}, {__mode = "k"}),
    _grid = grid,
  }, tcod.observer_mt)

  tcod.update_transparency(result)
  return result
end

--- @param grid grid<any>
tcod.update_transparency = function(grid)
  --- @diagnostic disable-next-line
  --- @cast grid tcod_observer

  for map in pairs(grid._maps) do
    map:update_transparency()
  end
end

----------------------------------------------------------------------------------------------------
-- [SECTION] Map
----------------------------------------------------------------------------------------------------

--- @class tcod_map
--- @field _map any
--- @field _parent tcod_observer
--- @field _fov_center vector
--- @field _fov_r integer
local map_methods = {}
tcod.map_mt = {__index = map_methods}

--- @param grid grid Actually, not grid but a tcod.observer
--- @return tcod_map
tcod.map = function(grid)
  --- @diagnostic disable-next-line
  --- @cast grid tcod_observer

  local result = setmetatable({
    _map = tcod._c.TCOD_map_new(unpack(grid._grid.size)),
    _parent = grid,
  }, tcod.map_mt)

  local first_map = next(grid._maps)
  if first_map == nil then
    result:update_transparency()
  else
    tcod._c.TCOD_map_copy(first_map._map, result._map)
  end

  grid._maps[result] = true
  return result
end

--- @param self tcod_map
local assert_is_not_freed = function(self)
  if self._map == nil then
    Error("Attempt to use tcod.map after free")
  end
end

map_methods.free = function(self)
  assert_is_not_freed(self)

  tcod._c.TCOD_map_delete(self._map)
  self._map = nil
  self._parent._maps[self] = nil
end

map_methods.update_transparency = function(self)
  assert_is_not_freed(self)

  local grid = self._parent._grid
  local w, h = unpack(grid.size)

  for x = 1, w do
    for y = 1, h do
      local e = grid:unsafe_get(x, y)
      tcod._c.TCOD_map_set_properties(
        self._map, x - 1, y - 1, not e or not not e.transparent_flag, not e
      )
    end
  end
end

--- @param position vector
--- @param r integer
map_methods.refresh_fov = function(self, position, r)
  assert_is_not_freed(self)

  self._fov_center = position
  self._fov_r = r

  local px, py = unpack(position)
  tcod._c.TCOD_map_compute_fov(
    self._map, px - 1, py - 1, r, true, tcod._c.FOV_PERMISSIVE_8
  )
end

--- @param x integer
--- @param y integer
--- @return boolean
map_methods.is_visible_unsafe = function(self, x, y)
  assert_is_not_freed(self)

  return tcod._c.TCOD_map_is_in_fov(self._map, x - 1, y - 1)
end

--- @param x integer
--- @param y integer
--- @return boolean
map_methods.is_transparent_unsafe = function(self, x, y)
  assert_is_not_freed(self)

  return tcod._c.TCOD_map_is_transparent(self._map, x - 1, y - 1)
end

--- @param origin vector
--- @param destination vector
--- @return vector[]
map_methods.find_path = function(self, origin, destination)
  assert_is_not_freed(self)

  if not self._parent._grid:can_fit(origin) then
    Error("find_path origin %s is out of grid borders", origin)
  end

  if not self._parent._grid:can_fit(destination) then
    Error("find_path destination %s is out of grid borders", origin)
  end

  local raw_path = tcod._c.TCOD_path_new_using_map(self._map, 0)
  local ox, oy = unpack(origin - Vector.one)
  local dx, dy = unpack(destination - Vector.one)
  tcod._c.TCOD_path_compute(raw_path, ox, oy, dx, dy)

  local result = {}
  for i = 0, tcod._c.TCOD_path_size(raw_path) - 1 do
    local xp = ffi.new("int[1]")
    local yp = ffi.new("int[1]")
    tcod._c.TCOD_path_get(raw_path, i, xp, yp)
    table.insert(result, V(xp[0], yp[0]) + Vector.one)
  end
  tcod._c.TCOD_path_delete(raw_path)

  return result
end

----------------------------------------------------------------------------------------------------
-- [SECTION] Serialization
----------------------------------------------------------------------------------------------------

-- Serialization order is important. tcod_map is deserialized partially (when deserialized by
-- itself), and tcod_observer sets all the references & initializes the C maps.
--
-- See girvel/engine#78.

--- @param self tcod_map
tcod.map_mt.__serialize = function(self)
  local fov_center = self._fov_center
  local fov_r = self._fov_r

  return function()
    return setmetatable({
      _fov_center = fov_center,
      _fov_r = fov_r,
    }, tcod.map_mt)
  end
end

--- @param self tcod_observer
tcod.observer_mt.__serialize = function(self)
  local grid = self._grid
  local maps = self._maps

  return function()
    local result = tcod.observer(grid)
    result._maps = maps  --- @diagnostic disable-line:inject-field
    for map in pairs(maps) do
      map._parent = result
      map._map = tcod._c.TCOD_map_new(unpack(grid.size))
    end

    tcod.update_transparency(result)
    for map in pairs(maps) do
      if map._fov_center then
        map:refresh_fov(map._fov_center, map._fov_r)
      end
    end

    return result
  end
end

Ldump.mark(tcod, {}, ...)
return tcod
