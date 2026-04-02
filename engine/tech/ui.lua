local colors = require("engine.tech.colors")
local sprite = require "engine.tech.sprite"


--- Immediate mode UI module
local ui = {}

----------------------------------------------------------------------------------------------------
-- [SECTION] Internal state
----------------------------------------------------------------------------------------------------

local input = {
  mouse = {
    x = 0,
    y = 0,
    button_pressed = {},
    button_released = {},
  },
  keyboard = {
    pressed = {},
    input = "",
  },
}

local state = {
  selection = {
    i = 1, max_i = 0,
    is_pressed = false,
  },
  cursor = nil,
  time = love.timer.getTime(),

  active_frames_t = CompositeMap.new("weak"),
  are_pressed = CompositeMap.new("weak"),
}

--- @type table<string, table>
local stack

--- @type ui_context
local context

--- @class ui_context
--- @field cursor_x integer
--- @field cursor_y integer
--- @field frame ui_frame
--- @field alignment {x: ui_alignment_x, y: ui_alignment_y}
--- @field font love.Font
--- @field font_size integer
--- @field is_linear boolean
--- @field line_last_h integer
--- @field styles ui_styles
--- @field color vector

--- @class ui_styles
--- @field link_color vector
--- @field punctuation_color vector

--- @class ui_styles_optional
--- @field link_color? vector
--- @field punctuation_color? vector

--- @class ui_frame
--- @field x integer
--- @field y integer
--- @field w integer
--- @field h integer

--- @alias ui_alignment_x "left"|"center"|"right"
--- @alias ui_alignment_y "top"|"center"|"bottom"

----------------------------------------------------------------------------------------------------
-- [SECTION] Internals
----------------------------------------------------------------------------------------------------

--- @enum (key) ui_cursor_type
local CURSORS = {
  normal = love.mouse.newCursor("engine/assets/sprites/gui/cursor/normal.png"),
  target_active = love.mouse.newCursor("engine/assets/sprites/gui/cursor/target_active.png", 8, 8),
  target_inactive = love.mouse.newCursor("engine/assets/sprites/gui/cursor/target_inactive.png", 8, 8),
  walk = love.mouse.newCursor("engine/assets/sprites/gui/cursor/walk.png", 8, 8),
  hand = love.mouse.getSystemCursor("hand"),
}

local FRAME = "engine/assets/sprites/gui/button_frame.png"
local ACTIVE_FRAME = "engine/assets/sprites/gui/active_button_frame.png"

local LINE_K = love.system.getOS() == "Windows" and 1 or 1.25

local get_font = Memoize(function(size)
  return love.graphics.newFont("engine/assets/fonts/clacon2.ttf", size)
end)

local get_batch = Memoize(function(path)
  local image = love.graphics.newImage(path)
  local batch = love.graphics.newSpriteBatch(image)
  local w, h = image:getDimensions()
  assert(w == h)
  local cell_size = w / 3

  local quads = {}
  for i = 1, 9 do
    quads[i] = sprite.utility.get_atlas_quad(i, cell_size, w, h)
  end

  return batch, quads, cell_size
end)

local get_mouse_over = function(x, y, w, h)
  return (
    input.mouse.x > x
    and input.mouse.y > y
    and input.mouse.x <= x + w
    and input.mouse.y <= y + h
  )
end

--- @class ui_button_out
--- @field is_clicked boolean
--- @field is_active boolean
--- @field is_mouse_over boolean

--- @param x integer
--- @param y integer
--- @param w integer
--- @param h integer
--- @return ui_button_out
local button = function(x, y, w, h)
  local result = {
    is_clicked = false,
    is_mouse_over = get_mouse_over(x, y, w, h),
  }

  result.is_active = result.is_mouse_over and state.are_pressed:get(x, y, w, h)

  if result.is_mouse_over then
    if Table.contains(input.mouse.button_pressed, 1) then
      state.are_pressed:set(true, x, y, w, h)
    end

    if Table.contains(input.mouse.button_released, 1)
      and state.are_pressed:get(x, y, w, h)
    then
      result.is_clicked = true
      state.are_pressed:set(false, x, y, w, h)
    end
  else
    if Table.contains(input.mouse.button_released, 1) then
      state.are_pressed:set(false, x, y, w, h)
    end
  end

  return result
end

--- @param fmt any
--- @param ... any
--- @return string
local format = function(fmt, ...)
  fmt = tostring(fmt)
  if select("#", ...) > 0 then
    fmt = fmt:format(...)
  end
  return fmt
end

----------------------------------------------------------------------------------------------------
-- [SECTION] Context
----------------------------------------------------------------------------------------------------

ui.SCALE = 4  -- has its own scale constant

--- @return ui_context
--- @nodiscard
ui.get_context = function()
  return context
end

--- @param key string
--- @param value any
ui.stack_push = function(key, value)
  if not stack[key] then
    stack[key] = {}
    context[key] = value
  end

  table.insert(stack[key], context[key])
  context[key] = value
end

--- @param key string
--- @return any
ui.stack_pop = function(key)
  if not stack[key] then
    Error("Can not pop tech.ui's stack: no stack key %q", key)
    return
  end

  if #stack[key] == 0 then
    Error("Can't pop tech.ui's stack: stack %q is empty", key)
    return
  end

  local prev = context[key]
  context[key] = table.remove(stack[key])
  return prev
end

ui.start = function()
  state.selection.max_i = 0
  state.cursor = "normal"

  context = {
    cursor_x = 0,
    cursor_y = 0,
    frame = {
      x = 0,
      y = 0,
      w = love.graphics.getWidth(),
      h = love.graphics.getHeight(),
    },
    alignment = {x = "left", y = "top"},
    font = get_font(20),
    font_size = 20,
    is_linear = false,
    line_last_h = 0,
    styles = {
      link_color = colors.blue_high,
      punctuation_color = colors.white_dim,
    },
    color = Vector.white,
  }

  stack = {}
  for key in pairs(context) do
    stack[key] = {}
  end
end

ui.finish = function()
  do
    local unclosed = {}
    for k, v in pairs(stack) do
      if #v > 0 then
        table.insert(unclosed, ("%s of %s"):format(#v, k))
      end
    end
    if #unclosed > 0 then
      Error("Unclosed ui contexts: %s", table.concat(unclosed, ", "))
    end
  end

  state.selection.is_pressed = false
  input.mouse.button_pressed = {}
  input.mouse.button_released = {}
  input.keyboard.pressed = {}
  input.keyboard.input = ""
  love.mouse.setCursor(CURSORS[state.cursor])
end

--- @param x? integer?
--- @param y? integer?
--- @param w? integer?
--- @param h? integer?
ui.start_frame = function(x, y, w, h)
  local prev = context.frame
  if not x then
    x = 0
  end
  if not y then
    y = 0
  end
  if not w then
    w = prev.w - x
  elseif w < 0 then
    w = prev.w + w
  end
  if not h then
    h = prev.h - y
  elseif h < 0 then
    h = prev.h + h
  end

  local frame = {
    x = context.cursor_x + x,
    y = context.cursor_y + y,
    w = w,
    h = h,
  }

  ui.stack_push("frame", frame)
  ui.stack_push("cursor_x", frame.x)
  ui.stack_push("cursor_y", frame.y)
  -- love.graphics.setScissor(frame.x, frame.y, frame.w, frame.h)
end

--- @param push_y? "push_frame"|"push_cursor"
--- @return ui_frame
ui.finish_frame = function(push_y)
  ui.stack_pop("cursor_x")
  local prev_cursor_y = ui.stack_pop("cursor_y")
  local prev_frame = ui.stack_pop("frame")
  if push_y == "push_frame" then
    context.cursor_y = prev_frame.y + prev_frame.h
  elseif push_y == "push_cursor" then
    context.cursor_y = prev_cursor_y
  end
  -- love.graphics.setScissor(frame.x, frame.y, frame.w, frame.h)
  return prev_frame
end

--- @param x? ui_alignment_x
--- @param y? ui_alignment_y
ui.start_alignment = function(x, y)
  ui.stack_push("alignment", {x = x or context.alignment.x, y = y or context.alignment.y})
end

ui.finish_alignment = function()
  ui.stack_pop("alignment")
end

--- @param size? integer
ui.start_font = function(size)
  size = size or 20
  local font = get_font(size)
  ui.stack_push("font", font)
  ui.stack_push("font_size", size)
  love.graphics.setFont(font)
end

ui.finish_font = function()
  ui.stack_pop("font")
  ui.stack_pop("font_size")
  love.graphics.setFont(context.font)
end

ui.start_line = function()
  ui.start_frame()
  ui.stack_push("is_linear", true)
  ui.stack_push("line_last_h", 0)
end

ui.finish_line = function()
  ui.stack_pop("is_linear")
  local old_cursor_y = context.cursor_y
  ui.finish_frame()
  context.cursor_y = old_cursor_y + ui.stack_pop("line_last_h")
end

--- @param styles ui_styles_optional
ui.start_styles = function(styles)
  ui.stack_push("styles", Table.extend({}, context.styles, styles))
end

ui.finish_styles = function()
  ui.stack_pop("styles")
end

--- @param color vector
ui.start_color = function(color)
  ui.stack_push("color", color)
  love.graphics.setColor(color)
end

ui.finish_color = function()
  ui.stack_pop("color")
  love.graphics.setColor(context.color)
end

----------------------------------------------------------------------------------------------------
-- [SECTION] UI elements
----------------------------------------------------------------------------------------------------

--- @param text string
--- @return string[]
local wrap = Memoize(function(text, font, initial_offset, width)
  if #text == 0 then return {""} end

  local font_w = font:getWidth("w")
  local max_w = math.max(1, math.floor(width / font_w))
  local first_max_w = math.floor((width - initial_offset) / font_w)

  local result = {}

  local i = 1
  while true do
    local line = text:utf_sub(i, i + (i == 1 and first_max_w or max_w) - 1)
    local not_last = i - 1 + line:utf_len() < text:utf_len()

    if not_last then
      local str_break = line:find("\n") or line:find("%s%S*$")
      if str_break and (line:sub(str_break, str_break) == "\n" or str_break > 1) then
        line = line:sub(1, str_break - 1)
        i = i + 1
      end
      i = i + line:utf_len()
    end

    table.insert(result, line)
    if not not_last then break end
  end

  return result
end)

--- @param text string
--- @param max_w integer
--- @return integer h
ui.predict_text_size = function(text, max_w)
  local wrapped = wrap(text, context.font, 0, max_w)
  return #wrapped * context.font:getHeight() * LINE_K
end

--- @param text any
ui.text = function(text, ...)
  text = format(text, ...)

  local frame = context.frame
  local font = context.font
  local alignment = context.alignment

  local wrapped = wrap(text, context.font, context.cursor_x - context.frame.x, context.frame.w)

  for i, line in ipairs(wrapped) do
    local x
    if alignment.x == "center" then
      x = frame.x + (frame.w - font:getWidth(line)) / 2
    elseif alignment.x == "right" then
      x = frame.x + frame.w - font:getWidth(line)
    else
      x = context.cursor_x
    end

    local y
    if alignment.y == "center" then
      y = frame.y + (frame.h - font:getHeight() * #wrapped) / 2 + font:getHeight() * (i - 1)
    elseif alignment.y == "bottom" then
      y = frame.y + frame.h - font:getHeight() * #wrapped + font:getHeight() * (i - 1)
    else
      y = context.cursor_y
    end

    love.graphics.print(line, x, y)

    if context.is_linear then
      if i < #wrapped then
        context.cursor_y = context.cursor_y + math.max(context.line_last_h, font:getHeight() * LINE_K)
        context.cursor_x = context.frame.x
        context.line_last_h = 0
      else
        context.cursor_x = context.cursor_x + font:getWidth("w") * text:utf_len()
        context.line_last_h = math.max(context.line_last_h, font:getHeight() * LINE_K)
      end
    else
      if alignment.y == "top" then
        context.cursor_y = context.cursor_y + font:getHeight() * LINE_K
        context.cursor_x = context.frame.x
      end
    end
    -- if alignment.y == "top" then
    --   if context.is_linear then
    --     if alignment.x == "left" then
    --       context.cursor_x = context.cursor_x + font:getWidth("w") * text:utf_len()
    --       context.line_last_h = math.max(context.line_last_h, font:getHeight() * LINE_K)
    --     end
    --   else
    --     context.cursor_y = context.cursor_y + font:getHeight() * LINE_K
    --   end
    -- end
  end
end

ui.br = function()
  ui.text(" ")
end

--- @param text string
ui.h1 = function(text)
  ui.start_font(context.font_size * 2)
  ui.start_alignment("center")
    ui.text(text)
    ui.br()
  ui.finish_alignment()
  ui.finish_font()
end

--- @param headers string[]
--- @param content any[][]
ui.table = function(headers, content)
  for y, row in ipairs(content) do
    for x, value in ipairs(row) do
      content[y][x] = tostring(value)
    end
  end

  local original_column_sizes = Fun.range(#headers)
    :map(function(x)
      return math.max(
        headers[x]:utf_len(),
        #content == 0 and 0 or Fun.range(#content)
          :map(function(y) return content[y][x]:utf_len() end)
          :max())
    end)
    :totable()

  local original_w = Fun.iter(original_column_sizes):sum()
  local total_w = math.floor(context.frame.w / context.font:getWidth("i"))
  local k = total_w / original_w

  local column_sizes = Fun.iter(original_column_sizes)
    :map(function(w) return math.floor(w * k) - 2 end)
    :totable()

  ui.text(Fun.iter(headers)
    :enumerate()
    :map(function(x, h) return h .. " " * (column_sizes[x] - h:utf_len()) .. "  " end)
    :reduce(Fun.op.concat, ""))

  ui.text("-" * (total_w))

  for _, row in ipairs(content) do
    ui.text(Fun.iter(row)
      :enumerate()
      :map(function(x, v) return "  " .. v .. " " * (column_sizes[x] - v:utf_len()) end)
      :reduce(Fun.op.concat, "")
      :utf_sub(3))
  end
end

local get_image = function(base)
  if type(base) == "string" then
    return love.graphics.newImage(base)  -- cached by kernel
  end
  return base
end

--- @param image string|love.Image
--- @param scale? integer
ui.image = function(image, scale)
  local frame = context.frame
  local alignment = context.alignment
  scale = scale or ui.SCALE

  image = get_image(image)

  local x
  if alignment.x == "center" then
    x = frame.x + (frame.w - image:getWidth() * scale) / 2
  elseif alignment.x == "right" then
    x = frame.x + frame.w - image:getWidth() * scale
  else
    x = context.cursor_x
  end

  local y
  if alignment.y == "center" then
    y = frame.y + (frame.h - image:getHeight() * scale) / 2
  elseif alignment.y == "bottom" then
    y = frame.y + frame.h - image:getHeight() * scale
  else
    y = context.cursor_y
  end

  love.graphics.draw(image, x, y, 0, scale)

  if context.is_linear then
    if alignment.x == "left" then
      context.cursor_x = context.cursor_x + image:getWidth() * scale
      context.line_last_h = math.max(context.line_last_h, image:getHeight() * scale)
    end
  else
    if alignment.y == "top" then
      context.cursor_y = context.cursor_y + image:getHeight() * scale
    end
  end
end

local ACTIVE_FRAME_PERIOD = .1

--- @param image string|love.Image
--- @param key love.KeyConstant
--- @return ui_button_out
ui.key_button = function(image, key, is_disabled)
  image = get_image(image)
  local w = image:getWidth() * ui.SCALE
  local h = image:getHeight() * ui.SCALE
  local result = button(context.cursor_x, context.cursor_y, w, h)

  if is_disabled then
    result.is_clicked = false
  else
    result.is_clicked = result.is_clicked or ui.keyboard(key)
  end

  if result.is_mouse_over and not is_disabled then
    state.cursor = "hand"
  end

  if result.is_clicked then
    state.active_frames_t:set(ACTIVE_FRAME_PERIOD, image, key)
  end

  result.is_active = result.is_active or state.active_frames_t:get(image, key)

  local font_size, text, dy
  if key:utf_len() == 1 then
    font_size = 32
    text = key:utf_upper()
    dy = ui.SCALE
  else
    font_size = 20
    text = key
    dy = 0
  end

  ui.start_frame()
    ui.image(image)
    local image_cursor_x = context.cursor_x
    local image_cursor_y = context.cursor_y
  ui.finish_frame()

  if (result.is_mouse_over and not is_disabled) or result.is_active then
    ui.start_frame(-ui.SCALE, -ui.SCALE, w + ui.SCALE * 2, h + ui.SCALE * 2)
      ui.tile(result.is_active and ACTIVE_FRAME or FRAME)
    ui.finish_frame()
  end

  ui.start_font(font_size)
  ui.start_frame(nil, nil, w - ui.SCALE, h + dy)
  ui.start_alignment("right", "bottom")
    ui.text(text)
  ui.finish_alignment()
  ui.finish_frame()
  ui.finish_font()

  context.cursor_x = image_cursor_x
  context.cursor_y = image_cursor_y

  return result
end

--- @param path string path to atlas file
ui.tile = function(path)
  local batch, quads, cell_size = get_batch(path)
  batch:clear()

  local cropped_w = math.ceil(context.frame.w / cell_size / ui.SCALE) - 2
  local cropped_h = math.ceil(context.frame.h / cell_size / ui.SCALE) - 2
  local end_x = context.frame.w / ui.SCALE - cell_size
  local end_y = context.frame.h / ui.SCALE - cell_size

  for x = 0, cropped_w do
    for y = 0, cropped_h do
      local quad_i
      if x == 0 then
        if y == 0 then
          quad_i = 1
        else
          quad_i = 4
        end
      else
        if y == 0 then
          quad_i = 2
        else
          quad_i = 5
        end
      end
      batch:add(quads[quad_i], x * cell_size, y * cell_size)
    end
  end

  for y = 0, cropped_h do
    local quad_i
    if y == 0 then
      quad_i = 3
    else
      quad_i = 6
    end
    batch:add(quads[quad_i], end_x, y * cell_size)
  end

  for x = 0, cropped_w do
    local quad_i
    if x == 0 then
      quad_i = 7
    else
      quad_i = 8
    end
    batch:add(quads[quad_i], x * cell_size, end_y)
  end

  batch:add(quads[9], end_x, end_y)

  love.graphics.draw(batch, context.frame.x, context.frame.y, 0, ui.SCALE)
end

--- @param x? integer
--- @param y? integer
ui.offset = function(x, y)
  context.cursor_x = context.cursor_x + (x or 0)
  context.cursor_y = context.cursor_y + (y or 0)
end

-- TODO consider suppressing ui.keyboard? or maybe on higher level?
--- @param container table
--- @param key any
ui.field = function(container, key, max_length)
  local is_selected = state.selection.i == state.selection.max_i
  ui.text("%s%s", container[key], is_selected and state.time % 2 >= 1 and "█" or " ")
  if is_selected then
    if input.keyboard.pressed.backspace then
      container[key] = container[key]:utf_sub(1, -2)
      input.keyboard.pressed.backspace = nil
    end

    container[key] = container[key] .. input.keyboard.input
    if max_length then
      container[key] = container[key]:utf_sub(1, max_length)
    end
    input.keyboard.pressed = {}
  end
end

--- @return boolean is_selected
ui.selector = function()
  state.selection.max_i = state.selection.max_i + 1
  if state.selection.i == state.selection.max_i then
    ui.text("> ")
  else
    ui.text("  ")
  end
  return state.selection.i == state.selection.max_i
end

--- @param values string[]
local max_length = Memoize(function(values)
  return Fun.iter(values)
    :map(function(v) return (type(v) == "string" and v or Name.game(v)):utf_len() end)
    :max()
end)

--- @param text any
--- @param ... any
--- @return ui_button_out
ui.text_button = function(text, ...)
  -- TODO bug overlap when next to each other
  text = format(text, ...)

  local result = button(
    context.cursor_x, context.cursor_y,
    context.font:getWidth("w") * text:utf_len(), context.font:getHeight()
  )

  if result.is_mouse_over then
    ui.cursor("hand")
  else
    ui.start_color(context.styles.link_color)
  end
  ui.text(text)
  if not result.is_mouse_over then
    ui.finish_color()
  end
  return result
end

--- @param possible_values string[]|table[]
--- @param container table
--- @param key any
--- @param disabled? boolean
--- @param ... string|table exceptions
--- @return boolean did_change
ui.switch = function(possible_values, container, key, disabled, ...)
  local value = container[key]
  local is_scrollable = not disabled and #possible_values - select("#", ...) > 1
  local length = max_length(possible_values)
  possible_values = Table.removed(possible_values, ...)
  local index = Table.index_of(possible_values, value) or 1
  if type(value) == "table" then
    value = Name.game(value)
  else
    value = tostring(value)
  end

  local left_button
  if is_scrollable then
    left_button = ui.text_button(" < ").is_clicked
  else
    ui.text("   ")
  end

  ui.text(value:cjust(length, " "))

  local right_button
  if is_scrollable then
    right_button = ui.text_button(" > ").is_clicked
  else
    ui.text("   ")
  end

  local is_selected = state.selection.i == state.selection.max_i

  if is_scrollable then
    local offset
    if left_button or is_selected and ui.keyboard("left") then
      offset = -1
    end

    if right_button or is_selected and ui.keyboard("right") then
      offset = 1
    end

    if offset then
      container[key] = possible_values[Math.loopmod(index + offset, #possible_values)]
      return true
    end
  end
  return false
end

--- @param options string[]
--- @return number?
ui.choice = function(options)
  local is_selected = false

  local result
  for i, option in ipairs(options) do
    local button_out = button(
      context.cursor_x, context.cursor_y,
      context.frame.w, context.font:getHeight() * LINE_K
    )

    if button_out.is_mouse_over then
      state.selection.i = state.selection.max_i + i
      is_selected = true
      state.cursor = "hand"
      love.graphics.setColor(.7, .7, .7)
    end

    if state.selection.max_i + i == state.selection.i then
      is_selected = true
      if button_out.is_active then
        option = "- " .. option
      else
        option = "> " .. option
      end
    else
      option = "  " .. option
    end

    if context.alignment.y == "center" then
      option = option .. "  "
    end

    ui.text(option)

    if button_out.is_mouse_over then
      love.graphics.setColor(1, 1, 1)
    end

    if button_out.is_clicked then
      result = state.selection.i
      break
    end
  end

  if result then return result end

  state.selection.max_i = state.selection.max_i + #options

  if state.selection.is_pressed and is_selected then
    return state.selection.i
  end
end

--- @param ... love.KeyConstant
--- @return boolean
ui.keyboard = function(...)
  for i = 1, select("#", ...) do
    local key = select(i, ...)
    if input.keyboard.pressed[key] then
      input.keyboard.pressed[key] = nil
      return true
    end
  end
  return false
end

--- @param ... integer mouse button number (love-compatible)
ui.mousedown = function(...)
  local frame = context.frame
  if not get_mouse_over(frame.x, frame.y, frame.w, frame.h) then return false end
  return ui.mousedown_anywhere(...)
end

--- @param ... integer mouse button number (love-compatible)
ui.mousedown_anywhere = function(...)
  for i = 1, select("#", ...) do
    if Table.contains(input.mouse.button_pressed, select(i, ...)) then
      return true
    end
  end
  return false
end

--- @param cursor_type? ui_cursor_type
--- @return ui_button_out
ui.mouse = function(cursor_type)
  local result = button(context.frame.x, context.frame.y, context.frame.w, context.frame.h)
  if cursor_type and result.is_mouse_over then
    state.cursor = cursor_type
  end
  return result
end

--- @param cursor_type ui_cursor_type
ui.cursor = function(cursor_type)
  local fr = context.frame
  if not get_mouse_over(fr.x, fr.y, fr.w, fr.h) then return end
  state.cursor = cursor_type
end

ui.reset_selection = function()
  state.selection.i = 1
end

ui.get_height = function()
  return context.cursor_y - context.frame.y
end

----------------------------------------------------------------------------------------------------
-- [SECTION] Event handlers
----------------------------------------------------------------------------------------------------

ui.handle_keypress = function(key)
  if key == "up" then
    state.selection.i = Math.loopmod(state.selection.i - 1, state.selection.max_i)
  elseif key == "down" then
    state.selection.i = Math.loopmod(state.selection.i + 1, state.selection.max_i)
  elseif key == "return" then
    state.selection.is_pressed = true
  end

  input.keyboard.pressed[key] = true
end

ui.handle_textinput = function(text)
  input.keyboard.input = input.keyboard.input .. text
end

ui.handle_mousemove = function(x, y)
  input.mouse.x = x
  input.mouse.y = y
end

ui.handle_mousepress = function(button_i)
  table.insert(input.mouse.button_pressed, button_i)
end

ui.handle_mouserelease = function(button_i)
  table.insert(input.mouse.button_released, button_i)
end

ui.handle_update = function(dt)
  for k, v in state.active_frames_t:iter() do
    local next_v = v - dt
    if next_v <= 0 then
      next_v = nil
    end
    state.active_frames_t:set(next_v, unpack(k))
  end
  state.time = love.timer.getTime()
end

----------------------------------------------------------------------------------------------------
-- [SECTION] Footer
----------------------------------------------------------------------------------------------------

Ldump.mark(ui, {}, ...)
return ui
