local quests = {}

--- @alias quest_status "new"|"active"|"done"|"failed"

--- @class quest
--- @field name string
--- @field objectives objective[]
--- @field status quest_status

--- @class objective
--- @field text string
--- @field status quest_status

--- @class state_quests
--- @field order string[]
--- @field has_new_content boolean
--- @field items table<string, quest>
local methods = {}
local mt = {__index = methods}

quests.new = function()
  return setmetatable({
    order = {},
    has_new_content = false,
    items = {},
  }, mt)
end

methods.new_content_is_read = function(self)
  if not self.has_new_content then return end
  for _, quest in pairs(self.items) do
    if quest.status == "new" then
      quest.status = "active"
    end
    for _, objective in ipairs(quest.objectives) do
      if objective.status == "new" then
        objective.status = "active"
      end
    end
  end
  self.has_new_content = false
end

Ldump.mark(quests, {}, ...)
return quests
