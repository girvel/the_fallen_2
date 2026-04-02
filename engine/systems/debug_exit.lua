return Tiny.system {
  codename = "debug_exit",
  base_callback = "keypressed",
  update = function(self, _, scancode)
    if State.debug and
      (love.keyboard.isDown("rctrl") or love.keyboard.isDown("lctrl")) and
      scancode == "d"
    then
      Log.info("Ctrl+D")
      love.event.quit()
    end
  end,
}
