local sprite = require("engine.tech.sprite")
local camera = {}


----------------------------------------------------------------------------------------------------
-- [SECTION] API
----------------------------------------------------------------------------------------------------

--- @class state_camera
--- @field target_override entity?
--- @field is_camera_following boolean
--- @field is_moving boolean (internally set)
--- @field offset vector (internally set) offset in pixels relative to the grid start
--- @field vision_start vector (internally set) the grid coordinate of the first cell visible in top left corner, clamped to grid size
--- @field vision_end vector (internally set) the grid coordinate of the last cell visible in bottom right corner, clamped to grid size
--- @field sidebar_w integer sidebar width in screen pixels
--- @field scale integer current scaling coefficient
--- @field base_scale integer starting scaling coefficient
local methods = {}
camera.mt = {__index = methods}

camera.new = function()
  local self = {
    is_moving = false,
    is_camera_following = true,
    offset = Vector.zero,
    vision_start = Vector.zero,
    vision_end = Vector.zero,
    sidebar_w = 0,
    base_scale = Kernel.args.youtube and 8 or 4,
  }
  self.scale = self.base_scale
  return setmetatable(self, camera.mt)
end

methods.immediate_center = function(self)
  self.offset = V(self:_center(unpack((self.target_override or State.player).position)))
end

--- @param gx number
--- @param gy number
--- @return number sx
--- @return number sy
methods.game_to_screen = function(self, gx, gy)
  local dx, dy = unpack(self.offset)
  local k = State.camera.scale * sprite.cell_size
  return k * gx - dx, k * gy - dy
end

--- @param sx number
--- @param sy number
--- @return number gx
--- @return number gy
methods.screen_to_game = function(self, sx, sy)
  local dx, dy = unpack(self.offset)
  local k = State.camera.scale * sprite.cell_size
  return math.floor((sx + dx) / k), math.floor((sy + dy) / k)
end

----------------------------------------------------------------------------------------------------
-- [SECTION] Implementation
----------------------------------------------------------------------------------------------------

local smooth_camera_offset

methods._update = function(self, dt)
  if State:exists(State.player) then
    State.player.ai._vision_map:refresh_fov(State.player.position, State.player.fov_r)
  end

  if self.is_camera_following then
    local prev_offset = self.offset

    if dt >= .05 then
      self:immediate_center()
    else
      local target = self.target_override or State.player
      local px, py = unpack(self.offset)
      local tx, ty = unpack(target.position)

      if target == State.player
        and Kernel.gui._mode.type == "game"
        and State.player:can_act()
        and State.player.resources.movement > 0
      then
        tx = tx
          + math.min(1, (Kernel._delays.d or 0) * Kernel:get_key_rate("d"))
          - math.min(1, (Kernel._delays.a or 0) * Kernel:get_key_rate("a"))

        ty = ty
          + math.min(1, (Kernel._delays.s or 0) * Kernel:get_key_rate("s"))
          - math.min(1, (Kernel._delays.w or 0) * Kernel:get_key_rate("w"))
      end

      local x, y = self:_center(tx, ty)
      self.offset = V(smooth_camera_offset:next(x, y, px, py, dt))
    end

    self.is_moving = prev_offset ~= self.offset
  else
    self.is_moving = false
  end

  do
    local total_scale = self.scale * sprite.cell_size
    self.vision_start = (self.offset / total_scale):map(math.ceil):sub_mut(Vector.one)
    self.vision_end = V(love.graphics.getWidth() - self.sidebar_w, love.graphics.getHeight())
      :div_mut(total_scale)
      :map_mut(math.ceil)
      :add_mut(self.vision_start)

    self.vision_start = Vector.use(
      Math.median, Vector.one, self.vision_start, State.level.grid_size
    )
    self.vision_end = Vector.use(Math.median, Vector.one, self.vision_end, State.level.grid_size)
  end
end

--- @param x number
--- @param y number
--- @return number x
--- @return number y
methods._center = function(self, x, y)
  local k = sprite.cell_size * self.scale
  return
    math.floor((x + .5) * k - (love.graphics.getWidth() - self.sidebar_w) / 2),
    math.floor((y + .5) * k - love.graphics.getHeight() / 2)
end

local SPRING_STIFFNESS = 100
local DAMPING_K = 2 * math.sqrt(SPRING_STIFFNESS)

smooth_camera_offset = {
  vx = 0,
  vy = 0,
  next = function(self, x, y, px, py, dt)
    local dx = x - px
    local dy = y - py

    local ax = SPRING_STIFFNESS * dx - DAMPING_K * self.vx
    local ay = SPRING_STIFFNESS * dy - DAMPING_K * self.vy

    self.vx = self.vx + ax * dt
    self.vy = self.vy + ay * dt

    return
      math.floor(px + self.vx * dt),
      math.floor(py + self.vy * dt)
  end,
}

Ldump.mark(camera, {mt = "const"}, ...)
return camera
