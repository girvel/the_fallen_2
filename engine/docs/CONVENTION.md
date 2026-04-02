# Code conventions

## Rules

1. Never use function definition sugar (like `function f() ... end`); instead, always use assignment (like `f = function() end`)
2. Never indent assignment operator, like:

```lua
local a   = 1
local bcd = 2
```

## Rationale

(1) and (2) aim to make code greppable.
