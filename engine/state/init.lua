local shadow = require("engine.state.shadow")
local async = require("engine.tech.async")
local level = require("engine.tech.level")
local combat = require("engine.state.combat")
local ldtk = require("engine.tech.ldtk")
local tcod = require("engine.tech.tcod")
local sprite = require("engine.tech.sprite")


local state = {}

--- @class state
--- @field runner state_runner
--- @field camera state_camera
--- @field combat state_combat?
--- @field quests state_quests
--- @field hostility state_hostility
--- @field audio state_audio
--- @field period state_period
--- @field uid state_uid
--- @field stats state_stats
--- @field shadow state_shadow
--- @field shader shader?
--- @field rails rails
--- @field grids table<grid_layer, grid<entity>>
--- @field level level
--- @field player player
--- @field is_loaded boolean is level fully loaded
--- @field _world table
--- @field _entities table<entity, true>
--- @field _entities_to_add entity[]
--- @field _entities_to_remove [entity, boolean][]
--- @field _travel_map tcod_map
local methods = {}
state.mt = {__index = methods}

--- @param systems table[]
--- @return state
state.new = function(systems)
  return setmetatable({
    is_loaded = false,

    runner = require("engine.state.runner").new(),
    camera = require("engine.state.camera").new(),
    quests = require("engine.state.quests").new(),
    hostility = require("engine.state.hostility").new(),
    audio = require("engine.state.audio").new(),
    period = require("engine.state.period").new(),
    uid = require("engine.state.uid").new(),
    stats = require("engine.state.stats").new(),

    _world = Tiny.world(unpack(systems)),
    _entities = {},
    _entities_to_add = {},
    _entities_to_remove = {},
  }, state.mt)
end

--- Schedules entity to be added
--- @generic T: entity
--- @param self state
--- @param entity T
--- @param ... table extensions
--- @return T
methods.add = function(self, entity, ...)
  --- @cast entity entity

  Table.extend(entity, ...)
  table.insert(self._entities_to_add, entity)
  if entity.inventory then
    for _, it in pairs(entity.inventory) do
      self:add(it)
    end
  end
  return entity
end

--- Schedules entity to be added
--- @generic T: entity
--- @param self state
--- @param entity T
--- @param position vector
--- @param grid_layer grid_layer
--- @return T
methods.add_at = function(self, entity, position, grid_layer)
  --- @cast entity entity
  entity.position = position
  entity.grid_layer = grid_layer
  return self:add(entity)
end

--- Schedules entity to be removed
--- @generic T: entity
--- @param self state
--- @param entity T
--- @param silently? boolean
--- @return T
methods.remove = function(self, entity, silently)
  --- @cast entity entity
  table.insert(self._entities_to_remove, {entity, silently})
  return entity
end

--- @param entity entity?
--- @return boolean
methods.exists = function(self, entity)
  return not not self._entities[entity]
end

--- Removes & adds scheduled entities
methods.flush = function(self)
  for _, pair in ipairs(self._entities_to_remove) do
    local entity, silently = unpack(pair)
    if entity.on_remove then
      entity:on_remove()
    end

    if not silently and not entity.boring_flag then
      Log.debug("Removing %s", Name.code(entity))
    end

    self._world:remove(entity)
    self._entities[entity] = nil

    if entity.position and entity.grid_layer then
      level.remove(entity)
    end

    if entity.inventory then
      for _, item in pairs(entity.inventory) do
        self:remove(item, silently)
      end
    end

    if self.combat then
      self:remove_from_combat(entity)
    end
  end
  self._entities_to_remove = {}
  self._world:refresh()

  for _, entity in ipairs(self._entities_to_add) do
    self._world:add(entity)
    self._entities[entity] = true
    if entity.position and entity.grid_layer then
      level.put(entity)
    end
    if entity.on_add then
      entity:on_add()
    end
  end
  self._entities_to_add = {}
  self._world:refresh()
end

--- @async
--- @param path string
methods.load_level = function(self, path)
  -- :load_level is not part of .new, because entities being created during loading should
  -- still have access to State.runner, State.rails, State.level etc.

  async.lag_threshold = .5
  self.is_loaded = false
  Log.info("Loading level %s", path)
  local start_t = love.timer.getTime()

  local load_data = ldtk.load(path)
  local read_t = love.timer.getTime()
  local last_yield_t = read_t

  Log.info(
    "State.level:\n  grid_size: %s\n  captured positions: (%s)\n  captured entities: (%s)",
    load_data.level.grid_size,
    Table.count(load_data.level.positions),
    Table.count(load_data.level.entities)
  )
  self.level = load_data.level

  self.grids = Fun.iter(level.grid_layers)
    :map(function(layer) return layer, Grid.new(self.level.grid_size) end)
    :tomap()
  self.grids.solids = tcod.observer(self.grids.solids)
  self._travel_map = tcod.map(self.grids.solids)

  for layer, grid in pairs(self.grids) do
    self:add({
      codename = layer .. "_grid_container",
      sprite = sprite.grid(grid),
      layer = layer,
      position = Vector.zero,
    })
  end

  self.shadow = shadow.new(load_data.shadows)
  self:add(shadow.new_entity())

  for i, e in ipairs(load_data.entities) do
    e = self:add(e)
    if e.player_flag then self.player = e --[[@as player]] end

    if i % 500 == 0 and love.timer.getTime() - last_yield_t >= async.yield_period then
      coroutine.yield("add", i / #load_data.entities)
      last_yield_t = love.timer.getTime()
      self:flush()
    end
  end

  -- entities may continue to be created/removed during :on_add & :on_remove
  for _ = 1, 100 do
    if #self._entities_to_add + #self._entities_to_remove == 0 then break end
    self:flush()
  end

  if not self.player then
    Error("There's no player in the level")
  end

  self.camera:immediate_center()

  coroutine.yield("add", 1)
  local add_t = love.timer.getTime()
  Log.info("%.2f s | Added %s entities", add_t - read_t, #load_data.entities)

  self.rails = load_data.rails_new(Kernel.args.checkpoint)

  local end_t = love.timer.getTime()
  Log.info("%.2f s | Initialized rails", end_t - add_t)
  Log.info("%.2f s | (Total) Loaded the level", end_t - start_t)

  self.is_loaded = true
  async.lag_threshold = .1
end

--- @param list entity[]
methods.start_combat = function(self, list)
  list = Fun.iter(list)
    :filter(function(e) return not self:in_combat(e) and self:exists(e) end)
    :totable()

  if #list == 0 then return end

  self.runner:run_task_sync(function()
    list = Fun.iter(list)
      :filter(function(e) return not self:in_combat(e) and self:exists(e) end)
      :totable()
    if #list == 0 then return end

    local initiatives = {}
    for _, e in ipairs(list) do
      initiatives[e] = e:get_initiative_roll():roll()
    end

    table.sort(list, function(a, b) return initiatives[a] > initiatives[b] end)
    local repr = table.concat(Fun.iter(list):map(Name.code):totable(), ", ")

    for _, e in ipairs(list) do
      if e.ai then
        e.ai._control_coroutine = nil
      end
    end

    if State.combat then
      Log.info("Joining the combat: %s", repr)
      Table.concat(State.combat.list, list)
    else
      Log.info("--- Combat starts: %s ---", repr)
      State.combat = combat.new(list)
    end
  end, "start_combat")
end

--- @param entity entity
methods.remove_from_combat = function(self, entity)
  assert(self.combat)

  State.combat:remove(entity)
  if entity.ai then
    entity.ai._control_coroutine = nil
  end
end

--- @param entity entity
methods.in_combat = function(self, entity)
  return State.combat and Table.contains(State.combat.list, entity)
end

-- get_time is love.timer.getTime() - Kernel.load_level_moment + State._total_time

Ldump.mark(state, {mt = "const"}, ...)
return state
