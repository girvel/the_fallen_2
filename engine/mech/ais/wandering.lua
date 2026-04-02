local tcod = require("engine.tech.tcod")
local tk = require("engine.mech.ais.tk")
local async = require("engine.tech.async")
local actions = require("engine.mech.actions")


local wandering = {}

--- @alias wandering_ai wandering_ai_strict|table

--- @class wandering_ai_strict: ai_strict
--- @field targeting ai_targeting
--- @field _frequency_k number
--- @field _target? entity
--- @field _hostility_sub function
--- @field _vision_map tcod_map
local methods = {}
wandering.mt = {__index = methods}

--- @type ai_targeting
local DEFAULT_TARGETING = {
  scan_period = .5,
  scan_range = 10,
  follow_range = 20,
  support_range = 0,
}

--- @param targeting? ai_targeting_optional
--- @param frequency_k? number
--- @return wandering_ai
wandering.new = function(frequency_k, targeting)
  return setmetatable({
    targeting = Table.defaults(targeting, DEFAULT_TARGETING),
    _frequency_k = frequency_k or 1,
  }, wandering.mt)
end

--- @param entity entity
methods.init = function(self, entity)
  self._hostility_sub = State.hostility:subscribe(function(attacker, target)
    if entity.faction and target.faction == entity.faction then
      local ai = entity.ai  --[[@as wandering_ai]]
      State.hostility:set(entity.faction, attacker.faction, "enemy")
      ai._target = attacker
      ai._control_coroutine = nil
    end
  end)
  self._vision_map = tcod.map(State.grids.solids)
end

--- @param entity entity
methods.deinit = function(self, entity)
  State.hostility:unsubscribe(self._hostility_sub)
  self._vision_map:free()
end

--- @param entity entity
--- @param dt number
methods.observe = function(self, entity, dt)
  if (not self._target or (self._target.position - entity.position):abs2() > self.targeting.follow_range)
    and State.period:absolute(self.targeting.scan_period, self, "target_scan")
  then
    self._target = tk.find_target(entity, self.targeting.scan_range, self._vision_map)
  end
end

--- @param entity entity
methods.control = function(self, entity)
  if self._target then
    while self._target and entity.resources.movement > 0 do
      local distance = 0
      local direction
      for _, d in ipairs(Vector.directions) do
        local p = entity.position + d
        if not State.grids.solids:slow_get(p, true) then
          local this_distance = (self._target.position - p):abs2()
          if this_distance > distance then
            distance = this_distance
            direction = d
          end
        end
      end
      if not direction then break end
      actions.move(direction):act(entity)
      async.sleep(.2)
    end
  else
    async.sleep(math.random(0.5, 7) / self._frequency_k)
    actions.move(Random.item(Vector.directions)):act(entity)
  end
end

Ldump.mark(wandering, {mt = "const"}, ...)
return wandering
