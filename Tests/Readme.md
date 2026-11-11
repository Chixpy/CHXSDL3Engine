# CHXSDL3Engine test programs

Programs to test `SDL3`, `cCHXSDL3Engine` and its components.

## Compiling

_SDL3-for-Pascal_ is included as a submodule at `../SDL3`, so `fpcfg.cfg`
already points to `../SDL3/units`.

From this folder, it should be as easy as:

> `./build.sh <TestProgram>.pas` (Unix-like)

> `Build.bat <TestProgram>.pas` (Windows)

The executable file will be created at `bin` directory.

The SDL3 library must be installed or in the same directory as the program
to run it.
