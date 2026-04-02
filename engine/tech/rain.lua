local sound = require("engine.tech.sound")
local animated = require("engine.tech.animated")
local api = require("engine.tech.api")


local rain = {}

--- @alias rain rain_strict|table
--- @class rain_strict: entity_strict
--- @field _rain_state rain_state
--- @field rain_density number
--- @field rain_speed number

--- @class rain_state
--- @field _particles particle[]
--- @field _player_position vector
--- @field _canvas love.Canvas
--- @field _sound sound
--- @field _touched_ground boolean

--- @class particle
--- @field position vector in pixels (before scaling)
--- @field target_cell vector
--- @field life_time number
--- @field is_visible boolean

local sounds = {
  light = sound.new("engine/assets/sounds/rain_light.mp3", .6),
  heavy = sound.new("engine/assets/sounds/rain_heavy.mp3", .2),
}

--- @param density number
--- @param speed number
--- @return rain
rain.new = function(density, speed)
  return {
    codename = "rain_emitter",
    position = Vector.one,
    layer = "weather",
    sprite = {
      type = "rendered",
      render = rain.render,
    },

    rain_density = density,
    rain_speed = speed,
    _rain_state = {
      _particles = {},
      _player_position = nil,
      _canvas = love.graphics.newCanvas(unpack(State.level.grid_size * Constants.cell_size)),
      _touched_ground = false,
    },
  }
end

local BUFFER_K = 2
local DIRECTION = V(1, 1):normalized_mut()
local IMAGE = love.graphics.newImage("assets/sprites/standalone/rain_particle.png")

--- @param self sprite_rendered
--- @param entity rain
--- @param dt number
--- @return love.Canvas
rain.render = function(self, entity, dt)
  dt = math.min(1, dt)
  local state = entity._rain_state

  if entity.rain_density >= 1 then
    if state._sound ~= sounds.heavy then
      if state._sound then state._sound:stop() end
      state._sound = sounds.heavy
    end
  else
    if state._sound ~= sounds.light then
      if state._sound then state._sound:stop() end
      state._sound = sounds.light
    end
  end

  if state._touched_ground and not state._sound.source:isPlaying() then
    state._sound:play()
  end

  local start, finish do
    local original_start = State.camera.vision_start * Constants.cell_size
    local original_finish = (State.camera.vision_end + Vector.one) * Constants.cell_size

    local d = (original_finish - original_start)
    start = original_finish - d * BUFFER_K
    finish = original_start + d * BUFFER_K
  end

  local d, cells_n do
    local w, h = unpack(finish - start)
    d = math.max(w, h)
    cells_n = w * h / Constants.cell_size^2
  end

  local life_time = d / Constants.cell_size / entity.rain_speed
  local velocity = DIRECTION * entity.rain_speed * Constants.cell_size

  local did_vision_change do
    did_vision_change = state._player_position ~= State.player.position
    state._player_position = State.player.position
  end

  while State.period:absolute(life_time / entity.rain_density / cells_n, self, "emit_rain") do
    local target = Vector.use(Random.float, start, finish)
    local target_cell = (target / Constants.cell_size):map(math.floor)

    if State.grids.shadows:slow_get(target_cell, true) then goto continue end

    local e = State.grids.solids[target_cell]
    if e and not e.transparent_flag or State.rails:is_indoors(target_cell) then goto continue end

    table.insert(state._particles, {
      position = target - DIRECTION * d,
      target_cell = target_cell,
      life_time = life_time,
      is_visible = api.is_visible(target_cell),
    })

    ::continue::
  end

  local canvas = love.graphics.getCanvas()
  love.graphics.setCanvas(state._canvas)
    love.graphics.clear(Vector.transparent)

    for _, p in ipairs(state._particles) do
      p.position = p.position + velocity * dt
      p.life_time = p.life_time - dt
      if did_vision_change then
        p.is_visible = api.is_visible(p.target_cell)
      end
      if p.is_visible then
        love.graphics.draw(IMAGE, unpack(p.position))
      end
    end

    for i = #state._particles, 1, -1 do
      local p = state._particles[i]
      if p.life_time <= 0 then
        Table.remove_breaking_at(state._particles, i)
        state._touched_ground = true
        if p.is_visible then
          animated.add_fx("assets/sprites/animations/rain_impact", p.position / Constants.cell_size, "weather")
        end
      end
    end
  love.graphics.setCanvas(canvas)
  return state._canvas
end

Ldump.mark(rain, {render = {}}, ...)
return rain
