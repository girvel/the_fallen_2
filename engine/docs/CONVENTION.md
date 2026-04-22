# Code conventions

## Rules

1. Never use function definition sugar (like `function f() ... end`); instead, always use assignment (like `f = function() end`) -- for search purposes
2. Never indent assignment operator (for search purposes), like in:

```lua
local a   = 1
local bcd = 2
```

3. Function calls always use braces (`()`) except if it's something like `action.plain {...}`, where action.plain is kind of a type
4. Private fields start with _
