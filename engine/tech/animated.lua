local sprite = require("engine.tech.sprite")


local animated = {}

--- @alias animation_pack table<string, sprite_image[]>

--- @alias animation_name "idle"|"move"|"hand_attack"|"offhand_attack"|"gesture"|"fast_gesture"|"clap"|"lying"|"interact"|"throw"|"bow_attack"|"hanging"

--- @class animation
--- @field pack animation_pack
--- @field paused boolean
--- @field current animation_name|string
--- @field next animation_name
--- @field frame number
--- @field _end_promise promise

--- @class _animated_methods
local methods = {}

local load_pack

--- @alias atlas_n integer|"directional"|"no_atlas"

--- @param path string
--- @param atlas_n? atlas_n if nil or "directional", interprets animation atlas as directional; if "no_atlas", uses the frame as a whole; else, uses nth cell from each frame
--- @param color? vector
--- @return table
animated.mixin = function(path, atlas_n, color)
  local pack = load_pack(path, atlas_n or "directional", color)
  return Table.extend({
    animation = {
      pack = pack,
      paused = false,
      next = "idle",
      _end_promise = nil,
    },
    sprite = select(2, next(pack))[1],
  }, methods)
end

--- @param entity entity
--- @param path string
--- @param atlas_n? atlas_n
animated.change_pack = function(entity, path, atlas_n)
  entity.animation.pack = load_pack(path, atlas_n or "directional")
  entity:animate()
end

--- @param path string
--- @param position vector
--- @param layer? layer
--- @return entity
animated.add_fx = function(path, position, layer)
  return State:add(animated.fx(path, position, layer))
end

--- @param path string
--- @param position vector
--- @param layer? layer
--- @return entity
animated.fx = function(path, position, layer)
  local result = animated.mixin(path, "no_atlas")

  local _, _, head = path:find("/?([^/]+)$")
  result.codename = head and (head .. "_fx") or "unnamed_fx"
  result.boring_flag = true
  result.position = position
  result.layer = layer or "fx_under"

  result:animate():next(function()
    result:animation_set_paused(true)
    State:remove(result)
  end)

  return result
end

local set_current = function(self, animation_name)
  local animation = self.animation
  local dirname = self.direction and Vector.name_from_direction(self.direction)

  if dirname then
    animation.current = animation_name .. "_" .. dirname
  end

  if not dirname or not animation.pack[animation.current] then
    animation.current = animation_name
  end
end

--- @param self entity
--- @param animation_name? string|animation_name
--- @param assertive? boolean whether to assert that animation exists
--- @param looped? boolean
--- @return promise
methods.animate = function(self, animation_name, assertive, looped)
  local animation = self.animation
  animation_name = animation_name or animation.next

  local promise = animation._end_promise
  if promise then
    animation._end_promise = nil
    promise:resolve()
  end
  self:animation_set_paused(false)

  set_current(self, animation_name)

  if animation.pack[animation.current] then
    if looped then
      animation.next = animation_name
    end
  else
    if assertive then
      Error("Missing %s for entity %s", animation_name, self)
    end

    set_current(self, animation.next)
  end

  animation.frame = 1

  if self.inventory then
    for _, item in pairs(self.inventory) do
      if item.animate and not item.animated_independently_flag then
        item:animate(animation_name, false, looped)
      end
    end
  end

  animation._end_promise = Promise.new()
  return animation._end_promise
end

local DEFAULT_ANIMATION_FPS = 6

--- @param self entity
--- @param dt? number
methods.animation_update = function(self, dt)
  local animation = self.animation
  if animation.paused or not dt then dt = 0 end

  local current_pack = animation.pack[animation.current]
  if not current_pack then
    Error("%s is missing animation %s", Name.code(self), animation.current)
  end

  -- even if animation is 1 frame idle, still should play out for 1-frame FXs
  animation.frame = animation.frame + dt * DEFAULT_ANIMATION_FPS
  if math.floor(animation.frame) > #current_pack then
    self:animate(animation.next)
    current_pack = animation.pack[animation.current]
  end
  self.sprite = current_pack[math.floor(animation.frame)]
end

--- @param self entity
--- @param value boolean
methods.animation_set_paused = function(self, value)
  self.animation.paused = value

  if self.inventory then
    for _, item in pairs(self.inventory) do
      if item.animation and not item.animated_independently_flag then
        item.animation.paused = value
      end
    end
  end
end

--- @param self entity
--- @param animation_name animation_name
methods.animation_freeze = function(self, animation_name)
  self:animate(animation_name)
  self:animation_set_paused(true)
  self:animation_update()
end

--- @param folder_path string
--- @param is_atlas boolean
--- @param color vector?
--- @return animation_pack[]
local load_pack_raw = Memoize(function(folder_path, is_atlas, color)
  local info = love.filesystem.getInfo(folder_path)

  if not info then
    Error("No folder %q, unable to load animation", folder_path)
    return {}
  end

  if info.type ~= "directory" then
    Error("%q is not a folder, unable to load animation", folder_path)
    return {}
  end

  local w, h, parts_n
  local result = {}
  for _, file_name in ipairs(love.filesystem.getDirectoryItems(folder_path)) do
    local animation_name, frame_i do
      if not file_name:ends_with(".png") then goto continue end
      _, _, animation_name, frame_i = file_name:sub(1, -5):find("^(.+)_(%d+)$")
      frame_i = tonumber(frame_i)  --[[@as number]]

      if not frame_i then
        Error("%q not in format <animation name>_<frame index>.png", file_name)
        goto continue
      end
    end

    local full_path = folder_path .. "/" .. file_name
    local data = love.image.newImageData(full_path)

    do
      local next_w, next_h = data:getDimensions()
      if not w then
        assert(not h)
        w = next_w
        h = next_h

        if is_atlas then
          parts_n = w * h / Constants.cell_size / Constants.cell_size
          for i = 1, parts_n do
            result[i] = {}
          end
        else
          result[1] = {}
        end
      else
        if next_w ~= w then
          Error("%q's width %s is not equal to previous encountered %s", full_path, next_w, w)
        end
        if next_h ~= h then
          Error("%q's height %s is not equal to previous encountered %s", full_path, next_h, h)
        end
      end
    end

    if is_atlas then
      for i = 1, parts_n do
        local pack = result[i]
        pack[animation_name] = pack[animation_name] or {}
        pack[animation_name][frame_i] = sprite.image(
          sprite.utility.select(data, i), color
        )
      end
    else
      local pack = result[1]
      pack[animation_name] = pack[animation_name] or {}
      pack[animation_name][frame_i] = sprite.image(data, color)
    end

    ::continue::
  end

  return result
end)

--- @param path string
--- @param atlas_n atlas_n if nil, interprets animation atlas as directional; if "no_atlas", uses the frame as a whole; else, uses nth cell from each frame
--- @param color? vector
load_pack = function(path, atlas_n, color)
  local base_pack = load_pack_raw(path, atlas_n ~= "no_atlas", color)
  if atlas_n ~= "directional" then
    if atlas_n == "no_atlas" then atlas_n = 1 end
    return base_pack[atlas_n]
  end

  if #base_pack ~= 4 then
    Error("Directional animation atlas %s should contain 4 cells, got %s", path, #base_pack)
  end

  local pack = {}
  for i, direction_name in ipairs {"up", "left", "down", "right"} do
    for animation_name, frames in pairs(base_pack[i]) do
      pack[animation_name .. "_" .. direction_name] = frames
    end
  end
  return pack
end

Ldump.mark(animated, {}, ...)
return animated
