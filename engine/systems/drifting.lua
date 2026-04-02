return Tiny.processingSystem {
  codename = "drifting",
  base_callback = "update",
  filter = Tiny.requireAll("drift"),

  process = function(_, entity, dt)
    entity.position = (entity.drift * dt):add_mut(entity.position)
  end,
}
