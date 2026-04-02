local item   = require("engine.tech.item")


local projectile = {}

local TIMEOUT = 40

--- @param parent entity
--- @param slot string which inventory slot's content to launch
--- @param target entity|vector
--- @param speed number
--- @return promise
projectile.launch = function(parent, slot, target, speed)
  local promise = Promise.new()
  local this_item = assert(parent.inventory[slot])
  State:add(this_item, {
    layer = "fx_over",
    position = parent.position + item.anchor_offset(parent, slot),
    direction = Vector.right,
    drift = Vector.zero,
    ai = {
      observe = function(self, entity)
        local target_position if getmetatable(target) == Vector.mt then
          target_position = target + V(.5, .5)
        else
          target_position = target.position + V(.5, .5)
        end

        if State.debug then
          State.debug_overlay.points.projectile_target = {
            position = target_position,
            color = Vector.white,
            view = "grid",
          }
        end

        entity.drift = (target_position - entity.position):normalized_mut():mul_mut(speed)
        entity.rotation = math.atan2(entity.drift.y, entity.drift.x)
        if State.period:absolute(TIMEOUT, promise) or (target_position - entity.position):abs() < .25 then
          promise:resolve()
          State:remove(entity)
        end
      end,
    }
  })

  parent.inventory[slot] = nil
  this_item:animate(nil, true)

  return promise
end

Ldump.mark(projectile, {}, ...)
return projectile
