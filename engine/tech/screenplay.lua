local api = require "engine.tech.api"
local screenplay = {}

--- @class screenplay
--- @field stack (moonspeak|moonspeak_options)[]
--- @field cursor integer[]
--- @field characters table<string, entity>
local methods = {}
local mt = {__index = methods}

--- @param path string
--- @param characters table<string, entity>
--- @return screenplay
screenplay.new = function(path, characters)
  local content, _, _, err = love.filesystem.read(path)
  assert(not err, err)
  if not content then
    Error("Can't read moonspeak file %q", path)
  end

  return setmetatable({
    stack = {Moonspeak.read(content)},
    cursor = {0},
    characters = characters,
  }, mt)
end

local get_block

--- @async
--- @param subs? table<string, string>
methods.lines = function(self, subs)
  local block = get_block(self, "lines")  --[[@as moonspeak_lines]]

  for _, line in ipairs(block.lines) do
    local character
    if line.source ~= "narration" then
      character = self.characters[line.source]
    end
    local text = line.text
    if subs then
      for sub, v in pairs(subs) do
        text = text:gsub("%%" .. sub .. "%%", v)
      end
    end
    api.line(character, text)
  end
end

--- @nodiscard
--- @return table<integer, string>
methods.start_options = function(self)
  local block = get_block(self, "options")  --[[@as moonspeak_options]]
  table.insert(self.stack, block)
  table.insert(self.cursor, 0)

  return Fun.iter(block.options)
    :map(function(b) return b.text end)
    :totable()
end

methods.finish_options = function(self)
  assert(Table.last(self.stack).type == "options")
  table.remove(self.stack)
  table.remove(self.cursor)
end

--- @param n integer
methods.start_option = function(self, n)
  local block = Table.last(self.stack)  --[[@as moonspeak_options]]
  if block.type ~= "options" then
    Error(":start_option should be inside :start_options, got type %q instead", block.type)
  end
  if not block.options[n] then
    Error("No option %s, %s available", n, Table.keys(block.options))
  end
  table.insert(self.stack, block.options[n].branch)
  table.insert(self.cursor, 0)
end

methods.finish_option = function(self)
  assert(not Table.last(self.stack).type)
  table.remove(self.stack)
  table.remove(self.cursor)
  assert(Table.last(self.stack).type == "options")
end

methods.start_branches = function(self)
  local block = get_block(self, "branches")  --[[@as moonspeak_branches]]
  table.insert(self.stack, block)
  table.insert(self.cursor, 0)
end

methods.finish_branches = function(self)
  assert(Table.last(self.stack).type == "branches")
  table.remove(self.stack)
  table.remove(self.cursor)
end

methods.start_branch = function(self, n)
  local branches = Table.last(self.stack)  --[[@as moonspeak_branches]]
  assert(branches.type == "branches")
  assert(branches.branches[n].branch)
  table.insert(self.stack, branches.branches[n].branch)
  table.insert(self.cursor, 0)
end

methods.finish_branch = function(self)
  assert(not Table.last(self.stack).type)
  table.remove(self.stack)
  table.remove(self.cursor)
  assert(Table.last(self.stack).type == "branches")
end

--- @param n? integer
methods.start_single_branch = function(self, n)
  self:start_branches()
  self:start_branch(n or 1)
end

methods.finish_single_branch = function(self)
  self:finish_branch()
  self:finish_branches()
end

--- @return string
methods.literal = function(self)
  local block = get_block(self, "literal")  --[[@as moonspeak_literal]]
  return block.text
end

methods.finish = function(self)
  -- TODO redo with Error & self.cursor
  -- assert(#self.stack == 1, "Screenplay contains %s unclosed scopes;\nstack = %s" % {
  --   #self.stack - 1, Inspect(self.stack)
  -- })
  -- assert(
  --   #self.stack[1] == 0
  --   or #self.stack[1] == 1 and self.stack[1][1].type == "code",
  --   ("Expected script to end, got %s more entries;\nstack[1] = %s"):format(
  --     #self.stack[1], Inspect(self.stack[1])
  --   )
  -- )
end

get_block = function(player, type)
  local branch = Table.last(player.stack)
  player.cursor[#player.cursor] = player.cursor[#player.cursor] + 1
  local block = branch[player.cursor[#player.cursor]]
    or Error("No screenplay elements remain")  --[[@as moonspeak_element]]
  if block.type == "code" then
    player.cursor[#player.cursor] = player.cursor[#player.cursor] + 1
    block = branch[player.cursor[#player.cursor]]
      or Error("No screenplay elements remain")  --[[@as moonspeak_element]]
  end

  if block.type ~= type then
    Error("Screenplay expected %s, got %s", type, block.type)
  end

  return block
end

Ldump.mark(screenplay, {}, ...)
return screenplay
