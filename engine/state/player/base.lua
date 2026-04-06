local sprite = require("engine.tech.sprite")
local abilities = require("engine.mech.abilities")
local ai = require("engine.state.player.ai")
local action = require("engine.tech.action")
local creature = require "engine.mech.creature"


local base = {}

--- @class player_base: entity_strict
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

--- @param entity table
base.mix_in = function(entity)
  creature.mix_in(entity)
  entity.codename = "player"
  entity.player_flag = true
  entity.fov_r = 16
  entity.curtain_color = Vector.transparent
  entity.bag = {money = 0}

  entity.ai = ai.new()
  entity.immovable_flag = true

  entity.is_memory_enabled = true
  entity.is_blind = false
  entity.is_deaf = false
  entity.on_add = function(self)
    self.memory = love.graphics.newCanvas(unpack(
      State.level.grid_size * sprite.cell_size * State.camera.SCALE
    ))
  end

  entity.creator_model = nil
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
