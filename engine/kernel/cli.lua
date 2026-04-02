local cli = {}

cli.parse = function(args)
  local parser = Argparse()
    :name("love")
    :description("Launch the game")

  parser
    :argument(
      "game root path",
      "not required; windows version of LOVE passes the path argument, linux doesn't. This argument"
      .. "makes them compatible")
    :args("?")

  parser:flag(
    "-d --debug",
    "Show FPS; no confirmation on exit, exit through Ctrl+D enabled;"
  )

  parser:option(
    "-s --enable-scenes"
  ):args("+"):default({})

  parser:option(
    "-S --disable-scenes"
  ):args("+"):default({})

  parser:option(
    "-c --checkpoint"
  ):args("?")

  parser:flag(
    "-p --profiler",
    "Run the game with profiler"
  )

  parser:flag(
    "-A --disable-ambient",
    "Disables background music"
  )

  parser:option(
    "-r --resolution"
  ):args("?")

  args[-2] = nil
  args[-1] = nil

  local is_mobdebug_attached = Table.last(args) == "-debug"
  if is_mobdebug_attached then
    table.remove(args)
  end

  local result = parser:parse(args)

  if result.resolution then
    result.resolution = result.resolution[1] or "1080p"
    local builtin_resolutions = {
      ["1080p"] = V(1920, 1080),
      ["720p"] = V(1280, 720),
      ["360p"] = V(640, 360),
    }

    assert(builtin_resolutions[result.resolution] or result.resolution:find("x"))

    result.resolution = builtin_resolutions[result.resolution]
      or Vector.own(Fun.iter(result.resolution / "x"):map(tonumber):totable())
  end

  result.mobdebug = is_mobdebug_attached
  result.checkpoint = result.checkpoint and result.checkpoint[1]

  return result
end

return cli
