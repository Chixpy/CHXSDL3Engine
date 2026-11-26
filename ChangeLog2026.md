# ChangeLog 2026

## 2026-11-26 16:32

Fonts, TextEdit and docs checkpoint

### Renames and API cleanup
- Renamed `Abstracts/uaCHXSDL3Component.pas` → `ucaCHXSDL3Component.pas`, `Abstracts/uaCHXSDL3Font.pas` → `ucaCHXSDL3Font.pas`; updated all `uses`.
- `caCHXSDL3Font.Color` exposed as public field (removed redundant property); `cCHXSDL3Label.Caption/Font/TextAlign` exposed as public fields.

### Components and fonts
- Added `cCHXSDL3Label` (one-line, clipped, aligned) and `cCHXSDL3TextEdit` (basic: focus via SDL text input, UTF-8 helpers, cursor, editing, horizontal scroll to keep cursor visible). Fixed focus by calling inherited mouse handling in `TextEdit.HandleEvent`.
- Added minimal `cCHXSDL3FontBitmap` (grid BMP atlas) and example usage in `Tests/TestComponents.pas`; added sample `Tests/font8x8.bmp`.

### Docs and roadmap
- Updated `RoadMap.md` (phases 1–5 marked, verification notes), `ToDo.md` (phase 6 TTF plan), `README.md` (project structure), `CheatSheet.md` (font/label/textedit sections).

## 2026-11-24 21:50

# Last changes (draft)

## Screenshots (PrtScr) and config

- `Classes/ucCHXSDL3Config.pas`: add `ScreenshotDir` (default `scrshots`), INI key `ScreenshotDir`, CLI `--screenshot-dir`, sanitize empty to default.
- `ucCHXSDL3Engine.pas`: handle `SDLK_PRINTSCREEN` in `HandleEvent` (set `RequestScreenshot`); take BMP before present via `SDL_RenderReadPixels` + `SDL_SaveBMP`, create dir if needed, name `<ExeBase>-YYYYMMDD-HHMMSS_N.bmp` (local time, suffix from `_1`), log via `SDL_Log`/`SDL_LogWarn`; add `RequestScreenshot`/`TakeScreenshotNow`.

## Tests and docs

- New `Tests/TestScreenshot.pas` (dummy/software) and integrated into `Tests/build.sh`, `Tests/Build.bat`, `Tests/run_tests.sh`, `Tests/RunTests.bat`.
- Updated `README.md` and `Tests/Readme.md` (headless suites list, `ScreenshotDir`, `--screenshot-dir`, screenshot note).
- `RoadMap.md` marked completed for the BMP screenshot plan.

## 2026-11-24 18:16

Update CHXTests and add opt-in JSON test reports

### Tests/CHXTests
- Update the submodule from 7cddc8d to 43512b1: JSON writer, failure
  summaries, documentation and fgl-based lists.

### ucCHXSDL3Engine.pas
- Document AddComponent as the only component initialization point and
  remove the duplicate Setup loop from Run.

### Tests/TestComponentsSetup.pas
- Add a headless suite that checks one Setup/Finish call for components
  added before Run and from the engine Setup, plus colors and LogPres.

### Tests/uCHXTestJSON.pas
- Add a shared helper for `--json`/`--json=` and `CHXTESTS_JSON`. Directories
  get one report per suite. A save error sets exit code 2 when the tests
  passed.

### Tests/TestConfig.pas, Tests/SmokePrimitives.pas,
### Tests/TestComponentsSetup.pas
- Keep the console writer and add the JSON writer only on demand.

### Tests/run_tests.sh, Tests/RunTests.bat
- Build and run the new TestComponentsSetup suite.

### README.md, Tests/Readme.md, ToDo.md
- Document the JSON option and the new suite; mark the double Setup item as
  done and note the pending SDL error investigation.

## 2026-11-17 17:41

Use CHXTests for headless tests and add cross-platform runners

### `.gitmodules`
- Register the CHXTests submodule under `Tests/CHXTests`.

### `Tests/CHXTests`
- Add CHXTests as a submodule pinned to `7cddc8d`.

### `Tests/fpcfg.cfg`
- Add `-FuCHXTests` and `-FiCHXTests` for the headless suites.

### `Tests/TestConfig.pas`
- Convert the program to a `cCHXTestGroup` suite with a console writer.
- Replace local `Check*` helpers with CHXTests assertions.
- Keep the 9 cases and 60 assertions.

### `Tests/SmokePrimitives.pas`
- Convert the program to a `cCHXTestGroup` suite with a shared window.
- Split the existing checks into 18 cases and 84 assertions.
- Keep the software renderer and the headless dummy-driver requirement.

### `Tests/run_tests.sh`
- Add a headless runner that builds and runs both suites.
- Default to `SDL_VIDEODRIVER=dummy` and propagate CHXTests exit codes.

### `Tests/RunTests.bat`
- Add the Windows equivalent based on `Build.bat`.

### `README.md`
- Document the CHXTests dependency, headless runners and project layout.

### `Tests/Readme.md`
- Document the CHXTests submodule, both runners and exit codes.

### `Classes/ucCHXSDL3Renderer.pas`
- Document that SDL3 `Clear` ignores alpha.

## 2026-11-16 18:13

Fix ShellCheck warnings in build and commit scripts

### `Tests/build.sh`
- Exit if `pushd` or `popd` fails.
- Quote `"$@"` so compiler arguments are preserved.

### `Tests/Primitives/build.sh`
- Exit if `pushd` or `popd` fails.
- Quote `"$@"` so compiler arguments are preserved.

### `git_commit.sh`
- Generate the yearly changelog index with `compgen` instead of `ls`.
- Use an explicit no-op redirection to truncate `LastChanges.md`.

## 2026-11-14 00:33

Add configurable engine settings and command line options

### `Classes/ucCHXSDL3Config.pas`
- Add `FPS`, `LogicalPresentation`, `ShowFrameRate` and `VSync` settings.
- Use `TSDL_RendererLogicalPresentation` and SDL3 constants directly.
- Add `ApplyCommandLine` overloads with sequential argument processing.
- Support `--config`, `--width`, `--height`, `--scale`, `--fullscreen`,
  `--render`, `--fps`, `--logical`, `--show-fps` and `--vsync`.
- Accept `--key=value`, `--key value`, boolean `--no-*` and
  `--key=true|false`, and `--` as the end of engine options.
- Add `Sanitize` to clamp ranges and validate the logical presentation mode.
- Change `LoadFromIni` and `SaveToIni` to accept `TCustomIniFile`.
- Add helpers to convert logical presentation modes to and from strings.

### `Classes/ucCHXSDL3Window.pas`
- Add logical presentation and VSync parameters to `Create`.
- Apply `SDL_SetRenderVSync` and use the requested logical presentation mode.

### `ucCHXSDL3Engine.pas`
- Add a values constructor with `AutoInit` first and the new settings.
- Add constructors for an INI filename and an already opened `TCustomIniFile`.
- Apply and sanitize configuration in `Init`, including command line options.
- Use `Config.FPS` in `Run` and keep `ShowFrameRate` synchronized with
  `Config`.

### `Tests/TestConfig.pas`
- Add non-interactive tests for defaults, INI serialization, command line
  parsing, repeated options and configuration precedence.

### `Tests`
- Update engine constructor calls to the new signature.
- Document the configuration tests in `Tests/Readme.md`.

### Documentation
- Document the configuration constructors, INI keys and command line options.
- Update `CheatSheet.md` with the new configuration API.

### `.gitignore`
- Ignore the local `PENDIENTES.md` audit notes.

## 2026-11-13 20:01

Harden drawing primitives and SDL resource handling

### `Classes/CHXSDL3Renderer/Auxiliar.inc`
- Add `CHXSDL3IsFinite` to reject NaN and infinite geometry values.
- Add `GetRenderBounds` to query the current logical or output render
  bounds at call time.
- Normalize array range validation parameters to `CInt`.

### `Classes/ucCHXSDL3Renderer.pas`
- Add `MaxRegPolySides` and `MaxRasterIterations` safety limits.
- Normalize SDL-facing index and count parameters to `CInt`.
- Remove `inline` from polygon border helpers that now set SDL errors.
- Fix the `PointMirrorHVFilled` documentation mapping.
- Document that `SDL_RenderGeometryRaw`, `SDL_RenderPresent`,
  `SDL_RenderDebugTextFormat` and `SDL_RenderCopy` remain outside the
  basic wrapper.

### `Classes/CHXSDL3Renderer/Circle.inc`
- Reject non-finite coordinates and radii.
- Skip circles completely outside the render bounds.
- Limit huge radii before entering rasterization loops.
- Guard misconfigured vertex counts.
- Use `Cardinal` indices for `SDL_RenderGeometryRaw` and pass
  `SizeOf(Cardinal)`.
- Preserve validation failures in border wrappers.

### `Classes/CHXSDL3Renderer/Ellipse.inc`
- Reject non-finite coordinates and radii.
- Skip ellipses completely outside the render bounds.
- Limit huge radii before entering rasterization loops.
- Use `Cardinal` indices for `SDL_RenderGeometryRaw` and pass
  `SizeOf(Cardinal)`.
- Preserve validation failures in border wrappers.

### `Classes/CHXSDL3Renderer/RndRect.inc`
- Add finite-value, radius and off-screen guards to the circular and
  elliptical rounded-rectangle rasterizers.
- Prevent huge radii from entering integer rasterization loops.

### `Classes/CHXSDL3Renderer/Polygon.inc`
- Validate unsafe polygon ranges with `Int64` arithmetic.
- Reject non-finite polygon points.
- Clip scanlines and X spans to the visible viewport.
- Bound scanline iterations with `MaxRasterIterations`.
- Preserve validation failures in border and fill wrappers.
- Handle one and two point polygons in `SPPolygonFilledUnsafe`.
- Remove the incorrect `Odd(PairCount)` check from `SegmentsUnsafe`.

### `Classes/CHXSDL3Renderer/RegPoly.inc`
- Add `NSides` and finite-value guards.
- Limit the number of regular polygon sides.
- Use `Cardinal` indices for `SDL_RenderGeometryRaw`.

### `Classes/CHXSDL3Renderer/Color.inc`
- Keep the color cache coherent only after successful SDL color updates.
- Roll back `PushDrawColor` and `PopDrawColor` on failure.

### Other renderer primitives
(`Classes/CHXSDL3Renderer/Line.inc`, `Point.inc`, `Quad.inc`, `Rect.inc`,
`Triangle.inc`)
- Normalize SDL-facing index and count types to `CInt`.
- Keep native point, line and rect calls inside the basic primitives.

### `Classes/ucCHXSDL3Window.pas`
- Add `ReleaseResources` and free the renderer, window and video subsystem
  if construction fails.
- Roll back logical presentation stack changes on failure.
- Use `CInt` for render sizes.

### `ucCHXSDL3Engine.pas`
- Use `LogPresMode` in all `PushRenderSize` calls.
- Fix SDL error and allocation diagnostics in the destructor.

### `Classes/ucCHXSDL3FPSManager.pas`
- Clamp and cast the `SDL_Delay` argument to `UInt32`.

### `Tests/SmokePrimitives.pas`, `Tests/Readme.md`
- Add a non-interactive smoke test for valid and invalid primitives,
  safety limits and resource stacks.
- Document running the smoke test with the dummy video driver.

### `git_commit.sh`
- Add emoji markers to status messages.

## 2026-11-11 03:37

Add per-year changelog and commit helper script

### `git_commit.sh`
- Translate the script to English.
- Write entries to `ChangeLog<YYYY>.md` and regenerate `CHANGELOG.md`
  as the yearly index.
- Strip HTML comments from the draft before using it as the commit
  message and changelog entry.
- Back up and restore the changelog files if the commit fails.
- Check for a Git work tree with `git rev-parse --is-inside-work-tree`,
  so the script also works from submodules and subdirectories.
- Keep `LastChanges.md` on failure and clear it only after a successful
  commit.

### `.gitignore`
- Ignore the local `LastChanges.md` draft.

### `LastChanges.example.md`
- Add the changelog entry template and instructions.

### `CHANGELOG.md`, `ChangeLog2026.md`
- Add the changelog index and the initial yearly file.

### `README.md`
- Document the development process and the changelog workflow.

