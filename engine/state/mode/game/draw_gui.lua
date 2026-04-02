local class = require("engine.mech.class")
local xp = require("engine.mech.xp")
local colors = require("engine.tech.colors")
local animated = require("engine.tech.animated")
local sound = require("engine.tech.sound")
local base_player = require("engine.state.player.base")
local gui_elements = require("engine.state.mode.gui_elements")
local ui = require("engine.tech.ui")
local actions = require("engine.mech.actions")
local translation  = require("engine.tech.translation")
local gui = require("engine.state.mode.gui_elements")
local fighter = require("engine.mech.class.fighter")
local tk = require("engine.state.mode.tk")
local interactive = require("engine.tech.interactive")
local api         = require("engine.tech.api")


-- Refactor plan:
--   render functions, utility functions -> game mode as separate file-functions
--   internal state -> game mode fields

-- Internal state
local cost, hint, mouse_task, mouse_task_path, is_compact, open_escape_menu

-- Utility functions
local action_button, set_mouse_task

-- Render functions
local draw_gui, draw_sidebar, draw_top_bars, draw_action_grid, draw_resources, draw_move_order,
  draw_bag, draw_dialogue, draw_notification, draw_suggestion, draw_keyboard_action_grid,
  draw_mouse_action_grid, use_mouse, draw_curtain

--- @param self state_mode_game
--- @param dt number
draw_gui = function(self, dt)
  is_compact = love.graphics.getHeight() < 900
  open_escape_menu = false
  hint = nil

  draw_curtain()
  draw_sidebar(self)
  draw_dialogue()
  draw_notification()
  draw_suggestion()
  use_mouse(self)

  if ui.keyboard("escape") then
    State.mode:open_menu("escape_menu")
  end
end

draw_curtain = function()
  if State.player.curtain_color == Vector.transparent then return end
  local w, h = love.graphics.getDimensions()
  ui.start_color(State.player.curtain_color)
    love.graphics.rectangle("fill", 0, 0, w, h)
  ui.finish_color()
end

local PADDING_LX = 48
local PADDING_RX = 60
local SIDEBAR_INNER_W = 336

local SIDEBAR_W = SIDEBAR_INNER_W + PADDING_LX + PADDING_RX

draw_sidebar = function(self)
  if State.runner.locked_entities[State.player] then
    State.camera.sidebar_w = 0
    return
  end

  State.camera.sidebar_w = SIDEBAR_W

  tk.start_window(
    love.graphics.getWidth() - SIDEBAR_W, 0,
    SIDEBAR_W, love.graphics.getHeight()
  )
    draw_top_bars()
    draw_action_grid(self)
    draw_resources()
    draw_move_order()
    draw_bag()

    hint = Kernel._save and "сохранение..." or hint
    if hint then
      ui.start_alignment("center", "bottom")
        ui.text(hint:utf_capitalize())
      ui.finish_alignment()
    end
  tk.finish_window()
end

action_button = function(action, hotkey)
  local player = State.player
  local is_available = action:is_available(player) and State.player:can_act()
  local codename = is_available and action.codename or (action.codename .. "_inactive")
  local button = ui.key_button(gui_elements[codename], hotkey, not is_available)
  if button.is_clicked then
    player.ai:plan_action(action)
  end
  if button.is_mouse_over then
    cost = action.cost
    hint = action.get_hint and action:get_hint(State.player) or action.name
  end
end

local HP_BAR_W = SIDEBAR_INNER_W - 64
local HP_BAR_H = 10 * 4

draw_top_bars = function()
  local player = State.player

  ui.start_frame(HP_BAR_W + 8, -4, 64, 64)
    if ui.mouse().is_mouse_over then
      hint = "броня"
    end
    ui.image("engine/assets/sprites/gui/shield.png")
  ui.finish_frame()

  ui.start_frame(HP_BAR_W + 8, -4, 64, 64)
  ui.start_alignment("center", "center")
  ui.start_font(32)
    ui.text(player:get_armor())
  ui.finish_font()
  ui.finish_alignment()
  ui.finish_frame()

  tk.start_bar(
    HP_BAR_W, HP_BAR_H,
    player.hp, player:get_max_hp(),
    gui.hp_bar, gui.hp_bar_min, gui.hp_bar_extra
  )
    if ui.mouse().is_mouse_over then
      hint = "здоровье"
    end
  tk.finish_bar()

  ui.offset(0, 12)

  tk.start_bar(
    SIDEBAR_INNER_W, 24,
    player.xp, xp.to_reach(State.player.level + 1),
    gui.xp_bar, gui.xp_bar_min, gui.hp_bar_extra
  )
    if ui.mouse().is_mouse_over then
      hint = "опыт"
    end
  tk.finish_bar()
end

draw_action_grid = function(self)
  ui.br()
  if not is_compact then ui.br() end

  cost = nil

  ui.start_frame(-16, -4)
    ui.image("engine/assets/sprites/gui/action_grid_bg.png")
  ui.finish_frame()

  ui.start_frame(4)
    if self.input_mode == "normal" then
      draw_keyboard_action_grid(self)
    else
      assert(self.input_mode == "target")
      draw_mouse_action_grid(self)
    end
  ui.finish_frame()
  ui.offset(0, 208)

  for key, direction in pairs(Vector.wasd) do
    if ui.keyboard(key) then
      set_mouse_task()
      State.player.ai:plan_action(actions.move(direction))
    end
  end
end

draw_keyboard_action_grid = function(self)
  ui.start_line()
    do
      local button = ui.key_button(gui.escape_menu, "escape")
      if button.is_clicked then
        State.mode:open_menu("escape_menu")
      end
      if button.is_mouse_over then
        hint = "меню"
      end
    end
    ui.offset(4)

    do
      local journal_image = State.quests.has_new_content and gui.journal or gui.journal_inactive
      local button = ui.key_button(journal_image, "j")
      if State.quests.has_new_content then
        ui.offset(-64)
        tk.highlight()
      end
      if button.is_clicked then
        State.mode:open_menu("journal")
      end
      if button.is_mouse_over then
        hint = "журнал"
      end
    end
    ui.offset(4)

    do
      local is_active = State.player.xp >= xp.to_reach(State.player.level + 1)
      local button = ui.key_button(
        is_active
          and gui.creator
          or gui.creator_inactive, "n"
      )
      if is_active then
        ui.offset(-64)
        tk.highlight()
      end
      if button.is_clicked then
        State.mode:open_menu("creator")
      end
      if button.is_mouse_over then
        hint = "персонаж"
      end
    end
    ui.offset(4)
  ui.finish_line()
  ui.offset(0, 4)

  ui.start_line()
    if State.combat then
      action_button(base_player.skip_turn, "space")
      ui.offset(4)
      action_button(actions.disengage, "g")
    else
      ui.offset(132)
    end
    ui.offset(4)

    action_button(actions.dash, "z")
    ui.offset(4)

    action_button(actions.interact, "e")
    ui.offset(4)

    -- TODO handle warlock hit die
    action_button(class.hit_dice(fighter.hit_die), "h")
    ui.offset(4)
  ui.finish_line()
  ui.offset(0, 4)

  ui.start_line()
    local offhand = State.player.inventory.offhand
    if offhand and offhand.tags.ranged then
      -- when there would be multiple parametrized actions, we can redo this hardcode into an
      -- action_button branch; instead of base action + action factory we can do like an action
      -- class with static methods and like .producer_flag = true; if action_button receives an
      -- action, it does action; if it receives a producer, it does parametrized two-step action.
      local is_available = actions.bow_attack_base:is_available(State.player)
      local image = is_available
        and gui_elements.bow_attack
        or gui_elements.bow_attack_inactive
      local button = ui.key_button(image, "1", not is_available)
      if button.is_clicked then
        self.input_mode = "target"
      end
      if button.is_mouse_over then
        hint = actions.bow_attack_base:get_hint(State.player)
      end
    else
      action_button(actions.hand_attack, "1")
    end
    ui.offset(4)

    if offhand
      and offhand.damage_roll
      and not offhand.tags.ranged
    then
      action_button(actions.offhand_attack, "2")
    else
      action_button(actions.shove, "2")
    end
    ui.offset(4)

    for i, action in ipairs(State.player:modify("additional_actions", {})) do
      action_button(action, tostring(2 + i))
      if i % 5 == 3 then
        ui.finish_line()
        ui.start_line()
      else
        ui.offset(4)
      end
    end
  ui.finish_line()
end

draw_mouse_action_grid = function(self)
  local escape_button = ui.key_button(gui_elements.escape, "escape")
  if escape_button.is_clicked then
    self.input_mode = "normal"
  end
  if escape_button.is_mouse_over then
    hint = "отмена"
  end
end

local RESOURCE_DISPLAY_ORDER = {
  "actions", "bonus_actions", "reactions", "movement",
  "hit_dice", "action_surge", "second_wind", "fighting_spirit",
}

local ICONS = {
  actions = "#",
  bonus_actions = "+",
  reactions = "*",
  movement = ">",
}

local DEFAULT_ICON = "'"

local COLORS = {
  actions = Vector.hex("79ad9c"),
  bonus_actions = colors.green_high,
  reactions = Vector.hex("fcea9b"),
  movement = Vector.hex("429858"),
}

local PRIMITIVE_RESOURCES = {
  "movement",
  "actions",
  "bonus_actions",
  "reactions",
}

draw_resources = function()
  ui.br()
  if not is_compact then ui.br() end

  tk.start_block()
    if not is_compact then
      ui.start_alignment("center")
        ui.text("Ресурсы")
      ui.finish_alignment()
      ui.br()
    end

    for _, r in ipairs(RESOURCE_DISPLAY_ORDER) do
      local amount = State.player.resources[r]
      if not amount or (not State.combat and Table.contains(PRIMITIVE_RESOURCES, r)) then
        goto continue
      end

      ui.start_frame(180)
      ui.start_line()
        local icon = ICONS[r] or DEFAULT_ICON
        local highlighted_n = cost and cost[r]
        if highlighted_n then
          love.graphics.setColor(colors.red_high)
            ui.text(icon * highlighted_n)
          love.graphics.setColor(COLORS[r] or colors.white)
            ui.text(icon * math.max(0, amount - highlighted_n))
          love.graphics.setColor(colors.white)
        else
          love.graphics.setColor(COLORS[r] or colors.white)
            if amount <= 12 then
              ui.text(icon * amount)
            else
              ui.text("x" .. amount)
            end
          love.graphics.setColor(colors.white)
        end
      ui.finish_line()
      ui.finish_frame()

      ui.text(translation.resources[r]:utf_capitalize())

      ::continue::
    end
    love.graphics.setColor(Vector.white)
  tk.finish_block()
end

local HOSTILITY_COLOR = {
  enemy = colors.red,
  ally = colors.green_dim,
}

draw_move_order = function()
  if not State.combat then return end

  ui.br()
  if not is_compact then ui.br() end

  tk.start_block()
    if not is_compact then
      ui.start_alignment("center")
        ui.text("Очередь ходов")
      ui.finish_alignment()
      ui.br()
    end

    local draw_item = function(i, e)
      ui.start_line()
        if State.combat.current_i == i then
          ui.text("x ")
        else
          love.graphics.setColor(colors.white_dim)
          ui.text("- ")
        end

        local hostility = State.hostility:get(e, State.player)
        local color = hostility and HOSTILITY_COLOR[hostility] or Vector.white

        love.graphics.setColor(color)
          ui.text(Name.game(e):utf_capitalize())
        love.graphics.setColor(Vector.white)
      ui.finish_line()
    end

    local list = State.combat.list
    if #list <= 8 then
      for i, e in ipairs(list) do
        draw_item(i, e)
      end
    else
      local pivot = math.ceil(#list / 10) * 5

      local frame = ui.get_context().frame
      ui.start_frame(frame.w / 2)
        for i = pivot + 1, #list do
          draw_item(i, list[i])
        end
      ui.finish_frame()

      for i = 1, pivot do
        draw_item(i, list[i])
      end
    end
  tk.finish_block()
end

draw_bag = function()
  --- @type [string, integer][], integer
  local sorted, max_length do
    sorted = {}
    max_length = 0
    for k, v in pairs(State.player.bag) do
      if v > 0 then
        table.insert(sorted, {k, v})
        max_length = math.max(max_length, k:utf_len())
      end
    end

    if #sorted == 0 then return end

    table.sort(sorted, function(a, b)
      return a[1] < b[1]
    end)
  end

  ui.br()
  if not is_compact then ui.br() end

  tk.start_block()
    if not is_compact then
      ui.start_alignment("center")
        ui.text("Сумка")
      ui.finish_alignment()
      ui.br()
    end

    for _, t in ipairs(sorted) do
      local k, v = unpack(t)
      ui.text("%s:%s %s", translation.bag[k] or k, " " * (max_length - k:utf_len()), v)
    end
  tk.finish_block()  -- TODO UI make this stateless?
end

local draw_line, draw_options

draw_dialogue = function()
  local line = State.player.hears
  if not line then return end

  local H = is_compact and 190 or 280
  local BOTTOM_GAP = is_compact and 0 or 50
  local FONT_SIZE = is_compact and 26 or 32

  tk.start_window("center", love.graphics.getHeight() - H - BOTTOM_GAP, "read_max", H)
  ui.start_font(FONT_SIZE)
    if line.type == "plain_line" then
      draw_line(line)
    elseif line.type == "options" then
      draw_options(line)
    else
      assert(false)
    end
  ui.finish_font()
  tk.finish_window()
end

local SKIP_SOUNDS = sound.multiple("engine/assets/sounds/skip_line", .05)

local FAILURE = colors.red_high
local SUCCESS = colors.green_high

draw_line = function(line)
  local text = line.text
  ui.start_frame()
  ui.start_line()
    if line.source then
      local name = Name.game(line.source)
      ui.start_color(line.source.sprite.color)
        ui.text(name)
      ui.finish_color()
      ui.text(": ")
    end

    do
      local color
      local _, j, highlighted = text:find("^(%[[^%]]+ — успех%] )")
      if highlighted then
        color = SUCCESS
      else
        _, j, highlighted = text:find("^(%[[^%]]+ — провал%] )")
        if highlighted then
          color = FAILURE
        end
      end

      if highlighted then
        ui.start_color(color)
          ui.text(highlighted)
        ui.finish_color()
        text = text:sub(j + 1)
      end
    end
    ui.text(text)
  ui.finish_line()
  ui.finish_frame()

  if ui.keyboard("space") or ui.mousedown_anywhere(1) then
    State.player.hears = nil
    SKIP_SOUNDS:play()
  end
end

draw_options = function(line)
  local sorted = {}
  for i, o in pairs(line.options) do  -- can't use luafun: ipairs/pairs detection conflict
    table.insert(sorted, {i, o})
  end
  table.sort(sorted, function(a, b) return a[1] < b[1] end)

  local displayed = Fun.iter(sorted)
    :enumerate()
    :map(function(i, pair) return i .. ". " .. pair[2] end)
    :totable()

  local n = ui.choice(displayed)
  for i = 1, #displayed do
    if ui.keyboard(tostring(i)) then
      n = i
    end
  end
  if n then
    State.player.speaks = sorted[n][1]
    State.player.hears = nil
  end
end

local start_t, prev

draw_notification = function()
  local text = State.player.notification
  if not text then
    prev = text
    return
  end

  if not prev then
    start_t = love.timer.getTime()
  end
  local dt = love.timer.getTime() - start_t

  local postfix, prefix
  if dt <= .3 then
    prefix  = "  ."
    postfix = ".  "
  elseif dt <= .6 then
    prefix  = " . "
    postfix = " . "
  elseif dt <= .9 then
    prefix  = ".  "
    postfix = "  ."
  else
    prefix  = "   "
    postfix = "   "
  end

  ui.start_frame(nil, 10)
  ui.start_font(32)
  ui.start_alignment("center")
    ui.text(prefix .. text .. postfix)
  ui.finish_alignment()
  ui.finish_font()
  ui.finish_frame()

  prev = text
end

draw_suggestion = function()
  if State.runner.locked_entities[State.player] then return end
  if not actions.interact:is_available(State.player) then return end
  local target = interactive.get_for(State.player)  --[[@as item]]
  if not target then return end

  ui.start_frame(nil, love.graphics.getHeight() - 100)
  ui.start_alignment("center")
  ui.start_font(32)
    local name = Name.game(target)
    local roll = target.damage_roll
    if roll then
      if target.bonus then
        roll = roll + target.bonus
      end
      name = ("%s (%s)"):format(name, roll:simplified())
    end
    ui.text("[E] для взаимодействия с " .. name)
  ui.finish_font()
  ui.finish_alignment()
  ui.finish_frame()
end

--- @param task? fun(scene: any, characters: any)
--- @param path? vector[]
set_mouse_task = function(task, path)
  State.runner:stop(mouse_task, false, true)
  if task then
    local promise
    promise, mouse_task = State.runner:run_task(task)
    promise:next(function()
      mouse_task_path = nil
    end)
  end
  mouse_task_path = path
end

local PATH_MAX_LENGTH = 50
local render_path

use_mouse = function(self)
  if ui.mousedown(1) then
    set_mouse_task()
  end

  if not State.player:can_act() then
    State.runner:stop(mouse_task, false, true)
    return
  end

  ui.start_frame(nil, nil, love.graphics.getWidth() - State.camera.sidebar_w)
    if self.input_mode == "target" then ui.cursor("target_inactive") end

    local position = V(love.mouse.getPosition())
      :sub_mut(State.camera.offset)
      :div_mut(Constants.cell_size * 4)
      :map_mut(math.floor)
    local solid = State.grids.solids:slow_get(position)
    local interaction_target = interactive.get_at(position)

    local lmb = ui.mousedown(1)
    local rmb = ui.mousedown(2)

    if self.input_mode == "target" then
      if rmb then
        self.input_mode = "normal"
      end

      if solid then
        local action = actions.bow_attack(solid)

        if action:is_available(State.player) then
          ui.cursor("target_active")
          if rmb then
            State.player.ai:plan_action(action)
          end
        end
      end
    else
      -- TODO OPT cache with mouse_x, mouse_y and invalidate on tcod map changes
      --   (or maybe it would be even slower, idk)
      local path, max_length do
        if not State.combat then
          max_length = PATH_MAX_LENGTH
        elseif State.player:can_act() then
          max_length = State.player.resources.movement
        else
          max_length = 0
        end

        path = api.build_path(State.player.position, position, max_length)
      end

      if interaction_target then
        ui.cursor("hand")
      elseif not solid and path then
        ui.cursor("walk")
      end

      if State.combat then
        if mouse_task_path then
          render_path(mouse_task_path)
        elseif path then
          render_path(path, max_length)
        end
      end

      if path and (rmb and not solid or lmb and interaction_target) then
        animated.add_fx("engine/assets/sprites/animations/underfoot_circle", position)
        set_mouse_task(function()
          local ok = api.follow_path(State.player, path, false, 8)
          api.rotate(State.player, position)
          if ok and interaction_target then
            actions.interact:act(State.player)
          end
        end, path)
      end

      local is_a_potential_target
      if not solid then
        is_a_potential_target = false
      else
        local player_hostility = State.hostility:get(State.player, solid)
        is_a_potential_target = (
          player_hostility == "enemy"
          or player_hostility == nil and State.hostility:get(solid, State.player) == "enemy"
        )
      end
      local bow_attack = actions.bow_attack(solid)

      if bow_attack:is_available(State.player) and is_a_potential_target then
        ui.cursor("target_active")
        if rmb then
          State.player.ai:plan_action(bow_attack)
        end
      end

      local hand = State.player.inventory.hand
      if hand and hand.damage_roll and is_a_potential_target then
        ui.cursor("target_active")
        if rmb and (path or api.distance(position, State.player) == 1) then
          local potential_attacking_actions = {
            actions.hand_attack,
            actions.offhand_attack,
            actions.shove,
          }

          if Fun.iter(potential_attacking_actions)
            :any(function(a) return a:enough_resources(State.player) end)
          then
            set_mouse_task(function()
              animated.add_fx("engine/assets/sprites/animations/underfoot_circle", position)
              local ok = not path or api.follow_path(State.player, path, false, 8)
              api.rotate(State.player, position)
              if ok then
                local action = Fun.iter(potential_attacking_actions)
                  :filter(function(a) return a:is_available(State.player) end)
                  :nth(1)

                if action then
                  action:act(State.player)
                end
              end
            end, path)
          end
        end
      end
    end
  ui.finish_frame()
end

--- @param path vector[]
--- @param max_length? integer present only if the path is planned
render_path = function(path, max_length)
  local start_i
  if not max_length then
    for i, e in ipairs(path) do
      if e == State.player.position then
        start_i = i + 1
        goto found
      end
    end
  end
  start_i = 1

  ::found::
  local px, py = State.camera:game_to_screen(unpack(State.player.position))

  for i = start_i, #path do
    local e = path[i]
    local sx, sy = State.camera:game_to_screen(unpack(e))

    local postfix
    if i == 1 and e.y - State.player.position.y == -1 then
      postfix = "vertical_part"
    elseif px - sx == 0 then
      postfix = "vertical"
    else
      postfix = "horizontal"
    end

    if not max_length then
      postfix = "persistent_" .. postfix
    end

    ui.start_frame(math.min(px, sx), math.min(py, sy))
      ui.image(("engine/assets/sprites/gui/path_%s.png"):format(postfix))
    ui.finish_frame()

    px = sx
    py = sy
  end

  if max_length then
    local n = State.camera.SCALE * Constants.cell_size
    ui.start_frame(px, py, n, n - 4)
    ui.start_alignment("center", "bottom")
      ui.text("%s/%s", #path, max_length)
    ui.finish_alignment()
    ui.finish_frame()
  end
end

Ldump.mark(draw_gui, {}, ...)
return draw_gui
