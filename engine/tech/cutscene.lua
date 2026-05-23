local screenplay = require("engine.tech.screenplay")
local cutscene = {}

--- @class cutscene.characters_def
--- @field dynamic? boolean Does not trigger error if the character is missing (nil)
--- @field optional? boolean Allows the scene to run without this character

--- @alias cutscene cutscene_strict|table
--- @class cutscene_strict: scene_strict
--- @field _run fun(self: scene, ch: ch, ps: ps, sp?: screenplay, ...): any
--- @field _condition? fun(self: scene, dt: number, ch: ch, ps: ps): boolean|any, ...
--- @field _on_add? fun(self: scene, ch: ch, ps: ps) runs when the scene is added
--- @field _on_cancel? fun(self: scene, ch: ch, ps: ps) runs when the scene run is cancelled (either through runner:stop or loading a save)
--- @field enabled? boolean
--- @field mode? "sequential"|"parallel"|"once"|"disable"
--- @field characters? table<string, cutscene.characters_def>
--- @field screenplay? string a path to screenplay
--- @field boring_flag? true don't log scene beginning and ending
--- @field in_combat_flag? true allows scene to start in combat
--- @field lag_flag? true hides coroutine lag warnings
local methods = {}
cutscene.mt = {__index = methods}

--- @param t cutscene
--- @return cutscene
cutscene.make = function(t)
  if t.screenplay and not love.filesystem.getInfo(t.screenplay) then
    Error("Missing screenplay file at %s", t.screenplay)
  end
  return setmetatable(t, cutscene.mt)
end

--- @param scene scene
--- @param scene_name string
--- @return boolean, ch
local select_characters = function(scene, scene_name)
  local ok = true
  local characters = {}

  if scene.characters then
    for name, opts in pairs(scene.characters) do
      local e
      if opts.dynamic then
        e = rawget(State.level.entities, name)
      else
        e = State.level.entities[name]
      end

      if not opts.optional and not State:exists(e)
        or State.level.locked_entities[e]
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
--- @param ch ch
local finish = function(scene, key, ch)
  for _, character in pairs(ch) do
    State.level.locked_entities[character] = nil
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
    condition_return = {self:_condition(dt, ch, State.level.positions)}
    ok = table.remove(condition_return, 1)
  else
    condition_return = {}
    ok = true
  end

  if ok then
    -- done in condition to prevent the next condition possibly triggering
    for _, character in pairs(ch) do
      State.level.locked_entities[character] = true
    end
  end
  return ok, ch, State.level.positions, unpack(condition_return)
end

--- @param name string
--- @param ch ch
--- @param ps ps
methods.run = function(self, name, ch, ps, ...)
  if not self.boring_flag then
    Log.info("Scene %q starts", name)
  end

  if not self.mode or self.mode == "once" then
    State.runner:remove(self)
  elseif self.mode == "disable" then
    self.enabled = nil
  end

  local sp
  if self.screenplay then
    sp = screenplay.new(self.screenplay, ch)
  end
  self:_run(ch, ps, sp, ...)
  if sp then
    sp:finish()
  end
  finish(self, name, ch)

  if not self.boring_flag then
    Log.info("Scene %q ends", name)
  end
end

--- @param name string
methods.on_cancel = function(self, name)
  local _, ch = select_characters(self, name)
  if self._on_cancel then
    self:_on_cancel(ch, State.level.positions)
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

  if self._on_add then
    local _, ch = select_characters(self, name)
    self:_on_add(ch, State.level.positions)
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
