local camera = {}


----------------------------------------------------------------------------------------------------
-- [SECTION] API
----------------------------------------------------------------------------------------------------

--- @class state_camera
--- @field target_override entity?
--- @field is_camera_following boolean
--- @field is_moving boolean (internally set)
--- @field offset vector (internally set) offset in pixels relative to the grid start
--- @field vision_start vector (internally set)
--- @field vision_end vector (internally set)
--- @field sidebar_w integer sidebar width in screen pixels
--- @field SCALE integer
local methods = {}
camera.mt = {__index = methods}

camera.new = function()
  return setmetatable({
    is_moving = false,
    is_camera_following = true,
    camera_offset = Vector.zero,
    vision_start = Vector.zero,
    vision_end = Vector.zero,
    sidebar_w = 0,
    SCALE = 4,
  }, camera.mt)
end

methods.immediate_center = function(self)
  self.offset = V(self:_center(unpack((self.target_override or State.player).position)))
end

--- @param gx number
--- @param gy number
--- @return number sx, number sy
methods.game_to_screen = function(self, gx, gy)
  local dx, dy = unpack(self.offset)
  local k = State.camera.SCALE * Constants.cell_size
  return dx + k * gx, dy + k * gy
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
        and State.mode._mode.type == "game"
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

      self.offset = V(smooth_camera_offset:next(tx, ty, px, py, dt))
    end

    self.is_moving = prev_offset ~= self.offset
  else
    self.is_moving = false
  end

  do
    local total_scale = self.SCALE * Constants.cell_size
    self.vision_start = -(State.camera.offset / total_scale):map(math.ceil)
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
--- @return number, number
methods._center = function(self, x, y)
  local k = Constants.cell_size * self.SCALE
  return
    math.floor((love.graphics.getWidth() - self.sidebar_w) / 2 - (x + .5) * k),
    math.floor(love.graphics.getHeight() / 2 - (y + .5) * k)
end

local SPRING_STIFFNESS = 100
local DAMPING_K = 2 * math.sqrt(SPRING_STIFFNESS)

smooth_camera_offset = {
  vx = 0,
  vy = 0,
  next = function(self, tx, ty, px, py, dt)
    local dest_x, dest_y = State.camera:_center(tx, ty)

    local dx = dest_x - px
    local dy = dest_y - py

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
