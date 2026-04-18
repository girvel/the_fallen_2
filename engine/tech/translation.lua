local translation = {
  resources = {
    bonus_actions = "бонусные действия",
    movement = "движение",
    reactions = "реакции",
    actions = "действия",
    second_wind = "второе дыхание",
    action_surge = "всплеск действий",
    hit_dice = "перевязать раны",
    fighting_spirit = "боевой дух",
    spell_slots_1 = "заклинания ур. 1",
    spell_slots_2 = "заклинания ур. 2",
    spell_slots_3 = "заклинания ур. 3",
    spell_slots_4 = "заклинания ур. 4",
    spell_slots_5 = "заклинания ур. 5",
    spell_slots_6 = "заклинания ур. 6",
    spell_slots_7 = "заклинания ур. 7",
    spell_slots_8 = "заклинания ур. 8",
    spell_slots_9 = "заклинания ур. 9",
  },
  bag = {
    money = "Ценности",
  },

  abilities = {
    str = "сила",
    dex = "ловкость",
    con = "телосложение",
    int = "интеллект",
    wis = "мудрость",
    cha = "харизма",
  },

  skills = {
    athletics = "атлетика",
    acrobatics = "акробатика",
    sleight_of_hand = "ловкость рук",
    stealth = "скрытность",
    arcana = "магия",
    history = "история",
    investigation = "расследование",
    nature = "природа",
    religion = "религия",
    animal_handling = "уход за животными",
    insight = "проницательность",
    medicine = "медицина",
    perception = "внимание",
    deception = "обман",
    intimidation = "запугивание",
    performance = "выступление",
    persuasion = "убеждение",
    survival = "выживание",
  },

  items = {
    tags = {
      two_handed = "двуручное",
      light = "лёгкое",
      finnesse = "фехтовальное",
      heavy = "тяжёлое",
      versatile = "полуторное",
    },
  },

  feats = {
    savage_attacker = "неистовый атакующий",
    great_weapon_master = "мастер двуручного оружия",
  },

  classes = {
    fighter = "воин",
  },

  fighting_styles = {
    two_weapon_fighting = "Бой двумя оружиями",
    defence = "Защита",
  },
}

Ldump.mark(translation, "const", ...)
return translation
