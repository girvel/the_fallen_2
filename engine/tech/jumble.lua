local morphems = ([[
  lor em ip sum dol or sit am et con sect et ur adip isc ing el it sed do eius mod temp in cid unt
  ut lab ore et magn qua ut nim ven iam minim s nos trud exer
]]):tokens()

local avg_morphem_len = Fun.iter(morphems)
  :map(function(m) return m:utf_len() end)
  :sum() / #morphems

--- @diagnostic disable-next-line:newline-call
local punctuation = ("\n `~!@#$%^&*()_-+=[]{};:'\",.<>/?\\|"):to_set()

--- @param word string
--- @param ratio number
local jumble_word = function(word, ratio)
  if #word == 0 or not Random.chance(ratio) then
    return word
  end

  local morphems_n = math.ceil(word:utf_len() / avg_morphem_len)
  local result = ""
  for _ = 1, morphems_n do
    result = result .. Random.item(morphems)
  end
  if word:utf_sub(1, 1):utf_is_upper() and (word:utf_len() == 1 or not word:utf_is_upper()) then
    result = result:utf_sub(1, 1):utf_upper() .. result:utf_sub(2)
  end
  return result
end

--- @param text string
--- @param ratio number
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
    result = result .. jumble_word(current, ratio)
  else
    result = result .. current
  end
  return result
end

Ldump.mark(jumble, {}, ...)
return jumble
