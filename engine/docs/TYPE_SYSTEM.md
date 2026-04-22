# Type System

- Flat & minimal.
- Metatables can be used for practical purposes (s.a. definiting + operator in `D(4) + 1`).
- A single isolated type can be defined using `module.mt = {__index = methods}` convention.
- If the type is not isolated (like entities can contain sprites, be animated, be interactive, ...), `methods` are not used; instead, the instance is created through mixing data from multiple sources (like .mix_in functions).
- Good format for actions & spells: single constructor that sets defaults & does boilerplate

## Historically

1. Initially in fallen entities were created through Table.extend, but it was inflexible & used allocation; non-entity types were created without metatables, with methods directly assigned on initialization.
2. Then, `__index = methods` convention formed to (A) work with LSP, (B) not break assignment after serialization-deserialization (metatables were marked as static by Ldump), (C) make modules look cleaner.
3. In the_fallen_1 (dot) the Table.extend convention was reused, modules produced extend-compatible mixins from their .mixin methods.
4. In the_fallen_2, mixins were optimized: `Table.extend(e, animated.mixin(...))` -> `animated.mixin(e, ...)`; this allowed for more complex mixing (like calling methods on mixing) & did not require any allocations.
5. I've considered a possibility to have `local methods = setmetatable({}, {__index = parent_methods})`; it would create a very natural type hierarchy for actions, where there's clear base & function overloading. The idea was rejected on grounds of being an OOP slop, I want a clean & simple system.
6. For actions, doing stuff like `local move = action.plain { ... }` feels convenient.
