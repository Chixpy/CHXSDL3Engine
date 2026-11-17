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

CHXTests is included as a submodule at `CHXTests/`. If it is missing, run
`git submodule update --init --recursive` from the repository root.

## Headless suites

`TestConfig.pas` and `SmokePrimitives.pas` are non-interactive CHXTests
suites. Compile and run both with:

> `./run_tests.sh` (Unix-like)

> `RunTests.bat` (Windows)

Both runners set `SDL_VIDEODRIVER=dummy` unless the caller defines it, so
they also work on headless systems. The remaining programs in this folder
are interactive visual demos or environment diagnostics and need a display.

CHXTests exit codes: `0` success, `1` failed assertion, `2` unexpected error,
`3` skipped or no cases executed.

## Non-interactive smoke test

`SmokePrimitives.pas` checks error handling and safety limits of
`cCHXSDL3Renderer` without opening an interactive loop. On headless systems
it can use the SDL dummy video driver with the software renderer:

> `SDL_VIDEODRIVER=dummy ./bin/SmokePrimitives`

It returns exit code `0` when all checks pass.

## Configuration tests

`TestConfig.pas` checks defaults, INI serialization, command line parsing and
the precedence between configuration files and command line options. It does
not open a window and can run on headless systems:

> `./bin/TestConfig`

It returns exit code `0` when all checks pass.
