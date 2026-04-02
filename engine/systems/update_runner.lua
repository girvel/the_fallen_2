return Tiny.system {
  codename = "update_runner",
  base_callback = "update",
  update = function(self, dt)
    State.runner:update(dt)
  end,
}
