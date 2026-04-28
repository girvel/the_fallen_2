local cutscene = {}

--- @class cutscene.characters_def
--- @field dynamic? boolean Does not trigger error if the character is missing (nil)
--- @field optional? boolean Allows the scene to run without this character

--- @alias cutscene cutscene_strict|table
--- @class cutscene_strict: scene_strict
--- @field _run fun(self: scene, ch: runner_characters, ps: runner_positions, ...): any
--- @field _condition? fun(self: scene, name: string, dt: number, ch: runner_characters, ps: runner_positions): boolean|any, ...
--- @field _on_add? fun(self: scene, ch: runner_characters, ps: runner_positions) runs when the scene is added
--- @field _on_cancel? fun(self: scene, ch: runner_characters, ps: runner_positions) runs when the scene run is cancelled (either through runner:stop or loading a save)
--- @field enabled? boolean
--- @field mode? "sequential"|"parallel"|"once"|"disable"
--- @field characters? table<string, cutscene.characters_def>
--- @field screenplay? string
--- @field boring_flag? true don't log scene beginning and ending
--- @field save_flag? true don't warn about making a save during this scene
--- @field in_combat_flag? true allows scene to start in combat
--- @field lag_flag? true hides coroutine lag warnings
local methods = {}
cutscene.mt = {__index = methods}

--- @param t cutscene
--- @return cutscene
cutscene.make = function(t)
  return setmetatable(t, cutscene.mt)
end

--- @param scene scene
--- @param scene_name string
--- @return boolean, runner_characters
local select_characters = function(scene, scene_name)
  local ok = true
  local characters = {}

  if scene.characters then
    for name, opts in pairs(scene.characters) do
      local e
      if opts.dynamic then
        e = rawget(State.runner.entities, name)
      else
        e = State.runner.entities[name]
      end

      if not opts.optional and not State:exists(e)
        or State.runner.locked_entities[e]
      then
        ok = false
      end

      characters[name] = e
    end
  end

  return ok, Table.strict(characters, ("scene %q's character"):format(scene_name))
end

--- @param scene scene
--- @param key string
--- @param ch runner_characters
local finish = function(scene, key, ch)
  for _, character in pairs(ch) do
    State.runner.locked_entities[character] = nil
  end

  if Table.key_of(ch, State.player) then
    State.camera.target_override = nil
    State.camera.is_camera_following = true
    State.player.curtain_color = Vector.transparent
  end
end

--- @param name string
--- @param dt number
--- @return boolean
--- @return ...
methods.condition = function(self, name, dt)
  local main_condition = (
    self.enabled
    -- NEXT move save_lock logic back into the runner
    and (not State.runner.save_lock or State.runner.save_lock == self or self.on_cancel)
    and (self.mode == "parallel" or not State.runner:is_running(self))
    and (self.in_combat_flag
      or not State.combat
      or not self.characters)
  )
  if not main_condition then
    return false
  end

  local ok, ch = select_characters(self, name)
  if not ok then return false end

  local condition_return
  if self._condition then
    condition_return = {self:_condition(name, dt, ch, State.runner.positions)}
    ok = table.remove(condition_return, 1)
  else
    condition_return = {}
    ok = true
  end

  if ok then
    -- done in condition to prevent the next condition possibly triggering
    for _, character in pairs(ch) do
      State.runner.locked_entities[character] = true
    end
  end
  return ok, ch, State.runner.positions, unpack(condition_return)
end

--- @param name string
--- @param ch runner_characters
--- @param ps runner_positions
methods.run = function(self, name, ch, ps, ...)
  if not self.mode or self.mode == "once" then
    State.runner:remove(self)
  elseif self.mode == "disable" then
    self.enabled = nil
  end
  if not self.boring_flag then
    Log.info("Scene %q starts", name)
  end
  self:_run(ch, ps, ...)
  finish(self, name, ch)
  if not self.boring_flag then
    Log.info("Scene %q ends", name)
  end
end

--- @param name string
methods.on_cancel = function(self, name)
  local _, ch = select_characters(self, name)
  if self._on_cancel then
    self:_on_cancel(ch, State.runner.positions)
  end
  finish(self, name, ch)
  if not self.boring_flag then
    Log.info("%s:on_cancel()", name)
  end
end

--- @param name string
methods.on_add = function(self, name)
  if Table.contains(Kernel.args.enable_scenes, name) then
    self.enabled = true
  end

  if Table.contains(Kernel.args.disable_scenes, name) then
    self.enabled = nil
  end
end

--- @param name string
methods.on_remove = function(self, name)
  if not self.boring_flag then
    Log.info("Removed scene %s", name)
  end
end

Ldump.mark(cutscene, {mt = "const"}, ...)
return cutscene
