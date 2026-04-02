return Tiny.system {
  codename = "genesis",
  base_callback = "update",
  update = function(self, dt)
    State:flush()
  end,
}
