local tk = require("engine.state.mode.tk")
local ui = require("engine.tech.ui")


local save_menu = {}

--- @class state_mode_save_menu
--- @field type "save_menu"
--- @field _prev table
local methods = {}
local mt = {__index = methods}

--- @param prev table
--- @return state_mode_save_menu
save_menu.new = function(prev)
  return setmetatable({
    type = "save_menu",
    _prev = prev,
  }, mt)
end

tk.delegate(methods, "draw_entity", "preprocess", "postprocess")

methods.draw_gui = function(self, dt)
  local in_combat = State.combat
  local in_cutscene = State.runner.locked_entities[State.player]
  if in_combat or in_cutscene then
    State.mode:close_menu()
    State.mode:show_warning(
      "Невозможно сохранить игру во время %s",
      in_combat and "битвы" or "диалога"
    )
    return
  end

  tk.start_window("center", "center", "read_max", "max")
  ui.start_font(24)
    ui.h1("Сохранить игру")

    local save = tk.choose_save(true)
    if save then
      Kernel:plan_save(save)

      if self._prev.type == "escape_menu" then
        self._prev.has_saved = true
      end
    end

    local escape_pressed = ui.keyboard("escape")

    if save or escape_pressed then
      ui.reset_selection()
      State.mode:close_menu()
    end
  ui.finish_font()
  tk.finish_window()
end

Ldump.mark(save_menu, {}, ...)
return save_menu
