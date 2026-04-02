local async = require("engine.tech.async")


local no_op = {}

--- @class no_op_ai
local methods = {}
no_op.mt = {__index = methods}

--- @return no_op_ai
no_op.new = function()
  return setmetatable({}, no_op.mt)
end

methods.control = function(self, entity)
  async.sleep(1)
end

Ldump.mark(no_op, {mt = "const"}, ...)
return no_op
