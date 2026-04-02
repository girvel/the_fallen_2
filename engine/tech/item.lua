local level = require("engine.tech.level")
local animated = require "engine.tech.animated"
local interactive = require "engine.tech.interactive"


local item = {}

item.DROPPING_SLOTS = {"hand", "offhand", "head", "body"}

-- TODO replace tags.heavy with like tag_heavy or flag_heavy

--- @alias item item_strict|table

--- @class item_strict: entity_strict
--- @field damage_roll? d present only in weapons
--- @field bonus? integer bonus damage
--- @field tags table<string, true>
--- @field slot item_slot
--- @field anchor? anchor overrides .slot for anchoring
--- @field projectile_factory? fun(): entity present only in ranged weapons
--- @field no_drop_flag? true
--- @field animated_independently_flag? true

--- @alias inventory_slot "hand"|"offhand"|"head"|"right_pocket"|"hair"|"skin"|"body"|"bag"|cue_slot
--- @alias item_slot "hands"|inventory_slot

item.mixin = function(animation_path)
  return Table.extend(
    animated.mixin(animation_path),
    interactive.mixin(function(self, other)
      if not item.give(other, self) then return end
      level.remove(self)
      self.position = nil
      State:add(self)
    end),
    {
      inventory = {
        highlight = item.cues.highlight(),
      },
      tags = {},
      direction = Vector.right,  -- needed to initially animate into idle_right instead of idle
    }
  )
end

--- @param slot string
--- @return item
item.mixin_min = function(slot)
  return {
    tags = {},
    direction = Vector.right,
    slot = slot,
  }
end

--- @param damage_roll d
--- @param bonus integer?
--- @return item
item.natural_weapon = function(damage_roll, bonus)
  return {
    damage_roll = damage_roll,
    bonus = bonus,

    codename = "natural_weapon",
    boring_flag = true,
    no_drop_flag = true,
    slot = "hands",
    tags = {},
  }
end

--- @param entity entity
--- @param slot inventory_slot
item.anchor_offset = function(entity, slot)
  local this_item = entity.inventory[slot]
  if not this_item then
    Error("anchor_offset for empty %s's inventory slot %s", Name.code(entity), slot)
    return Vector.zero
  end

  local parent_anchor = entity.sprite.anchors[this_item.anchor or slot]
  if not parent_anchor then return Vector.zero end

  local item_anchor = this_item.sprite and this_item.sprite.anchors.parent
  if not item_anchor then return Vector.zero end

  return (parent_anchor - item_anchor):div_mut(Constants.cell_size)
end

--- @param parent entity
--- @param ... string | integer
--- @return boolean
item.drop = function(parent, ...)
  local arg_len = select("#", ...)
  if arg_len == 0 then return true end

  local present_items = {}
  local present_slots = {}

  for i = 1, arg_len do
    local slot = select(i, ...)
    local this_item = parent.inventory[slot]
    if this_item then
      table.insert(present_items, this_item)
      table.insert(present_slots, slot)
    end
  end

  local dropped_n = item.drops(parent.position, unpack(present_items))
  for i = 1, dropped_n do
    parent.inventory[present_slots[i]] = nil
  end
  return dropped_n == #present_items
end

--- @param position vector
--- @param ... item
--- @return integer
item.drops = function(position, ...)
  local arg_len = select("#", ...)
  if arg_len == 0 then return 0 end

  local bfs = State.grids.solids:bfs(position)
  bfs()

  for i = 1, arg_len do
    local this_item = select(i, ...)

    do ::redo::
      local p, e = bfs()
      if not p then return i - 1 end
      if e and not e.moving_flag then
        bfs:discard()
        goto redo
      end
      if State.grids.items[p] then
        goto redo
      end

      this_item.position = p
      this_item.grid_layer = "items"
      State:add(this_item)
    end
  end

  return select("#", ...)
end

local give_to_hands, give_to_a_hand

--- Put item in the entity's inventory. 
--- Drops the item if entity can't take the item; contains logic for taking weapons.
--- @param entity entity entity to receive the item
--- @param this_item item item to give
--- @return boolean success did item make it to the entity's inventory
item.give = function(entity, this_item)
  local is_free
  local slot = this_item.slot
  if slot == "hands" then
    is_free, slot = give_to_hands(entity, this_item)
  elseif slot == "offhand" or slot == "hand" then
    is_free = give_to_a_hand(slot, entity, this_item)
  else
    is_free = not entity.inventory[slot] or item.drop(entity, slot)
  end

  if not is_free then return false end

  entity.inventory[slot] = this_item

  this_item.direction = entity.direction
  this_item:animate()
  this_item:animation_set_paused(entity.animation and entity.animation.paused)

  return true
end

--- Sets whether given cue should (not) be or displayed
---
--- Cues are simplistic items that exist for visualization only, like blood marks or a highlight.
--- @param entity entity
--- @param slot cue_slot
--- @param value boolean
--- @return nil
item.set_cue = function(entity, slot, value)
  if not item.existing_cues[slot] then
    Error("Slot %q is not supported", slot)
  end

  local factory = entity.cues and entity.cues[slot] or item.cues[slot]
  if not factory then return end

  if not entity.inventory then entity.inventory = {} end
  if (not not value) == (not not entity.inventory[slot]) then return end
  if value then
    item.give(entity, State:add(factory()))
  else
    State:remove(entity.inventory[slot])
    entity.inventory[slot] = nil
  end
end

--- @enum (key) cue_slot
item.existing_cues = {
  highlight = true,
  blood = true,
}

item.cues = {
  highlight = function()
    return Table.extend(
      animated.mixin("engine/assets/sprites/animations/highlight", 1),
      {
        name = "Хайлайт",
        codename = "highlight",
        slot = "highlight",
        animated_independently_flag = true,
        boring_flag = true,
      }
    )
  end,
}

--- @return boolean, item_slot?
give_to_hands = function(entity, this_item)
  local inv = entity.inventory
  local hand = inv.hand
  local offhand = inv.offhand

  if this_item.tags.two_handed then
    return item.drop(entity, "hand", "offhand"), "hand"
  end

  if not entity:modify("light", this_item.tags.light, this_item) then
    if offhand and offhand.damage_roll then
      return item.drop(entity, "hand", "offhand"), "hand"
    else
      return item.drop(entity, "hand"), "hand"
    end
  end

  if not hand then
    return not offhand
      or not offhand.tags.two_handed
        and (entity:modify("light", offhand.tags.light, offhand) or not offhand.damage_roll)
      or item.drop(entity, "offhand"), "hand"
  end

  if not entity:modify("light", hand.tags.light, hand) then
    return item.drop(entity, "hand"), "hand"
  end

  if not offhand then
    return true, "offhand"
  end

  if not item.drop(entity, "offhand") then
    return false
  end

  inv.offhand = inv.hand
  inv.hand = nil
  return true, "hand"
end

give_to_a_hand = function(slot, entity, this_item)
  assert(slot == "hand" or slot == "offhand")
  local other = entity.inventory[slot == "hand" and "offhand" or "hand"]

  local needs_two_hands = other and (
    this_item.tags.two_handed
    or other.tags.two_handed
    or (not this_item.tags.light or not other.tags.light)
      and this_item.damage_roll
      and other.damage_roll
  )

  if needs_two_hands then
    return item.drop(entity, "hand", "offhand")
  end

  return item.drop(entity, slot)
end

Ldump.mark(item, {}, ...)
return item
