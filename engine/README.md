# Fallen engine

## Concept

- 2D grid-based graphics
- D&D-like combat & build system
- Immediate mode GUI
- Coroutine-based scripting
- [ldump](https://github.com/girvel/ldump)-driven serialization
- Uses [moonspeak](https://github.com/girvel/moonspeak) to separate cutscene texts and code
- LuaLS-compatible

## Setup

```bash
git init
git submodule add https://github.com/girvel/engine
echo 'require("engine.kernel.main")' | tee main.lua
love .
```

Then follow the error messages. Even though the fallen engine is open-source, I highly doubt that anybody except me/potential collaborators would use it, so there's no documentation and the error messages are not excessively nice.

## Build system dependencies

- Linux environment
- LOVE windows binaries
- wine
- rcedit
- imagemagick
