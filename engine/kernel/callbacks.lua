local colors = require("engine.tech.colors")
local ui = require("engine.tech.ui")
local memory = require("engine.tech.shaders.memory")
local saves = require("engine.kernel.saves")
local state = require("engine.state")
local safety = require "engine.tech.safety"
local cli = require "engine.kernel.cli"
local async = require "engine.tech.async"


--- @diagnostic disable-next-line:duplicate-set-field
love.load = function(args)
  Log.info("Started love.load")

  args = cli.parse(args)
  Kernel = require("engine.kernel").new(args)
  Log.info("CLI args: %s", args)

  assert = safety.assert
  Error = safety.error

  if args.profiler then
    Profile.start()
    async.lag_threshold = 1
  end

  if args.mobdebug then
    local ok, mobdebug = pcall(require, "mobdebug")
    assert(
      ok,
      "-debug option provided, but mobdebug is not found. Are you running this from ZeroBrane?"
    )

    mobdebug.start()
    async.lag_threshold = 2
  end

  if args.debug then
    Kernel:set_key_rate("space", 15)
  else
    Lp = {
      start = function() end,
      stop = function() end,
      report = function() return "" end,
    }
  end

  if args.resolution then
    love.window.updateMode(args.resolution[1], args.resolution[2], {fullscreen = false, minheight = 200, minwidth = 200})
  else
    love.window.updateMode(0, 0, {fullscreen = true, minheight = 200, minwidth = 200})
  end

  if args.youtube then
    if args.resolution then
      love.window.setPosition(200, 200)
    end
  end

  if args.playground then
    love.filesystem.load("engine/kernel/playground.lua")()
  end

  Log.info("Finished love.load")
end

local handle_event = function(event, a,b,c,d,e,f)
  if not Kernel._is_active then return end

  if event == "keypressed" then
    local scancode = b
    ui.handle_keypress(scancode)

    if Kernel.debug and
      (love.keyboard.isDown("rctrl") or love.keyboard.isDown("lctrl")) and
      scancode == "d"
    then
      Log.info("Ctrl+D")
      love.event.quit()
    end
  elseif event == "textinput" then
    ui.handle_textinput(a)
  elseif event == "mousemoved" then
    ui.handle_mousemove(a, b)
  elseif event == "mousepressed" then
    ui.handle_mousepress(c)
  elseif event == "mousereleased" then
    ui.handle_mouserelease(c)
  elseif event == "update" then
    ui.handle_update(a)
  end

  if State and State.is_loaded then
    State._world:update(
      function(_, system) return system.base_callback == event end,
      a,b,c,d,e,f
    )
  end
end

love.run = function()
  --- @diagnostic disable-next-line:undefined-field
  love.load(love.arg.parseGameArguments(arg))

  love.timer.step()
  local dt = 0
  local KEY_REPETITION_DELAY = .3
  local serialization_coroutine
  local coroutine_type

  Kernel.start_time = love.timer.getTime()
  return function()
    if Kernel._save then
      local path = Kernel._save  --[[@as string]]
      serialization_coroutine = coroutine.create(function()
        saves.write(State, path)
      end)

      coroutine_type = "сохранение"
      Kernel._save = nil
      Kernel._delays = {}

    elseif Kernel._load then
      local path = Kernel._load  --[[@as string]]
      serialization_coroutine = coroutine.create(function()
        State = saves.read(path)  --[[@as state]]
        if Kernel.gui._mode.type == "escape_menu" then
          Kernel.gui:close_menu()
        end
        State.runner:handle_loading()
      end)

      coroutine_type = "загрузка"
      Kernel._load = nil
      Kernel._delays = {}
    end

    if serialization_coroutine then
      love.event.pump()
      for name in love.event.poll() do
        if name == "quit" then
          return 0
        end
      end

      love.graphics.origin()
      love.graphics.clear()
        love.graphics.setShader(memory.love_shader)
          love.graphics.draw(Kernel.screenshot)
        love.graphics.setShader()

        love.graphics.print(coroutine_type:utf_capitalize() .. "." * math.floor((love.timer.getTime() * 4) % 4), 100, 100)
      love.graphics.present()

      coroutine.resume(serialization_coroutine)
      love.timer.step()
      if coroutine.status(serialization_coroutine) == "dead" then
        serialization_coroutine = nil
      else
        return
      end
    end

    Kernel._is_active = love.window.isVisible()
      and love.window.hasFocus()

    love.event.pump()
    for name, a,b,c,d,e,f in love.event.poll() do
      if name == "quit" then
        if not love.quit or not love.quit() then
          return a or 0
        end
      elseif name == "keypressed" then
        Kernel._delays[b] = KEY_REPETITION_DELAY
      elseif name == "keyreleased" then
        Kernel._delays[b] = nil
      end
      handle_event(name, a,b,c,d,e,f)
    end

    dt = love.timer.step()
    Kernel.cpu_time = Kernel.cpu_time + dt
    Kernel.frame_n = Kernel.frame_n + 1

    for k, v in pairs(Kernel._delays) do
      Kernel._delays[k] = math.max(0, v - dt)
      if Kernel._delays[k] == 0 then
        handle_event("keypressed", nil, k, true)
        Kernel._delays[k] = 1 / Kernel:get_key_rate(k)
      end
    end

    handle_event("update", dt)

    if Kernel._is_active then
      if V(love.graphics.getDimensions()) ~= V(Kernel.screenshot:getDimensions()) then
        Kernel.screenshot = love.graphics.newCanvas()
      end

      love.graphics.setCanvas(Kernel.screenshot)
      love.graphics.origin()
      love.graphics.clear(colors.black)
      Kernel.gui:preprocess(dt)

      handle_event("draw", dt)

      Kernel.gui:postprocess(dt)
      ui.start()
        Kernel.gui:draw_gui(dt)
        Kernel.overlay:draw(dt)
      ui.finish()
      love.graphics.setCanvas()
      love.graphics.draw(Kernel.screenshot)
    end

    do
      local t = love.timer.getTime()
        love.graphics.present()
      Kernel.cpu_time = math.max(0, Kernel.cpu_time - (love.timer.getTime() - t))
    end
  end
end

love.quit = function()
  if not Kernel.debug and Kernel.gui:attempt_exit() then return true end

  Log.info("Exited smoothly")
  Kernel:report()
  return false
end

love.errorhandler = function(msg)
  Log.fatal(debug.traceback(msg, 2))
  Kernel:report()
  -- saves.write({State}, "last_crash.ldump.gz")
  -- love.window.requestAttention()

  if Kernel.debug then return end

  local FONT = love.graphics.newFont("engine/assets/fonts/clacon2.ttf", 48)

  return function()
    love.event.pump()

    for e,a,_b,_c in love.event.poll() do
      if e == "quit" then
        return 1
      elseif e == "keypressed" and a == "return" then
        love.event.quit()
      end
    end

    love.graphics.clear()
      love.graphics.setColor(Vector.white)
      love.graphics.setFont(FONT)

      love.graphics.print("Игра потерпела крушение", 200, 200)
      love.graphics.print("нажмите [Enter] чтобы выйти", 200, 260)
    love.graphics.present()
  end
end
