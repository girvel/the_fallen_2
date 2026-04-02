local api = require("engine.tech.api")
local animated = require("engine.tech.animated")
local health = require("engine.mech.health")
local tcod = require("engine.tech.tcod")
local action = require("engine.tech.action")


local healing_word = {}

--- @class spells_healing_word: action
--- @field target entity
--- @field level integer
--- @field range integer
local methods = {}
healing_word.mt = {__index = methods}

--- @param level integer
--- @return spells_healing_word|table
healing_word.base = function(level)
  return Table.extend({
    name = "Лечащее слово",
    codename = "healing_word_" .. level,

    cost = {
      bonus_actions = 1,
      ["spell_slots_" .. level] = 1,
    },

    range = 40,
  }, action.base)
end

--- @param level integer
--- @param target entity
--- @return spells_healing_word
healing_word.new = function(level, target)
  return setmetatable(
    Table.extend({level = level, target = target}, healing_word.base(level)),
    healing_word.mt
  )
end

methods._is_available = function(self, entity)
  if not (self.target
    and self.target.hp
    and self.target.hp < self.target:get_max_hp())
  then return false end

  local result do
    local vision_map = tcod.map(State.grids.solids)
    vision_map:refresh_fov(entity.position, self.range)
    result = vision_map:is_visible_unsafe(unpack(self.target.position))
    vision_map:free()
  end

  return result
end

methods._act = function(self, entity)
  api.rotate(entity, self.target)
  entity:animate("gesture")
  health.heal(self.target, (D(4) * self.level + entity:get_modifier("wis")):roll())
  animated.add_fx("engine/assets/sprites/animations/healing_word_target", self.target.position)
  animated.add_fx("engine/assets/sprites/animations/healing_word_spell", entity.position)
  return true
end

Ldump.mark(healing_word, {mt = "const"}, ...)
return healing_word
