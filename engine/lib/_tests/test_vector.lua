describe("Vector library", function()
  _G.unpack = table.unpack
  local vector = require("engine.lib.vector")
  local v = vector.new

  it("does arithmetics", function()
    assert.equal(v(1, 1), vector.one)
    assert.equal(v(2, 2), v(3, 1) + v(-1, 1))
    assert.equal(v(0, 2), v(3, 1) - v(3, -1))
    assert.equal(v(3, 6), v(1, 2) * 3)
    assert.equal(v(3, 3), v(12, 12) / 4)
  end)

  it("Vector.use uses function separately on xs and ys and builds vector from the result", function()
    assert.equal(
      v(2, 3),
      vector.use(math.max, v(1, 2), v(2, -3), v(0, 3))
    )
  end)
end)
