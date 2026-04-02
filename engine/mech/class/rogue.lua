local class = require("engine.mech.class")


local rogue = {}

rogue.hit_dice = class.hit_dice(8)

Ldump.mark(rogue, "const", ...)
return rogue
