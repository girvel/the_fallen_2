local utf8 = require("utf8")


--- Get a UTF-8-compatible substring
--- @param str string
--- @param a integer
--- @param b? integer defaults to the length of the string
--- @return string
string.utf_sub = function(str, a, b)
  local utf_len = str:utf_len()
  if a > utf_len then
    return ""
  end
  if not b or b > utf_len then
    b = utf_len
  elseif b < 0 then
    b = b + utf_len + 1
    if b <= 0 then return "" end
  end
  return str:sub(utf8.offset(str, a), utf8.offset(str, b + 1) - 1)
end

--- Get UTF-8-compatible length of the string
--- @param str string
--- @return integer
string.utf_len = function(str)
  return utf8.len(str)
end

local ru_lower = "абвгдеёжзийклмнопрстуфхцчшщъыьэюя"
local ru_upper = "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ"

--- Put all UTF-8 characters of `str` into lowercase
--- @param str string
--- @return string
string.utf_lower = function(str)
  str = str:lower()
  for i = 1, string.utf_len(ru_lower) do
    str = str:gsub(
      string.utf_sub(ru_upper, i, i),
      string.utf_sub(ru_lower, i, i)
    )
  end
  return str
end

--- Put all UTF-8 characters of `str` into uppercase
--- @param str string
--- @return string
string.utf_upper = function(str)
  str = str:upper()
  for i = 1, string.utf_len(ru_lower) do
    str = str:gsub(
      string.utf_sub(ru_lower, i, i),
      string.utf_sub(ru_upper, i, i)
    )
  end
  return str
end

--- Put the first UTF-8 character of `str` into uppercase
--- @param str string
--- @return string
string.utf_capitalize = function(str)
  return str:utf_sub(1, 1):utf_upper() .. str:utf_sub(2)
end

--- @param str string
--- @param prefix string
--- @return boolean
string.starts_with = function(str, prefix)
  return str:sub(1, #prefix) == prefix
end

--- @param str string
--- @param postfix string
--- @return boolean
string.ends_with = function(str, postfix)
  return str:sub(-#postfix, -1) == postfix
end

--- @param str string
--- @param pat string
--- @param plain boolean?
--- @return string[]
string.split = function(str, pat, plain)
  local t = {}

  while true do
    local pos1, pos2 = str:find(pat, 1, plain or false)

    if not pos1 or pos1 > pos2 then
      t[#t + 1] = str
      return t
    end

    t[#t + 1] = str:sub(1, pos1 - 1)
    str = str:sub(pos2 + 1)
  end
end

--- @param str string
--- @return string[]
string.tokens = function(str)
  return str:strip():split("%s+")
end

--- @param str string
--- @param int integer
--- @param padstr? string
--- @return string
string.ljust = function(str, int, padstr)
  padstr = padstr or " "
  assert(padstr:utf_len() == 1, "TODO")
  return str .. padstr * (int - str:utf_len())
end

--- @param str string
--- @param int integer
--- @param padstr? string
--- @return string
string.cjust = function(str, int, padstr)
  padstr = padstr or " "
  assert(padstr:utf_len() == 1, "TODO")
  local total_pad = int - str:utf_len()
  return (padstr * math.floor(total_pad / 2)) .. str .. (padstr * math.ceil(total_pad / 2))
end

--- @param str string
--- @return string
string.lstrip = function(str)
  return select(1, str:gsub("^%s+", ""))
end

--- @param str string
--- @return string
string.rstrip = function(str)
  return select(1, str:gsub("%s+$", ""))
end

--- @param str string
--- @return string
string.strip = function(str)
  return string.rstrip(string.lstrip(str))
end

--- @param str string
--- @return string
string.indent = function(str)
  return table.concat(Fun.iter(str / "\n")
    :map(function(line) return "  " .. line end)
    :totable(), "\n")
end


local mt = getmetatable("")

mt.__mul = function(a, b)
  return a:rep(b)
end

mt.__div = function(a, b)
  return string.split(a, b, true)
end
