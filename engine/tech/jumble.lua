local morphems = ([[
  bo lo ka da fa ro
]]):tokens()

--- @diagnostic disable-next-line:newline-call
local punctuation = ("\n `~!@#$%^&*()_-+=[]{};:'\",.<>/?\\|"):to_set()

local jumble_word = function(word, ratio)
  if #word == 0 or not Random.chance(ratio) then
    return word
  end

  return "REPLACED"
end

--- @param text string
local jumble = function(text, ratio)
  local result = ""
  local current = ""
  local is_word
  for i = 1, text:utf_len() do
    local char = text:utf_sub(i, i)
    if punctuation[char] then
      if is_word then
        result = result .. jumble_word(current, ratio)
        current = ""
        is_word = false
      end
      current = current .. char
    else
      if not is_word then
        result = result .. current
        current = ""
        is_word = true
      end
      current = current .. char
    end
  end
  if is_word then
    Log.traces(Inspect(current))
    result = result .. jumble_word(current, ratio)
  else
    result = result .. current
  end
  return result
end

Ldump.mark(jumble, {}, ...)
return jumble
