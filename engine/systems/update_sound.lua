return Tiny.system {
  codename = "update_sound",
  base_callback = "update",
  update = function(self, dt)
    State.audio:_update(dt)
  end,
}
