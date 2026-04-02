local tcod = require("engine.tech.tcod")
local sound    = require "engine.tech.sound"


local ai = {}

--- @class player_ai
--- @field finish_turn boolean?
--- @field _next_actions action[]
--- @field _action_promises promise[]
--- @field _vision_map tcod_map
local methods = {}
ai.mt = {__index = methods}

--- @return player_ai
ai.new = function()
  return setmetatable({
    finish_turn = nil,
    _next_actions = {},
    _action_promises = {},

    target = true,  -- a little hack for ally combat AI to follow the player when hesitant
  }, ai.mt)
end

methods.init = function(self, entity)
  self._vision_map = tcod.map(State.grids.solids)
end

methods.deinit = function(self, entity)
  self._vision_map:free()
end

local YOUR_TURN = sound.multiple("engine/assets/sounds/your_move", .2)

--- @param entity player
methods.control = function(self, entity)
  if State.combat then
    YOUR_TURN:play()
  end

  while true do
    for i, a in ipairs(self._next_actions) do
      local ok = a:act(entity)
      self._action_promises[i]:resolve(ok)
    end
    self._next_actions = {}
    self._action_promises = {}

    if not State.combat or self.finish_turn then break end
    coroutine.yield()
  end
  self.finish_turn = false
end

--- @param entity player
--- @param dt number
methods.observe = function(self, entity, dt)
  if not entity:can_act() then
    for _, p in ipairs(self._action_promises) do
      p:resolve(false)
    end
    self._next_actions = {}
    self._action_promises = {}
  end

  if State.combat and not Table.contains(State.combat.list, entity) then
    State:start_combat({entity})
  end
end

--- Puts the action into queue to be executed in :control
---
--- Promise resolves with false if can't act
--- @param action action
--- @return promise?
methods.plan_action = function(self, action)
  -- TODO maybe not needed, we've got State.runner now?
  local promise = Promise.new()
  table.insert(self._next_actions, action)
  table.insert(self._action_promises, promise)
  return promise
end

Ldump.mark(ai, {mt = "const"}, ...)
return ai
