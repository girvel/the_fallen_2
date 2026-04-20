local colors = require("engine.tech.colors")
local floater = require("engine.tech.floater")
local item   = require "engine.tech.item"


local health = {}

health.COLOR_DAMAGE = colors.red_high
health.COLOR_HEALING = colors.green_high

--- Restores `amount` of `target`'s health with FX
--- @param target entity
--- @param amount integer
--- @return nil
health.heal = function(target, amount)
  local value = target.hp + amount
  if target.get_max_hp then
    value = math.min(target:get_max_hp(), value)
  end
  health.set_hp(target, value)
  if target.position then
    State:add(floater.new("+" .. amount, target.position, health.COLOR_HEALING))
  end
end

--- Inflict fixed damage; handles hp, death and FX
--- @param target entity
--- @param amount number
--- @param source? entity
--- @param is_critical? boolean whether to display damage as critical
health.damage = function(target, amount, source, is_critical)
  amount = math.max(0, amount)
  Log.debug("%s damage to %s", amount, Name.code(target))

  if source then
    State.hostility:register(source, target)
  end

  local repr = tostring(amount)
  if is_critical then
    repr = repr .. "!"
  end

  State:add(floater.new(repr, target.position, health.COLOR_DAMAGE))

  if health.set_hp(target, target.hp - amount)
    and source
    and source.xp
    and target.xp_reward
  then
    source.xp = source.xp + target.xp_reward
  end
end

--- Set HP, update blood cue, handle modifiers
--- @param target entity
--- @param value integer
--- @return boolean is_dead
health.set_hp = function(target, value)
  if target.modify then
    value = target:modify("hp", value)
  end

  local before = target.hp
  target.hp = value

  if target.hp > 0 then
    if target.get_max_hp then
      local half = target:get_max_hp() / 2
      item.set_cue(target, "blood", target.hp <= half)
      if target.on_half_hp and before and before > half and target.hp <= half then
        target:on_half_hp()
      end
    end
    return false
  end

  if before and before > 0 and target.on_death then
    target:on_death()
  end

  if target.player_flag then
    State.mode:player_has_died()
    return false
  end

  if target.essential_flag then
    target:animation_freeze("lying")
    if State:in_combat(target) then
      State:remove_from_combat(target)
    end
    return false
  end

  if target.inventory then
    local to_drop = {}
    for _, slot in ipairs(item.DROPPING_SLOTS) do
      local this_item = target.inventory[slot]
      if this_item and not this_item.no_drop_flag then
        table.insert(to_drop, slot)
      end
    end
    item.drop(target, unpack(to_drop))
  end

  State:remove(target)
  if not target.boring_flag then
    Log.info(Name.code(target) .. " is killed")
  end
  return true
end

--- @param source entity attacking entity
--- @param target entity attacked entity
--- @param attack_roll d
--- @param damage_roll d
--- @return boolean did_hit
--- @return boolean is_critical
--- @return integer damage
health.attack_precog = function(source, target, attack_roll, damage_roll)
  if target.modify then
    attack_roll = target:modify("incoming_attack_roll", attack_roll, source)
  end

  local attack = attack_roll:roll()
  local is_nat_20 = attack == attack_roll:max()
  local is_nat_1 = attack == attack_roll:min()
  local ac = target.get_armor and target:get_armor() or target.armor or 0

  Log.info("%s / %s | %s attacks %s", attack, ac, source, target)

  if is_nat_1 then
    return false, true, 0
  end

  if attack < ac and not is_nat_20 then
    return false, false, 0
  end

  local is_critical = is_nat_20 and attack >= ac
  if is_critical then
    damage_roll = damage_roll + D.new(damage_roll.dice, 0)
  end

  local damage_amount = damage_roll:roll()
  if source.modify then
    damage_amount = source:modify("outgoing_damage", damage_amount, target, is_critical)
  end

  return true, is_critical, damage_amount
end

--- @param source entity attacking entity
--- @param target entity attacked entity
--- @param did_hit boolean
--- @param is_critical boolean
--- @param damage integer
health.attack_enact = function(source, target, did_hit, is_critical, damage)
  if not did_hit then
    State:add(floater.new(is_critical and "!" or "-", target.position, health.COLOR_DAMAGE))
    return
  end

  health.damage(target, damage, source, is_critical)
end

--- Attacks with given attack/damage rolls
--- @param source entity attacking entity
--- @param target entity attacked entity
--- @param attack_roll table
--- @return boolean did_hit true if attack landed
health.attack = function(source, target, attack_roll, damage_roll)
  local did_hit, is_crit, damage = health.attack_precog(source, target, attack_roll, damage_roll)
  health.attack_enact(source, target, did_hit, is_crit, damage)
  return did_hit
end

--- @param source entity
--- @param target entity
--- @param ability ability
--- @param save_dc integer
--- @param damage integer (because the roll is typically shared & unmodified for any separate target)
--- @return boolean fail
--- @return integer damage
health.attack_save_precog = function(source, target, ability, save_dc, damage)
  local fail = not target.saving_throw or not target:saving_throw(ability, save_dc)
  if not fail then
    damage = math.floor(damage / 2)
  end
  return fail, damage
end

--- @param source entity
--- @param target entity
--- @param fail boolean
--- @param damage integer
health.attack_save_enact = function(source, target, fail, damage)
  health.damage(target, damage, source, fail)
end

--- Attacks through making the target roll the saving throw; halves the damage on success
--- @param source entity
--- @param target entity
--- @param ability ability
--- @param save_dc integer
--- @param damage integer (because the roll is typically shared & unmodified for any separate target)
--- @return boolean did_fail whether the target failed the saving throw
health.attack_save = function(source, target, ability, save_dc, damage)
  local fail, damage_final = health.attack_save_precog(source, target, ability, save_dc, damage)
  health.attack_save_enact(source, target, fail, damage_final)
  return fail
end

Ldump.mark(health, {}, ...)
return health
