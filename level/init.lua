--- @class level: level_base

--- @type level_definition
return {
  ldtk_path = "level/level.ldtk",
  palette = Table.do_folder("level/palette"),
  rails_new = require("level.rails").new,
  level_mix_in = function(base)
  end,
}
