Log = require("engine.lib.log")
Ldump = require("engine.lib.ldump")
local KB = 1024
Ldump.upvalue_warning_threshold = 1024 * KB

Constants = require("engine.tech.constants")


Kernel = require("engine.kernel").new()


Argparse = require("engine.lib.argparse")

Common = require("engine.lib.common")

CompositeMap = require("engine.lib.composite_map")
Ldump.mark_module("engine.lib.composite_map", "const")

D = require("engine.lib.d")
Ldump.mark_module("engine.lib.d", "const")

Fun = require("engine.lib.fun")

Grid = require("engine.lib.grid")
Ldump.mark_module("engine.lib.grid", "const")

Inspect = function(x) return require("engine.lib.inspect")(x, {keys_limit = 20, depth = 4}) end

Iteration = require("engine.lib.iteration")

Json = require("engine.lib.json")

Lp = require("engine.lib.line_profiler")
Lp.time_function = love.timer.getTime

Math = require("engine.lib.math")

Memoize = require("engine.lib.memoize")

Moonspeak = require("engine.lib.moonspeak")

Name = require("engine.lib.name")

Polygon = require("engine.lib.polygon")
Ldump.mark_module("engine.lib.polygon", "const")

Profile = require("engine.lib.profile")

Promise = require("engine.lib.promise")
Ldump.mark_module("engine.lib.promise", "const")

Random = require("engine.lib.random")

require("engine.lib.string")

Table = require("engine.lib.table")

Timer = require("engine.lib.timer")

Tiny = require("engine.lib.tiny")
Ldump.mark_module("engine.lib.tiny", {
  systemTableKey = {},
})
Tiny.worldMetaTable.__serialize = function(self)
  local entities = self.entities
  return function()
    local systems = assert(love.filesystem.load("engine/systems/init.lua"))()
    for _, system in ipairs(systems) do
      system.world = nil
    end

    local result = Tiny.world(unpack(systems))
    for _, e in ipairs(entities) do
      result:add(e)
    end
    return result
  end
end

Vector = require("engine.lib.vector")
V = Vector.new
Ldump.mark_module("engine.lib.vector", "const")

-- assert & Error are assigned in engine/kernel/callbacks/load.lua
-- TODO they shouldn't be, debug mode & CLI args are kernel level data
Error = function(msg, ...) error(msg:format(...)) end  -- placeholder

Log.info("Initialized globals")
