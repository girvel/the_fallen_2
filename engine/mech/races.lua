local races = {}

races.human = {
  codename = "human",
  name = "Разносторонний человек",

  ability_bonus = {
    codename = "ability_bonus_human",
    modify_ability_score = function(self, entity, score, ability)
      return score + 1
    end,
  }
}

races.variant_human = {
  codename = "variant_human",
  name = "Альтернативный человек",

  ability_bonus = Memoize(function(_, ability1, ability2)
    return {
      codename = "ability_bonus_variant_human",
      modify_ability_score = function(self, entity, score, ability)
        if ability == ability1 or ability == ability2 then
          return score + 1
        end
        return score
      end
    }
  end),
}

races.custom_lineage = {
  codename = "custom_lineage",
  name = "Необычное происхождение",

  ability_bonus = Memoize(function(_, ability1)
    return {
      codename = "ability_bonus_custom_lineage",
      modify_ability_score = function(self, entity, score, ability)
        if ability == ability1 then
          return score + 1
        end
        return score
      end
    }
  end),
}

Ldump.mark(races, {}, ...)
return races
