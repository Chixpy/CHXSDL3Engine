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

## Requirements

- Free Pascal Compiler 3.3.1 or newer.
- SDL3 runtime library (3.x) installed on the system.
- [SDL3-for-Pascal](https://github.com/PascalGameDevelopment/SDL3-for-Pascal)
  units. This repository includes them as a submodule at `SDL3/`.

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
  Game := cMyGame.Create('My Game', 'mygame.ini', True);
  try
    Game.Run;
  finally
    Game.Free;
  end;
end.
```

## Project structure

```
Abstracts/   Component base classes.
Classes/     Engine, window, renderer, config and FPS manager.
Units/       Type helpers and utility units.
Tests/       Test programs.
SDL3/        SDL3-for-Pascal submodule.
```

## License

CHXSDL3Engine is free software distributed under the terms of the GNU
General Public License, version 3 or later. See [LICENSE](LICENSE).
