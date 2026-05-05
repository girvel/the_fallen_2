# Life Cycle

1. Initialization, modules are imported
2. love.load <=> Kernel is created
3. Loading the level: valid State is created and being filled across many frames, State.is_loaded is false
4. State.is_loaded becomes true, ECS starts running
