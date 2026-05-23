local state = require("engine.state")
local ui = require("engine.tech.ui")
local animated = require("engine.tech.animated")
local level    = require("engine.tech.level")
local sound    = require("engine.tech.sound")

local mode = {}

local STATES = {
  start_menu = require("engine.gui.start_menu"),
  game = require("engine.gui.game"),
  loading_screen = require("engine.gui.loading_screen"),
  escape_menu = require("engine.gui.escape_menu"),
  journal = require("engine.gui.journal"),
  save_menu = require("engine.gui.save_menu"),
  load_menu = require("engine.gui.load_menu"),
  death = require("engine.gui.death"),
  exit_confirmation = require("engine.gui.exit_confirmation"),
  ending = require("engine.gui.ending"),
  creator = require("engine.gui.creator"),
  warning = require("engine.gui.warning"),
  confirmation = require("engine.gui.confirmation"),
  appearance_editor = require("engine.gui.appearance_editor"),
}

local OPEN_JOURNAL = sound.multiple("engine/assets/sounds/open_journal", .3)
local CLOSE_JOURNAL = sound.multiple("engine/assets/sounds/close_journal", 1)

local empty_f = function() end

--- @class gui
--- @field _mode table
local methods = {}
mode.mt = {__index = methods}

methods._set_mode = function(self, mode_value)
  self._mode = mode_value

  -- TODO don't like this reassignment stuff
  for _, id in ipairs {"draw_gui", "draw_entity", "preprocess", "postprocess"} do
    self[id] = mode_value[id] and Ldump.ignore_upvalue_size(function(_, ...)
      return mode_value[id](mode_value, ...)
    end) or empty_f
  end

  if State and getmetatable(self._mode) ~= STATES.game.mt then
    State.camera.sidebar_w = 0
  end

  ui.reset_selection()
end

methods.draw_gui = function(self, dt)
  Error("No Kernel.gui._mode is set")
end

methods.draw_entity = function(self, entity, dt)
  Error("No Kernel.gui._mode is set")
end

methods.preprocess = function(self, dt)
  Error("No Kernel.gui._mode is set")
end

methods.postprocess = function(self, dt)
  Error("No Kernel.gui._mode is set")
end

methods.start_game = function(self)
  -- TODO switch modes between frames, not in the middle
  assert(self._mode.type == "start_menu")
  Log.info("Starting new game...")
  self:_set_mode(STATES.loading_screen.new(
    coroutine.create(function()
      State = state.new(assert(love.filesystem.load("engine/systems/init.lua"))())
      State:load_level("level")
    end),
    function() return self:start_game_finish() end
  ))
end

methods.start_game_finish = function(self)
  assert(self._mode.type == "loading_screen")
  Log.info("Game started")
  self:_set_mode(STATES.game.new())
  -- TODO .new() for states not needed, they should be static like draw_gui.lua, and history
  --   preserved here
end

--- @param kind "escape_menu"|"journal"|"creator"|"save_menu"|"load_menu"|"appearance_editor"
methods.open_menu = function(self, kind)
  Log.info("Opening %s", kind)
  if kind == "journal" or kind == "creator" then
    OPEN_JOURNAL:play()
  end
  self:_set_mode(STATES[kind].new(self._mode))
end

methods.close_menu = function(self)
  Log.info("Closing %s", self._mode.type)
  if self._mode.type == "journal" or self._mode.type == "creator" then
    CLOSE_JOURNAL:play()
  end
  self:_set_mode(assert(self._mode._prev))
end

methods.player_has_died = function(self)
  self:_set_mode(STATES.death.new())
  level.remove(State.player)
  State.player:rotate(Vector.left)
  animated.change_pack(State.player, "engine/assets/animations/skeleton")
end

methods.to_start_screen = function(self)
  assert(self._mode.type == "death" or self._mode.type == "ending")
  self:_set_mode(STATES.start_menu.new())
  State = (nil --[[@as state]])
end

methods.ending = function(self, is_good)
  self:_set_mode(STATES.ending.new(is_good))
end

--- @return boolean ok false if already in confirmation menu
methods.attempt_exit = function(self)
  if self._mode.type == "exit_confirmation" then
    return false
  end
  self:_set_mode(STATES.exit_confirmation.new(self._mode))
  return true
end

--- @param fmt string
--- @param ... any
methods.show_warning = function(self, fmt, ...)
  self:_set_mode(STATES.warning.new(self._mode, fmt:format(...)))
end

--- @param message string
--- @param f fun()
methods.confirm = function(self, message, f)
  self:_set_mode(STATES.confirmation.new(self._mode, message, f))
end

mode.new = function()
  local result = setmetatable({}, mode.mt)
  result:_set_mode(STATES.start_menu.new())
  return result
end

Ldump.mark(mode, {mt = "const"}, ...)
return mode
