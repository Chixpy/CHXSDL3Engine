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

`TestConfig.pas`, `SmokePrimitives.pas`, `TestComponentsSetup.pas` and
`TestScreenshot.pas` are non-interactive CHXTests suites. Compile and run
all of them with:

> `./run_tests.sh` (Unix-like)

> `RunTests.bat` (Windows)

The runners set `SDL_VIDEODRIVER=dummy` unless the caller defines it, so
they also work on headless systems. The remaining programs in this folder
are interactive visual demos or environment diagnostics and need a display.

CHXTests exit codes: `0` success, `1` failed assertion, `2` unexpected error,
`3` skipped or no cases executed. A requested JSON report that cannot be
saved also uses `2` when the tests passed.

### JSON reports

Every suite writes to the console. To also get a JSON report:

> `./bin/TestConfig --json bin/TestConfig.json`

`--json=<file>` works too. Set `CHXTESTS_JSON` to do the same for every
suite from a runner; when its value is a directory, each suite writes
`<suite>.json` there (directories are created as needed). A file path is
used as-is, so the last suite overwrites earlier reports. Command line
arguments take precedence over the variable.

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

## Component setup tests

`TestComponentsSetup.pas` checks that `cCHXSDL3Engine.AddComponent` is the
only initialization point for components. Cases add components before `Run`
and from the engine's `Setup`, then assert one `Setup`/`Finish` call, the
default colors and the logical presentation. It uses SDL dummy video with
the software renderer.

## Screenshot tests

`TestScreenshot.pas` checks that screenshot capture creates BMP files in the
configured directory (using a temporary directory), including incremental
suffixes. It uses SDL dummy video with the software renderer.
