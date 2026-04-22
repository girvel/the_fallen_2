local animated = require("engine.tech.animated")


--- All perks except feats
local perks = {}

--- Does not use opportunity attacks
perks.passive = {
  -- TODO should probably accept action itself instead of codename
  modify_activation = function(self, entity, value, action)
    if action.codename == "opportunity_attack" then
      return false
    end
    return value
  end,
}

perks.relentless = {
  modify_resources = function(self, entity, resources, rest_type)
    if rest_type == "long" then
      resources.relentless = (resources.relentless or 0) + 1
    end
    return resources
  end,

  modify_hp = function(self, entity, value)
    if value <= 0 and entity.resources.relentless > 0 then
      entity.resources.relentless = entity.resources.relentless - 1
      State:add(animated.fx("engine/assets/animations/relentless", entity.position))
      -- SOUND relentless
      return 1
    end
    return value
  end,
}

Ldump.mark(perks, {}, ...)
return perks
