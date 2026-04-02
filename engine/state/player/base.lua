local ai = require("engine.state.player.ai")
local action = require("engine.tech.action")
local creature = require "engine.mech.creature"


local base = {}

--- @class base_player: entity_strict
--- @field fov_r integer
--- @field ai player_ai
--- @field bag table<string, integer>
--- @field hears? dialogue_line
--- @field speaks? integer
--- @field notification? string
--- @field curtain_color vector
--- @field memory love.Canvas
--- @field is_memory_enabled boolean
--- @field is_blind boolean
--- @field is_deaf boolean
--- @field creator_model table?

--- @alias dialogue_line plain_dialogue_line | dialogue_options

--- @class plain_dialogue_line
--- @field type "plain_line"
--- @field source entity?
--- @field text string

--- @class dialogue_options
--- @field type "options"
--- @field options table<integer, string>

base.mixin = function()
  local result = Table.extend(creature.mixin(), {
    codename = "player",
    player_flag = true,
    fov_r = 16,
    curtain_color = Vector.transparent,
    bag = {money = 0},

    ai = ai.new(),
    immovable_flag = true,

    is_memory_enabled = true,
    is_blind = false,
    is_deaf = false,
    on_add = function(self)
      self.memory = love.graphics.newCanvas(unpack(
        State.level.grid_size * Constants.cell_size * State.camera.SCALE
      ))
    end,

    creator_model = nil,
  })

  return result
end

--- @type action
base.skip_turn = Table.extend({
  name = "Завершить ход",
  codename = "skip_turn",

  _is_available = function(self, entity)
    return State.combat and State.combat:get_current() == entity
  end,
  _act = function(self, entity)
    entity.ai.finish_turn = true
    return true
  end,
}, action.base)

Ldump.mark(base, {}, ...)
return base
