--- Table extension modules
---
--- Contains additional functions for complex table manipulation
local _table = {}

--- Returns the pairs-based entry count
--- @param t table
--- @return integer
_table.count = function(t)
  local result = 0
  for _ in pairs(t) do
    result = result + 1
  end
  return result
end

--- Copies all fields into the base mutating first argument
-- Modifies first argument, copying all the fields via pairs of the following arguments in order
-- from left to right.
--- @param base table table to be changed
--- @param extension table table to copy fields from
--- @param ... table following extensions
--- @return table base the base table
_table.extend = function(base, extension, ...)
  if extension == nil then return base end
  for k, v in pairs(extension) do
    base[k] = v
  end
  return _table.extend(base, ...)
end

--- Same as .extend, but asserts no collisions
_table.extend_strict = function(base, extension, ...)
  if extension == nil then return base end
  for k, v in pairs(extension) do
    if base[k] then
      assert(false, "Table.extend_strict collision on key " .. k)
    end
    base[k] = v
  end
  return _table.extend_strict(base, ...)
end

--- Sets values in base if they are nil
--- @generic T: table
--- @param base table?
--- @param defaults T
--- @return T
_table.defaults = function(base, defaults)
  base = base or {}
  for k, v in pairs(defaults) do
    if base[k] == nil then
      base[k] = v
    end
  end
  return base
end

--- Concatenates lists into the base
-- Modifies first argument, copying all the fields via ipairs of the following arguments in order
-- from left to right
--- @param base table table to be changed
--- @param extension table table to copy fields from
--- @param ... table following extensions
--- @return table base the base table
_table.concat = function(base, extension, ...)
  if extension == nil then return base end
  for _, v in ipairs(extension) do
    table.insert(base, v)
  end
  return _table.concat(base, ...)
end

--- Concatenates and extends into the base
-- Modifies first argument, concatenating integer fields and copying all the key-value data, both 
-- in order from left to right
--- @param base table table to be changed
--- @param extension table? table to copy fields from
--- @param ... table following extensions
--- @return table base the base table
_table.join = function(base, extension, ...)
  if extension == nil then return base end
  local length = #base
  for k, v in pairs(extension) do
    if type(k) == "number" and math.floor(k) == k then
      base[length + k] = v
    else
      assert(not base[k], ("collision during Table.join on key %s"):format(k))
      base[k] = v
    end
  end
  return _table.join(base, ...)
end

--- Copies all fields to the base, merging them with existing tables recursively and mutating 
--- first argument
--- @param base table table to be changed
--- @param extension table table to copy fields from
--- @param ... table following extensions
--- @return table base the base table
_table.merge = function(base, extension, ...)
  if extension == nil then return base end
  for k, v in pairs(extension) do
    if base[k] and type(base[k]) == "table" and type(v) == "table" then
      base[k] = _table.merge({}, base[k], v)
    else
      base[k] = v
    end
  end
  return _table.merge(base, ...)
end

--- Return the first index of the item in the table
--- @generic T
--- @param t T[]
--- @param item T
--- @return integer?
_table.index_of = function(t, item)
  for i, x in ipairs(t) do
    if x == item then
      return i
    end
  end
  return nil
end

--- Return one of the keys of the item in the table
--- @param t table
--- @param item any
--- @return any
_table.key_of = function(t, item)
  for k, v in pairs(t) do
    if v == item then
      return k
    end
  end
  return nil
end

--- Checks if the two tables are isomorphic on the first level on recursion
--- @param t1 table
--- @param t2 table
--- @return boolean
_table.shallow_same = function(t1, t2)
  for k, v in pairs(t1) do
    if v ~= t2[k] then return false end
  end
  for k, _ in pairs(t2) do
    if not t1[k] then return false end
  end
  return true
end

--- @generic T: table
--- @param t T
--- @return T
_table.shallow_copy = function(t)
  local result = setmetatable({}, getmetatable(t))
  for k, v in pairs(t) do
    result[k] = v
  end
  return result
end

--- @generic T: table
--- @param o T
--- @param seen? table
--- @return T
_table.deep_copy = function(o, seen)
  seen = seen or {}
  if o == nil then return nil end
  if seen[o] then return seen[o] end

  local no
  if type(o) == 'table' then
    no = {}
    seen[o] = no

    for k, v in next, o, nil do
      no[_table.deep_copy(k, seen)] = _table.deep_copy(v, seen)
    end
    setmetatable(no, _table.deep_copy(getmetatable(o), seen))
  else
    no = o
  end
  return no
end

--- @param t table
--- @param item any
--- @return table
_table.remove = function(t, item)
  for k, v in pairs(t) do
    if v == item then
      if type(k) == "number" and math.ceil(k) == k then
        table.remove(t, k)
      else
        t[k] = nil
      end
    end
  end
  return t
end

--- @param t table
--- @param ... any
--- @return table
_table.removed = function(t, ...)
  local result = Table.shallow_copy(t)
  for i = 1, select("#", ...) do
    Table.remove(result, select(i, ...))
  end
  return result
end

--- Uses pairs
_table.remove_pair = function(t, item)
  for k, v in pairs(t) do
    if v == item then
      t[k] = nil
    end
  end
end

--- @param t any[]
--- @param i integer
_table.remove_breaking_at = function(t, i)
  t[i] = t[#t]
  t[#t] = nil
end

--- @param t any[]
--- @param item any
_table.remove_breaking = function(t, item)
  Table.remove_breaking_at(t, assert(Table.index_of(t, item)))
end

--- @param t any[]
--- @param indexes integer[]
_table.remove_breaking_in_bulk = function(t, indexes)
  for i = #indexes, 1, -1 do
    _table.remove_breaking_at(t, indexes[i])
  end
end

--- Uses overridable equality operator
--- @param t table
--- @param item any
--- @return boolean
_table.contains = function(t, item)
  for _, x in ipairs(t) do
    if x == item then
      return true
    end
  end
  return false
end

--- @generic T
--- @param t T[]
--- @return T
_table.last = function(t)
  return t[#t]
end

--- @return table
_table.pack = function(...)
  local n = select("#", ...)
  local result = {}
  for i = 1, n do
    result[i] = select(i, ...)
  end
  return result
end

--- Transforms list into a set
--- @generic T
--- @param list T[]
--- @return table<T, true?>
_table.set = function(list)
  local result = {}
  for _, v in ipairs(list) do
    result[v] = true
  end
  return result
end

--- @param t table
--- @param fields string[]
_table.assert_fields = function(t, fields)
  local missing_fields = {}
  for _, field in ipairs(fields) do
    if t[field] == nil then
      table.insert(missing_fields, field)
    end
  end
  if #missing_fields > 0 then
    Error("fields %s are required for %s", table.concat(missing_fields, ", "), t)
  end
end

--- @param path string
--- @return table<string, any>
_table.do_folder = function(path)
  local result = {}
  for _, name in ipairs(love.filesystem.getDirectoryItems(path)) do
    local full_path = path .. "/" .. name
    if love.filesystem.getInfo(full_path, "directory") then
      result[name] = _table.do_folder(full_path)
    elseif name:ends_with(".lua") then
      result[name:sub(1, -5)] = love.filesystem.load(full_path)()
    end
  end
  return result
end

--- @generic T: table
--- @param t T
--- @param item_name string?
--- @return T
_table.strict = function(t, item_name)
  return setmetatable(t, {
    __index = function(self, index)
      Error("There's no %s %q", item_name or "item", index)
    end,
  })
end

--- @generic T
--- @param t table<T, any>
--- @return T[]
_table.keys = function(t)
  local result = {}
  for k in pairs(t) do
    table.insert(result, k)
  end
  return result
end

return _table
