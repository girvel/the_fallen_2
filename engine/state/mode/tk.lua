local colors = require("engine.tech.colors")
local gui_elements = require("engine.state.mode.gui_elements")
local ui = require("engine.tech.ui")
local item = require("engine.tech.item")


local tk = {}

--- @param methods table
--- @param ... string
tk.delegate = function(methods, ...)
  for i = 1, select("#", ...) do
    local f_name = select(i, ...)
    methods[f_name] = function(self, ...)
      if self._prev[f_name] then
        return self._prev[f_name](self._prev, ...)
      end
    end
  end
end

tk.WINDOW_PADDING = 40
local MAX_READABLE_W = 800

--- @param x integer|"center"|"right"
--- @param y integer|"center"
--- @param w integer|"max"|"read_max"
--- @param h integer|"max"
tk.start_window = function(x, y, w, h)
  if w == "max" then
    w = love.graphics.getWidth() - 2 * tk.WINDOW_PADDING
  elseif w == "read_max" then
    w = math.min(love.graphics.getWidth(), MAX_READABLE_W)
  end --- @cast w integer

  if h == "max" then
    h = love.graphics.getHeight() - 2 * tk.WINDOW_PADDING
  end --- @cast h integer

  if x == "center" then
    x = (love.graphics.getWidth() - w) / 2
  elseif x == "right" then
    x = love.graphics.getWidth() - w
  end --- @cast x integer

  if y == "center" then
    y = (love.graphics.getHeight() - h) / 2
  end --- @cast y integer

  ui.start_frame(x, y, w, h)
    ui.tile(gui_elements.window_bg)
  ui.finish_frame()

  ui.start_frame(
    x + tk.WINDOW_PADDING,
    y + tk.WINDOW_PADDING,
    w - 2 * tk.WINDOW_PADDING,
    h - 2 * tk.WINDOW_PADDING
  )
end

tk.finish_window = function()
  ui.finish_frame()
end

--- @param entity entity
--- @param x integer
--- @param y integer
--- @param scale integer
tk.draw_entity = function(entity, x, y, scale)
  local display_slot, is_hand_bg, is_offhand_bg
  if entity.inventory then
    display_slot = function(slot)
      local this_item = entity.inventory[slot]
      if not this_item then return end

      local item_sprite = this_item.sprite
      if not item_sprite then return end

      local dx, dy = unpack(item.anchor_offset(entity, slot):mul_mut(scale * Constants.cell_size))
      local item_x = x + dx
      local item_y = y + dy
      love.graphics.draw(item_sprite.image, item_x, item_y, 0, scale)
    end

    is_hand_bg = entity.direction == Vector.up
    is_offhand_bg = entity.direction ~= Vector.down

    if is_hand_bg then display_slot("hand") end
    if is_offhand_bg then display_slot("offhand") end
  end

  love.graphics.draw(entity.sprite.image, x, y, entity.rotation or 0, scale)

  if entity.inventory then
    display_slot("skin")
    display_slot("hair")
    display_slot("body")
    display_slot("head")
    display_slot("blood")
    display_slot("gloves")
    display_slot("bag")
    if not is_hand_bg then display_slot("hand") end
    if not is_offhand_bg then display_slot("offhand") end
    display_slot("highlight")
  end
end

local SIDEBAR_BLOCK_PADDING = 10

tk.start_block = function()
  ui.stack_push("tk_block_start", ui.get_context().cursor_y)
  ui.start_frame(
    4 + SIDEBAR_BLOCK_PADDING, 4 + SIDEBAR_BLOCK_PADDING,
    -2 * SIDEBAR_BLOCK_PADDING - 8
  )
end

tk.finish_block = function()
  local finish = ui.get_context().cursor_y
  local prev_frame = ui.finish_frame()

  local h = finish - ui.stack_pop("tk_block_start") + SIDEBAR_BLOCK_PADDING + 4
  local k = Constants.cell_size
  ui.start_frame(-k, -k, prev_frame.w + 2*k, h + 2*k)
    ui.tile(gui_elements.sidebar_block_bg)
  ui.finish_frame()
  ui.offset(0, h)
end

--- @param w integer
--- @param h integer
--- @param value integer
--- @param max integer
--- @param bar string
--- @param bar_small string
--- @param bar_extra string
tk.start_bar = function(w, h, value, max, bar, bar_small, bar_extra)
  ui.start_frame(nil, nil, w, h + 16)

  ui.tile(gui_elements.bar_bg)

  local saturation = value / max
  local base_saturation = math.min(saturation, 1)
  local extra_saturation = saturation > 1 and (1 - 1 / saturation)
  local bar_w = math.floor((w - 16) * base_saturation / ui.SCALE) * ui.SCALE

  if bar_w > 0 then
    ui.start_frame(8, 8, bar_w, h)
      ui.tile(bar_w > 16 and bar or bar_small)
    ui.finish_frame()

    if extra_saturation then
      ui.start_frame(8, 8, math.floor((w - 16) * extra_saturation / ui.SCALE) * ui.SCALE, h)
        ui.tile(bar_extra)
      ui.finish_frame()
    end
  end

  ui.start_alignment("center", "center")
  ui.start_font(math.floor(h * .8))
    ui.text("%s/%s", value, max)
  ui.finish_font()
  ui.finish_alignment()
end

tk.finish_bar = function()
  ui.finish_frame("push_frame")
end

tk.choose_save = function(show_new_save)
  local options, dates do
    options = {}
    dates = {}

    for _, name in ipairs(love.filesystem.getDirectoryItems("saves")) do
      local full_path = "saves/" .. name
      if love.filesystem.getInfo(full_path).type ~= "file" or
        not name:ends_with(".ldump.gz")
      then
        goto continue
      end

      name = name:sub(1, -10)
      table.insert(options, name)
      dates[name] = love.filesystem.getInfo(full_path).modtime

      ::continue::
    end

    table.sort(options, function(a, b) return dates[a] > dates[b] end)
    if show_new_save then
      table.insert(options, 1, "<Новое сохранение>")
    end
  end

  local nice_date = "%Y.%m.%d %H:%M  "
  local context = ui.get_context()
  local char_w = math.floor(context.frame.w / context.font:getWidth("w")) - #os.date(nice_date)

  ui.start_frame()
  ui.start_alignment("right")
  ui.start_color(colors.white_dim)
    for i, option in ipairs(options) do
      if show_new_save and i == 1 then
        ui.br()
      else
        ui.text("." * (char_w - option:utf_len()) .. os.date(nice_date, dates[option]))
      end
    end
  ui.finish_color()
  ui.finish_alignment()
  ui.finish_frame()

  local i = ui.choice(options)
  if show_new_save and i == 1 then
    return "save_" .. os.date("%Y-%m-%d_%H-%M-%S")
  end
  return options[i]
end

local highlight_entity = item.cues.highlight()

tk.highlight = function()
  if not State:exists(highlight_entity) then
    State:add(highlight_entity)
  end
  ui.image(highlight_entity.sprite.image)
end

--- @param position vector in-game
--- @param text string
tk.popup = function(position, text)
  local gx, gy = unpack(position)
  local sx, sy = State.camera:game_to_screen(gx + .5, gy - .25)
  local w = 150
  local padding = ui.SCALE
  local h = ui.predict_text_size(text, w)

  ui.start_frame(sx - w/2 - padding, sy - h - padding, w + padding, h + padding)
    ui.tile("engine/assets/sprites/gui/black_bg.png")
    ui.start_frame(padding, padding)
      ui.text(text)
    ui.finish_frame()
  ui.finish_frame()
end

Ldump.mark(tk, {}, ...)
return tk
