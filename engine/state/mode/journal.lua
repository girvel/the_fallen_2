local colors = require("engine.tech.colors")
local ui = require("engine.tech.ui")
local tk = require("engine.state.mode.tk")


local journal = {}

--- @class state_mode_journal
--- @field type "journal"
--- @field _prev state_mode_game
local methods = {}
local mt = {__index = methods}

--- @param prev state_mode_game
--- @return state_mode_journal
journal.new = function(prev)
  return setmetatable({
    type = "journal",
    _prev = prev,
  }, mt)
end

tk.delegate(methods, "draw_entity", "preprocess", "postprocess")

methods.draw_gui = function(self, dt)
  if ui.keyboard("escape") or ui.keyboard("j") then
    State.quests:new_content_is_read()
    State.mode:close_menu()
  end

  if ui.keyboard("n") then
    State.quests:new_content_is_read()
    State.mode:close_menu()
    State.mode:open_menu("creator")
  end

  tk.start_window("center", "center", "read_max", "max")
    ui.h1("Журнал")

    for _, codename in ipairs(State.quests.order) do
      local quest = State.quests.items[codename]
      if not quest then goto continue end

      ui.start_font(36)
        ui.start_line()
          ui.start_color(colors.white_dim)
          ui.text("# ")

          if quest.status == "new" or quest.status == "active" then
            ui.finish_color()
            ui.text(quest.name)
          else
            ui.text(quest.name)
            ui.finish_color()
          end
        ui.finish_line()
      ui.finish_font()
      ui.br()

      for _, objective in ipairs(quest.objectives) do
        local prefix
        local needs_color_reset = true
        if objective.status == "done" then
          ui.start_color(colors.white_dim)
          prefix = "+ "
        elseif objective.status == "failed" then
          ui.start_color(colors.white_dim)
          prefix = "x "
        elseif objective.status == "new" then
          ui.start_color(colors.golden)
          prefix = "- "
        else
          prefix = "- "
          needs_color_reset = false
        end

        ui.text(prefix .. objective.text)

        if needs_color_reset then
          ui.finish_color()
        end
      end
      ui.br()
      ui.br()

      ::continue::
    end
  tk.finish_window()
end

Ldump.mark(journal, {}, ...)
return journal
