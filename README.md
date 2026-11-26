# CHXSDL3Engine

A small 2D game engine for Free Pascal / Object Pascal built on top of
[SDL3](https://www.libsdl.org/) through the
[SDL3-for-Pascal](https://github.com/PascalGameDevelopment/SDL3-for-Pascal)
bindings.

CHXSDL3Engine provides:

- A ready-to-use application/game loop (`cCHXSDL3Engine`).
- Window, renderer and logical-presentation management (`cCHXSDL3Window`).
- An extended 2D renderer with primitives: points, lines, triangles,
  rectangles, polygons, circles, ellipses, rounded rectangles, etc.
  (`cCHXSDL3Renderer`).
- A component base class with focus and event routing
  (`caCHXSDL3Component`).
- A simple FPS manager (`cCHXSDL3FPSManager`).
- A small INI-based configuration class (`cCHXSDL3Config`).

## Development

After spliting from [CHXPas](https://github.com/Chixpy/CHXPas), this project
is primarily developed with the assistance of an AI coding agent running in
[OpenCode](https://opencode.ai/). The maintainer,
[Chixpy](https://github.com/Chixpy), reviews the changes, makes the design
decisions and contributes code from time to time.

AI-assisted changes can still contain mistakes. If you find a problem,
please open an issue.

## Requirements

- Free Pascal Compiler 3.3.1 or newer.
- SDL3 runtime library (3.x) installed on the system.
- [SDL3-for-Pascal](https://github.com/PascalGameDevelopment/SDL3-for-Pascal)
  units. This repository includes them as a submodule at `SDL3/`.
- [CHXTests](https://github.com/Chixpy/CHXTests) units, included as a
  submodule at `Tests/CHXTests/`. They are needed by the headless suites.

## Getting the source

```sh
git clone --recurse-submodules https://github.com/Chixpy/CHXSDL3Engine.git
cd CHXSDL3Engine
```

If you already cloned the repository without submodules:

```sh
git submodule update --init --recursive
```

## Building the tests

The test programs are in `Tests/` and `Tests/Primitives/`.

Unix-like:

```sh
cd Tests
./build.sh CHXSDL3Engine.pas
```

Windows:

```bat
cd Tests
Build.bat CHXSDL3Engine.pas
```

The executable is written to `Tests/bin/`. Add `-dRELEASE` for an optimized,
stripped build:

```sh
./build.sh -dRELEASE CHXSDL3Engine.pas
```

To run the graphical tests you need a working display (X11, Wayland, etc.).
On Termux, [Termux:X11](https://github.com/termux/termux-x11) can be used.

## Running headless tests

The non-interactive suites use CHXTests: `TestConfig.pas`,
`SmokePrimitives.pas`, `TestComponentsSetup.pas` and `TestScreenshot.pas`.

Unix-like:

```sh
cd Tests
./run_tests.sh
```

Windows:

```bat
cd Tests
RunTests.bat
```

The runners build those programs, then run them with
`SDL_VIDEODRIVER=dummy` unless the caller defines another driver. Exit
codes are `0` success, `1` failed assertion, `2` unexpected error and `3`
skipped or no cases executed. Individual suites can still be built and run
with `build.sh` or `Build.bat`.

### Optional JSON reports

Each suite always writes to the console. Add `--json <file>` (or
`--json=<file>`) to also write a machine-readable CHXTests report:

```sh
./bin/TestConfig --json bin/TestConfig.json
```

`CHXTESTS_JSON` does the same for every suite, which is convenient with the
runners:

```sh
CHXTESTS_JSON=bin/jsonreports ./run_tests.sh
```

When the value is a directory (existing, ending in a path separator or with
no extension), each suite writes `<suite>.json` there. When it is a file
path, it is used as-is and the last suite overwrites previous reports.
Command line arguments take precedence over the environment variable.
Reports include `generator`, `schemaVersion`, `counts`, `cases` and nested
`groups`. If a requested report cannot be saved, the error is printed and
the exit code becomes `2` when the tests passed.

## Minimal example

```pascal
program MyGame;

{$mode ObjFPC}{$H+}

uses
  CTypes, SDL3, ucCHXSDL3Engine;

type
  cMyGame = class(cCHXSDL3Engine)
  protected
    procedure Setup; override;
    procedure Finish; override;
    procedure Compute(var ExitProg : Boolean); override;
    procedure Draw; override;
    procedure HandleEvent(const aEvent : TSDL_Event;
      var Handled : Boolean; var ExitProg : Boolean); override;
  end;

procedure cMyGame.Setup;
begin
  ShowFrameRate := True;
end;

procedure cMyGame.Finish;
begin
end;

procedure cMyGame.Compute(var ExitProg : Boolean);
begin
end;

procedure cMyGame.Draw;
begin
  Render.Clear(0.1, 0.1, 0.15);
  Render.SetDrawColor(1, 0.5, 0);
  Render.CircleBorder(100, 100, 40);
  Render.DebugText(10, 10, 'Hello, World!');
end;

procedure cMyGame.HandleEvent(const aEvent : TSDL_Event;
  var Handled : Boolean; var ExitProg : Boolean);
begin
  inherited;
end;

var
  Game : cMyGame;
begin
  Game := cMyGame.Create('My Game', 'mygame.ini');
  try
    Game.Run;
  finally
    Game.Free;
  end;
end.
```

## Configuration

`cCHXSDL3Engine` owns a `cCHXSDL3Config` instance exposed as `Game.Config`.
The configuration can be created from values, from an INI file, or from an
already opened `TCustomIniFile`:

```pascal
// Values. AutoInit defaults to False, so Config can be adjusted before Init.
Game := cMyGame.Create(False, 'My Game', 640, 480, 2);

// File. The engine is initialized automatically.
Game := cMyGame.Create('My Game', 'mygame.ini');

// Already opened file. The caller keeps ownership of the IniFile.
Game := cMyGame.Create('My Game', MyIniFile);
```

With `AutoInit = False`, change `Game.Config` and call `Game.Init`:

```pascal
Game := cMyGame.Create(False, 'My Game');
try
  Game.Config.Width := 1280;
  Game.Config.Height := 720;
  Game.Config.FPS := 60;
  Game.Config.LogicalPresentation := SDL_LOGICAL_PRESENTATION_LETTERBOX;
  Game.Init;
  Game.Run;
finally
  Game.Free;
end;
```

The INI file uses the `[SDL3Engine]` section with the keys `Width`, `Height`,
`Scale`, `FullScreen`, `Render`, `FPS`, `LogicalPresentation`, `ShowFrameRate`,
`VSync` and `ScreenshotDir`. `LogicalPresentation` accepts `Disabled`, `Stretch`,
`Letterbox`, `Overscan` or `IntegerScale`. Pressing `PrintScreen` saves a BMP
screenshot in `ScreenshotDir` (default `scrshots`, created if missing).

### Command line

`Init` applies the command line every time it is called. Precedence, from
lowest to highest, is:

1. Defaults and constructor values.
2. INI files loaded by the constructor or by `--config`.
3. Command line options.

Because the command line is applied by `Init`, it also wins after manual
changes made with `AutoInit = False`.

Supported options:

| Option | Description |
| --- | --- |
| `--config <file>` | Load an INI file. Can be repeated. |
| `--width <pixels>` | Renderer width. |
| `--height <pixels>` | Renderer height. |
| `--scale <factor>` | Window scale. `0` maximizes the window. |
| `--fullscreen` | Enable full screen. |
| `--render <drivers>` | Comma-separated renderer drivers. |
| `--fps <value>` | Target FPS, clamped to `1..1000`. Default `30`. |
| `--logical <mode>` | `Disabled`, `Stretch`, `Letterbox`, `Overscan`, `IntegerScale` or `0..4`. |
| `--show-fps` | Show frame rate information. |
| `--vsync` | Enable vertical synchronization. |
| `--screenshot-dir <dir>` | Directory for screenshots (default `scrshots`). |

Options with a value accept both `--name=value` and `--name value`. Boolean
options accept `--no-<name>` and an explicit `--name=true|false`. Arguments
are processed in order, so the last value wins. `--` stops parsing; unknown
arguments are ignored by the engine and returned by the `ApplyCommandLine`
array overload.

## Project structure

```
ucCHXSDL3Engine.pas  Main engine class (root).
Abstracts/           Component/font base classes (e.g. ucaCHXSDL3Component, ucaCHXSDL3Font).
Classes/             Window, renderer, config, FPS manager, components (Button, Label, TextEdit), fonts (Debug, Bitmap).
Units/               Type helpers and utility units.
Tests/               Test programs; CHXTests submodule in Tests/CHXTests/.
SDL3/                SDL3-for-Pascal submodule.
```

## Known limitations

- **Fonts map bytes, not UTF-8 codepoints.** Bitmap fonts use a fixed grid:
  one byte maps to one glyph through `FirstChar`/`Columns`, with no variable
  width metadata. Non-ASCII bytes and codepoints outside the atlas draw a
  visible fallback glyph (`'?'` when available, otherwise the first glyph)
  instead of being silently skipped. TTF/UTF-8 rendering is not implemented.
- **Alignment with long text.** `RenderDynStrClipped` clamps centered/right
  start to `X` when the text is wider than `ClipWidth`, so the visible part is
  the beginning of the text.
- **Some renderer variants are unfinished.** The FP ellipse block is disabled
  and several SP/FP primitives are still pending in the source.
- **Components are minimal.** `cCHXSDL3Button` has caption/font/glyph code
  commented out and no hover/pressed/disabled states.

## Changelog

Changes are recorded per year in `ChangeLog<YYYY>.md`; `CHANGELOG.md` is
the index. To prepare a commit:

1. Copy `LastChanges.example.md` to `LastChanges.md` (ignored by Git).
2. Write the changes for the next commit.
3. Run `./git_commit.sh`.

The script stages all changes with `git add .`, updates the yearly changelog,
regenerates the index, commits everything and clears the draft on success.

## License

CHXSDL3Engine is free software distributed under the terms of the GNU
General Public License, version 3 or later. See [LICENSE](LICENSE).
