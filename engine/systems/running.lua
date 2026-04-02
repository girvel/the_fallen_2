return Tiny.system {
  codename = "running",
  base_callback = "update",
  update = function(self, dt)
    local is_shift_down = love.keyboard.isDown("lshift", "rshift")
    for _, key in ipairs {"w", "a", "s", "d"} do
      Kernel:set_key_rate(key, is_shift_down and 8 or 5)
    end
  end,
}
