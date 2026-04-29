local morphems = ([[
  bo lo ka da fa ro
]]):tokens()

--- @param text string
local jumble = function(text, ratio)
  local words = text:tokens()
  local result = ""
  for i, word in ipairs(words) do
    local new_word
    if Random.chance(ratio) then
      new_word = Random.item(morphems)
    else
      new_word = word
    end
    result = result .. " " .. new_word
  end
  return result
end

Ldump.mark(jumble, {}, ...)
return jumble
