local constants = {
  --- Width/height of a sprite fitting in a single grid cell
  cell_size = 16,
  --- Reference period to yield from coroutine for it to be smooth (for loading screens & like)
  yield_period = 1/60,
}

Ldump.mark(constants, {}, ...)
return constants
