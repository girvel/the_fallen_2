local uid = {}

--- @class state_uid
--- @field last integer
local methods = {}
uid.mt = {__index = methods}

--- @return state_uid
uid.new = function()
  return setmetatable({
    last = 0,
  }, uid.mt)
end

--- @return integer
methods.next = function(self)
  self.last = self.last + 1
  return self.last
end

Ldump.mark(uid, {mt = "const"}, ...)
return uid
