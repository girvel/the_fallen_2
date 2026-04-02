return Tiny.processingSystem {
  codename = "animation",
  base_callback = "update",
  filter = Tiny.requireAll("animation"),

  onAdd = function(_, entity)
    if not entity.animation.current then
      entity:animate()
    end
  end,

  --- @param entity entity
  process = function(_, entity, dt)
    entity:animation_update(dt)
  end,
}
