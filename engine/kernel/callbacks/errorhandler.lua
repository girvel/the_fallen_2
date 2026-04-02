return function(msg)
  Log.fatal(debug.traceback(msg, 2))
  Kernel:report()
  -- saves.write({State}, "last_crash.ldump.gz")
  -- love.window.requestAttention()

  if State.debug then return end

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
