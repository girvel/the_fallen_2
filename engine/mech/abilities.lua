local abilities = {}

--- @alias ability "str"|"dex"|"con"|"int"|"wis"|"cha"
--- @alias abilities table<ability, integer>

abilities.new = function(str, dex, con, int, wis, cha)
  return {
    str = str,
    dex = dex,
    con = con,
    int = int,
    wis = wis,
    cha = cha,
  }
end

abilities.list = {"str", "dex", "con", "int", "wis", "cha"}
abilities.set = Table.set(abilities.list) --[[@as table<ability, true>]]

--- @enum (key) skill
abilities.skill_bases = {
  athletics = "str",
  acrobatics = "dex",
  sleight_of_hand = "dex",
  stealth = "dex",
  history = "int",
  investigation = "int",
  religion = "int",
  insight = "wis",
  medicine = "wis",
  perception = "wis",
  survival = "wis",
  performance = "cha",
  -- arcana = "int",
  -- nature = "int",
  -- animal_handling = "wis",
  -- deception = "cha",
  -- intimidation = "cha",
  -- persuasion = "cha",
}

--- @param ability_score integer
--- @return integer
abilities.get_modifier = function(ability_score)
  return math.floor((ability_score - 10) / 2)
end

Ldump.mark(abilities, {}, ...)
return abilities
