# Life Cycle

1. **Initialization:** modules are imported
2. **Kernel loading:** love.load <=> Kernel is created
3. **Game loading:** Normally (if the save is not read), State is created and the level immediately starts loading; State is mostly valid, but .rails is missing until all entities are loaded. State.is_loaded is false
4. **Game running:** State.is_loaded becomes true, rails get created, ECS starts running.
