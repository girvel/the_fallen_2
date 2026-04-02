local vector = require("engine.lib.vector")

local iteration = {}

--- Guarantees that returned vectors are not references anywhere else
--- @param radius? integer
--- @return fun(): vector
iteration.rhombus = function(radius)
  return coroutine.wrap(function()
    coroutine.yield(vector.zero:copy())

    for r = 1, (radius or 50) do
      for x = 0, r - 1 do
        coroutine.yield(vector.new(x, x - r))
      end

      for x = r, 1, -1 do
        coroutine.yield(vector.new(x, r - x))
      end

      for x = 0, 1 - r, -1 do
        coroutine.yield(vector.new(x, x + r))
      end

      for x = -r, -1 do
        coroutine.yield(vector.new(x, -r - x))
      end
    end
  end)
end

--- Guarantees that returned vectors are not references anywhere else
--- @param radius? integer
--- @return fun(): vector
iteration.rhombus_edge = function(radius)
  return coroutine.wrap(function()
    for x = 0, radius - 1 do
      coroutine.yield(vector.new(x, x - radius))
    end

    for x = radius, 1, -1 do
      coroutine.yield(vector.new(x, radius - x))
    end

    for x = 0, 1 - radius, -1 do
      coroutine.yield(vector.new(x, x + radius))
    end

    for x = -radius, -1 do
      coroutine.yield(vector.new(x, -radius - x))
    end
  end)
end

return iteration
