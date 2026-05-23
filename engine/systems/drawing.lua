local level = require("engine.tech.level")


return Tiny.sortedProcessingSystem {
  codename = "drawing",
  base_callback = "draw",
  filter = function(_, entity)
    return entity.sprite and entity.position and entity.layer
  end,

  compare = function(_, a, b)
    return Table.index_of(level.layers, a.layer) < Table.index_of(level.layers, b.layer)
  end,

  preProcess = function(_, dt)
    State.camera:_update(dt)
  end,

  process = function(_, entity, dt)
    Kernel.gui:draw_entity(entity, dt)
  end,
}
