-- TODO not really used, not really functional, should probably be redone
local audio = {}

--- @class state_audio
--- @field _playlist sound[]
--- @field _playlist_paused boolean
--- @field _paused_delay number
--- @field _current sound?
local methods = {}
local mt = {__index = methods}

--- @return state_audio
audio.new = function()
  return setmetatable({
    _playlist = {},
    _playlist_paused = false,
    _paused_delay = 0,
    _current = nil,
  }, mt)
end

--- @param playlist sound[]
methods.set_playlist = function(self, playlist)
  self._current = nil
  self._playlist = playlist
end

local FADE_DURATION = .5

methods._update = function(self, dt)
  if State.player then
    love.audio.setPosition(unpack(State.player.position))
  else
    love.audio.setPosition(-1000, -1000, 0)
  end

  if State.args.disable_ambient then return end

  local last_track = self._current

  if last_track and last_track.source:isPlaying() then
    -- TODO intersection
    -- TODO don't stop playing music on pause, just turn it down
    if self._paused_delay > 0 then
      local volume = self._paused_delay / FADE_DURATION
      if not self._playlist_paused then
        volume = 1 - volume
      end
      last_track.source:setVolume(volume)
      self._paused_delay = self._paused_delay - dt
      return
    elseif self._playlist_paused then
      last_track.source:pause()
    end

    local position = last_track.source:tell()
    if position <= FADE_DURATION then
      last_track.source:setVolume(position / FADE_DURATION)
      return
    end

    local position_from_end = last_track.source:getDuration() - position
    if position_from_end <= FADE_DURATION then
      last_track.source:setVolume(position_from_end / FADE_DURATION)
      return
    end

    return
  end

  if #self._playlist == 0 or self._playlist_paused then return end

  while true do
    self._current = Random.item(self._playlist)
    if #self._playlist == 1 or self._current ~= last_track then break end
  end
  self._current:play()
end

--- @param value any
methods.set_paused = function(self, value)
  value = not not value
  if self._playlist_paused == value then return end

  self._playlist_paused = value
  self._paused_delay = FADE_DURATION

  if value then
    Log.info("Paused ambient")
  else
    Log.info("Unpaused ambient")
  end
end

methods.reset = function(self)
  if self._current then
    self._current.source:pause()
  end
end

Ldump.mark(audio, {}, ...)
return audio
