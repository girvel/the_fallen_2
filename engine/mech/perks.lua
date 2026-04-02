local animated = require("engine.tech.animated")


--- All perks except feats
local perks = {}

perks.passive = {
  modify_activation = function(self, entity, value, codename)
    if codename == "opportunity_attack" then
      return false
    end
    return value
  end,
}

perks.relentless = {
  modify_hp = function(self, entity, value)
    if value <= 0 and State.period:once(perks.relentless, State.combat, entity) then
      State:add(animated.fx("engine/assets/sprites/animations/relentless", entity.position))
      -- SOUND relentless
      return 1
    end
    return value
  end,
}

Ldump.mark(perks, {}, ...)
return perks
