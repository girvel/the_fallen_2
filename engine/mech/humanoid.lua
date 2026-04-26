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

local blood_mark_sprites do
  local atlas = love.image.newImageData("engine/assets/sprites/blood_mark.png")
  blood_mark_sprites = {}
  for i = 1, 2 do
    blood_mark_sprites[i] = sprite.image(sprite.utility.select(atlas, i))
  end
end

humanoid.add_blood_mark = mark(function()
  return {
    codename = "blood_mark",
    boring_flag = true,
    sprite = Random.item(blood_mark_sprites),
  }
end)

local body_sprites do
  local atlas = love.image.newImageData("engine/assets/sprites/body.png")
  body_sprites = {}
  for i = 1, 1 do
    body_sprites[i] = sprite.image(sprite.utility.select(atlas, i))
  end
end

humanoid.add_body = mark(function()
  return {
    codename = "body",
    boring_flag = true,
    body_flag = true,
    sprite = Random.item(body_sprites),
  }
end)

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
