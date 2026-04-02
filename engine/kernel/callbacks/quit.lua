return function()
  if not State.debug and State.mode:attempt_exit() then return true end

  Log.info("Exited smoothly")
  Kernel:report()
  return false
end
