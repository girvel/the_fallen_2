--- @async
--- @param path string
--- @return table
local read_json = function(path)
  local start_t = love.timer.getTime()

  local content, err = love.filesystem.read(path)  --[[@as string?, string]]
  if not content then error(err) end
  coroutine.yield("json", 0)

  local json_thread = love.thread.newThread [[
    local content = ...

    love.thread.getChannel('json'):push(
      require("engine.lib.json").decode(content)
    )
  ]]
  json_thread:start(content)

  while true do
    coroutine.yield("json", 0)
    local result = love.thread.getChannel('json'):pop()
    if result then
      Log.info("%.2f s | Read & parsed JSON %q", love.timer.getTime() - start_t, path)
      return result
    end
    err = json_thread:getError()
    if err then
      error(err)
    end
    love.timer.sleep(.01)
  end
end

Ldump.mark(read_json, "const", ...)
return read_json
