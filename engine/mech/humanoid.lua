local mark = require("engine.tech.mark")
local sprite = require("engine.tech.sprite")
local animated = require("engine.tech.animated")


local humanoid = {}

humanoid.cues = {
  blood = function()
    local e = {
      name = "Кровь",
      codename = "blood",
      slot = "blood",
      boring_flag = true,
    }
    animated.mix_in(e, "engine/assets/animations/blood")
    return e
  end,
}

local blood_mark = function()
  local atlas = love.image.newImageData("engine/assets/sprites/blood_mark.png")
  return {
    codename = "blood_mark",
    boring_flag = true,
    sprite = sprite.image(sprite.utility.select(atlas, math.random(1, 2))),
  }
end

humanoid.add_blood_mark = mark(blood_mark)

humanoid.add_body = function(self)
  local e = humanoid.add_blood_mark(self)
  if e then
    e.body_flag = true
  end
  return e
end

local humanoid_defaults = {
  transparent_flag = true,
  seethrough_flag = true,
  creature_type = "humanoid",
  cues = humanoid.cues,
  on_half_hp = humanoid.add_blood_mark,
  on_death = humanoid.add_body,
}

--- @param entity entity
humanoid.mix_in = function(entity)
  animated.mix_in(entity, "engine/assets/animations/humanoid")
  Table.defaults(entity, humanoid_defaults)
end

Ldump.mark(humanoid, {}, ...)
return humanoid
