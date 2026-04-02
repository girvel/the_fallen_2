local ui = require("engine.tech.ui")
local level = require("engine.tech.level")
local colors = require("engine.tech.colors")


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
    if State.is_loaded then
      State.camera:_update(dt)
    end

    love.graphics.clear(colors.black)

    State.mode:preprocess(dt)
  end,

  process = function(_, entity, dt)
    State.mode:draw_entity(entity, dt)
  end,

  postProcess = function(_, dt)
    State.mode:postprocess(dt)
    ui.start()
    State.mode:draw_gui(dt)
    State.debug_overlay:draw(dt)
    ui.finish()
  end,
}
