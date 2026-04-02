local async = require("engine.tech.async")


local sometimes = async.sometimes()
local sometimes_deser = async.sometimes(1)
local counter = 0

local old_serialize = getmetatable(Ldump.serializer).__call
Ldump.serializer = setmetatable({
  handlers = Ldump.serializer.handlers,
}, {
  __call = function(self, x)
    local a, b = old_serialize(self, x)
    sometimes:yield()
    if a then
      if type(a) == "function" then
        counter = counter + 1
        if counter % 50 == 0 then
          return function()
            sometimes_deser:yield()
            return a()
          end
        end
      end
      return a, b
    end

    if type(x) == "userdata"
      and pcall(function() return x.typeOf end)
      and x:typeOf("ImageData")
    then
      --- @cast x love.ImageData
      local repr = x:encode("png"):getString()
      return function()
        return love.image.newImageData(
          love.filesystem.newFileData(repr, "tmp.png")
        )
      end
    end
  end,
})

local wrap = function(modname, fname, memoize)
  local old = love[modname][fname]
  love[modname][fname] = function(...)
    local result = old(...)
    local args = {...}
    Ldump.serializer.handlers[result] = function()
      return love[modname][fname](unpack(args))
    end
    return result
  end

  if memoize then
    love[modname][fname] = Memoize(love[modname][fname])
  end
end

wrap("graphics", "newImage", true)
wrap("graphics", "newQuad")
wrap("graphics", "newFont", true)
wrap("graphics", "newSpriteBatch")
wrap("graphics", "newCanvas")
