local safety = require("engine.tech.safety")
local async = require("engine.tech.async")


local runner = {}

--- @alias runner_characters table<string, entity>
--- @alias runner_positions table<string, vector>
--- @alias runner_scenes table<string, scene>

--- @alias scene scene_strict|table
--- @class scene_strict
--- @field condition fun(self: scene, name: string, dt: number): boolean|any, ...
--- @field run fun(self: scene, name: string, ...): any
--- @field on_add? fun(self: scene, name: string) runs when the scene is added
--- @field on_cancel? fun(self: scene, name: string) runs when the scene run is cancelled (either through runner:stop or loading a save)

--- @class scene_run
--- @field coroutine thread
--- @field name string
--- @field base_scene scene

--- @class scene_cancellation
--- @field name string
--- @field base_scene scene

--- @class state_runner
--- @field scenes runner_scenes
--- @field positions table<string, vector>
--- @field entities table<string, entity>
--- @field locked_entities table<entity, true>
--- @field save_lock scene?
--- @field _scene_runs scene_run[]
--- @field _loading_cancellations? scene_cancellation[]
local methods = {}
runner.mt = {__index = methods}


--- @return state_runner
runner.new = function()
  return setmetatable({
    scenes = {},
    positions = Table.strict({}, "runner position"),
    entities = Table.strict({}, "runner entity"),
    _scene_runs = {},
    locked_entities = {},
  }, runner.mt)
end

local scene_run_mt = {}

--- @param dt number
methods.update = function(self, dt)
  for scene_name, scene in pairs(self.scenes) do
    local condition_return = {scene:condition(scene_name, dt)}
    local ok = table.remove(condition_return, 1)
    if ok then
      local run = {
        coroutine = coroutine.create(function()
          safety.call(scene.run, scene, scene_name, unpack(condition_return))
        end),
        base_scene = scene,
        name = scene_name,
      }
      setmetatable(run, scene_run_mt)
      table.insert(self._scene_runs, run)
    end
  end

  local to_remove = {}
  -- State.runner:stop may change _scene_runs
  local runs_copy = Table.shallow_copy(self._scene_runs)

  for _, run in ipairs(runs_copy) do
    async.resume(run.coroutine)

    if coroutine.status(run.coroutine) == "dead" then
      to_remove[run] = true
    end
  end

  -- can't use runs_copy anymore -- _scene_runs could be changed
  self._scene_runs = Fun.iter(self._scene_runs)
    :filter(function(run) return not to_remove[run] end)
    :totable()
end

--- @param scene string|scene
methods.is_running = function(self, scene)
  if type(scene) ~= "table" then
    scene = self.scenes[scene]
  end

  return Fun.iter(self._scene_runs)
    :any(function(r) return r.base_scene == scene end)
end

--- @param scene string|scene
--- @param hard? boolean prevent :on_cancel
--- @param silent? boolean
methods.cancel = function(self, scene, hard, silent)
  local name
  if type(scene) ~= "table" then
    name = scene
    scene = self.scenes[scene]
  end

  local next_runs = {}
  local cancelled_n = 0
  for _, run in ipairs(self._scene_runs) do
    if run.base_scene ~= scene then
      table.insert(next_runs, run)
    else
      cancelled_n = cancelled_n + 1
      name = name or run.name
      if not hard and run.base_scene.on_cancel then
        -- TODO enforce that :on_cancel should not be async?
        run.coroutine = coroutine.create(function()
          run.base_scene:on_cancel(run.name)
        end)
      end
    end
  end

  Log.info("%s runs | Cancelling %s", cancelled_n, name or "<non-existing scene>")
end

--- @param scenes runner_scenes
methods.extend = function(self, scenes)
  Table.extend_strict(self.scenes, scenes)
  local on_adds_repr = ""
  for name, scene in pairs(scenes) do
    if scene.on_add then
      -- TODO maybe run on_add during update?
      scene:on_add(name)
      on_adds_repr = on_adds_repr .. "\n  " .. name .. ":on_add()"
    end
  end

  Log.info("Added %s scenes%s", Table.count(scenes), on_adds_repr)
end

--- @param scene string|scene
methods.remove = function(self, scene)
  local key, scene_itself
  if type(scene) == "table" then
    key = Table.key_of(self.scenes, scene)
    scene_itself = scene
  else
    key = scene
    scene_itself = self.scenes[key]
  end

  if not key then return end
  self.scenes[key] = nil

  if not scene_itself.boring_flag then
    Log.info("Removed scene %s", key)
  end
end

--- @param f fun(scene, characters)
--- @param name? string
--- @return promise, scene
methods.run_task = function(self, f, name)
  local key = ("%s_%s"):format(name or "task", State.uid:next())

  local end_promise = Promise.new()
  local scene = {
    boring_flag = true,
    mode = "once",
    enabled = true,
    start_predicate = function() return true end,
    run = function(self_scene)
      f(self_scene)
      end_promise:resolve()
    end,
  }
  self.scenes[key] = scene
  return end_promise, scene
end

--- @param f fun(scene, characters)
--- @param name? string
--- @return promise, scene
methods.run_task_sync = function(self, f, name)
  local promise, scene = self:run_task(f, name)
  scene.on_cancel = f
  return promise, scene
end

methods.handle_loading = function(self)
  -- NOTICE: is done only when the whole state is deserialized
  for _, c in ipairs(self._loading_cancellations) do
    c.base_scene:on_cancel(c.name)
  end

  if #self._loading_cancellations > 0 then
    Log.info(
      "Scenes canceled on save:%s",
      Fun.iter(self._loading_cancellations)
        :reduce(function(acc, c) return acc .. "\n  " .. c.name end, "")
    )
  end

  self._loading_cancellations = nil
end

-- NEXT move to level
--- @param prefix string
--- @return string[]
methods.position_sequence = function(self, prefix)
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

  if #result == 0 then
    Error("No elements in position sequence %q", prefix)
  end

  if count ~= #result then
    Error("Hole in position sequence %q: %i is missing", prefix, #result + 1)
  end

  return result
end

--- @param self state_runner
runner.mt.__serialize = function(self)
  local scenes = self.scenes
  local positions = self.positions
  local entities = self.entities

  local cancellations = {}
  for _, run in ipairs(self._scene_runs) do
    local on_cancel = run.base_scene.on_cancel
    if on_cancel then
      table.insert(cancellations, {
        f = on_cancel,
        base_scene = run.base_scene,
        name = run.name,
      })
    elseif not run.base_scene.save_flag then
      Log.warn("Scene %s cancelled in save with no :on_cancel defined", run.name)
    end
  end

  return function()
    local result = setmetatable({
      scenes = scenes,
      positions = positions,
      entities = entities,
      _scene_runs = {},
      _loading_cancellations = cancellations,
      locked_entities = {},
    }, runner.mt)

    return result
  end
end

scene_run_mt.__serialize = function(self)
  return "nil"
end

Ldump.mark(runner, {mt = {}}, ...)
return runner
