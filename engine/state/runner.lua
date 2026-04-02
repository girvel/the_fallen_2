local safety = require("engine.tech.safety")
local async = require("engine.tech.async")


local runner = {}

--- @alias runner_characters table<string, entity>
--- @alias runner_positions table<string, vector>
--- @alias runner_scenes table<string, scene>

--- @alias scene scene_strict|table

--- @class character_options
--- @field dynamic? boolean Does not trigger error if the character is missing (nil)
--- @field optional? boolean Allows the scene to run without this character

--- @class scene_strict
--- @field characters? table<string, character_options>
--- @field start_predicate fun(self: scene, dt: number, ch: runner_characters, ps: runner_positions): boolean|any, ...
--- @field run fun(self: scene, ch: runner_characters, ps: runner_positions, ...): any
--- @field enabled? boolean
--- @field mode? "sequential"|"parallel"|"once"|"disable"
--- @field boring_flag? true don't log scene beginning and ending
--- @field save_flag? true don't warn about making a save during this scene
--- @field in_combat_flag? true allows scene to start in combat
--- @field lag_flag? true hides coroutine lag warnings
--- @field on_add? fun(self: scene, ch: runner_characters, ps: runner_positions) runs when the scene is added
--- @field on_cancel? fun(self: scene, ch: runner_characters, ps: runner_positions) runs when the scene run is cancelled (either through runner:stop or loading a save)

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

--- @param self state_runner
--- @param scene scene
--- @param scene_name string
--- @return boolean, runner_characters
local select_characters = function(self, scene, scene_name)
  local ok = true
  local characters = {}

  if scene.characters then
    for name, opts in pairs(scene.characters) do
      local e
      if opts.dynamic then
        e = rawget(self.entities, name)
      else
        e = self.entities[name]
      end

      if not opts.optional and not State:exists(e)
        or self.locked_entities[e]
      then
        ok = false
      end

      characters[name] = e
    end
  end

  return ok, Table.strict(characters, ("scene %q's character"):format(scene_name))
end

--- @param self state_runner
--- @param scene scene
--- @param key string
--- @param ch runner_characters
local finish = function(self, scene, key, ch)
  for _, character in pairs(ch) do
    self.locked_entities[character] = nil
  end

  if Table.key_of(ch, State.player) then
    State.camera.target_override = nil
    State.camera.is_camera_following = true
    State.player.curtain_color = Vector.transparent
  end
end

--- @param dt number
methods.update = function(self, dt)
  for scene_name, scene in pairs(self.scenes) do
    if not (scene.enabled
      and (not self.save_lock or self.save_lock == scene or scene.on_cancel)
      and (scene.mode == "parallel" or not self:is_running(scene))
      and (scene.in_combat_flag
        or not State.combat
        or not scene.characters
        or Table.count(scene.characters) == 0))
    then
      goto continue
    end

    local ok, ch = select_characters(self, scene, scene_name)
    if not ok then goto continue end

    local args = {scene:start_predicate(dt, ch, self.positions)}
    local ok = table.remove(args, 1)
    if not ok then goto continue end

    -- outside coroutine to avoid two scenes with the same character starting in the same frame
    for _, character in pairs(ch) do
      self.locked_entities[character] = true
    end

    table.insert(self._scene_runs, setmetatable({
      coroutine = coroutine.create(function()
        if not scene.mode or scene.mode == "once" then
          State.runner:remove(scene)
        elseif scene.mode == "disable" then
          scene.enabled = nil
        end

        if not scene.boring_flag then
          Log.info("Scene %q starts", scene_name)
        end

        safety.call(scene.run, scene, ch, self.positions, unpack(args))
        finish(self, scene, scene_name, ch)

        if not scene.boring_flag then
          Log.info("Scene %q ends", scene_name)
        end
      end),
      base_scene = scene,
      name = scene_name,
    }, scene_run_mt))

    ::continue::
  end

  local to_remove = {}
  local runs_copy = Table.shallow_copy(self._scene_runs)
  -- State.runner:stop may change this collection

  for _, run in ipairs(runs_copy) do
    async.resume(run.coroutine)

    if coroutine.status(run.coroutine) == "dead" then
      to_remove[run] = true
    end
  end

  -- can't use runs_copy anymore -- could be changed
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
methods.stop = function(self, scene, hard, silent)
  local key
  if type(scene) ~= "table" then
    key = scene
    scene = self.scenes[scene]
  else
    key = Table.key_of(self.scenes, scene)
  end

  local old_length = #self._scene_runs

  self._scene_runs = Fun.iter(self._scene_runs)
    :filter(function(r)
      if r.base_scene ~= scene then
        return true
      end
      key = key or r.name
      return false
    end)
    :totable()

  local new_length = #self._scene_runs

  local did_on_cancel_run = false
  if new_length ~= old_length then
    self:run_task_sync(function()
      local _, ch = select_characters(self, scene, key)
      finish(self, scene, key, ch)

      if scene.on_cancel then
        did_on_cancel_run = true
        if not hard then
          local _, characters = select_characters(self, scene, key)
          scene:on_cancel(characters, State.runner.positions)
        end
      end

      local postfix = ""
      if did_on_cancel_run then
        if hard then
          postfix = "; prevented :on_cancel"
        else
          postfix = "; used :on_cancel"
        end
      end

      if not silent then
        Log.info("Stopping scene %s; interrupted %s runs%s", key or Inspect(scene), old_length - new_length, postfix)
      end
    end)
  else
    if not silent then
      Log.info("Stopping scene %s; no runs found", key)
    end
  end
end

--- @param scenes runner_scenes
methods.add = function(self, scenes)
  Table.extend_strict(self.scenes, scenes)
  local on_adds_repr = ""
  for name, scene in pairs(scenes) do
    if scene.on_add then
      scene:on_add(self.entities, self.positions)
      on_adds_repr = on_adds_repr .. "\n  " .. name .. ":on_add()"
    end

    if Table.contains(Kernel.args.enable_scenes, name) then
      scene.enabled = true
    end

    if Table.contains(Kernel.args.disable_scenes, name) then
      scene.enabled = nil
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
    local _, ch = select_characters(self, c.base_scene, c.name)
    c.base_scene:on_cancel(ch, self.positions)
    finish(self, c.base_scene, c.name, ch)
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
