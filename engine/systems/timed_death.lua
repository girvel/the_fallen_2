return Tiny.processingSystem {
  codename = "timed_death",
  base_callback = "update",
  filter = Tiny.requireAll("life_time"),

  process = function(_, entity, dt)
    entity.life_time = entity.life_time - dt
    if entity.life_time <= 0 then
      State:remove(entity)
    end
  end,
}
