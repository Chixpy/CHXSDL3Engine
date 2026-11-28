# ChangeLog 2026

## 2026-11-28 12:33

Complete the ellipse FP family and add primitive pixel tests

### Renderer
- `Classes/ucCHXSDL3Renderer.pas`: declare and document `FPEllipse`, `FPEllipseBorder`, `FPEllipseFilled`, `FPEllipseFillOnly`, `FPEllipseInRect`, `FPEllipseInRectBorder`, `FPEllipseInRectFilled` and `FPEllipseInRectFillOnly` (`CFloat`).
- `Classes/CHXSDL3Renderer/Ellipse.inc`: implement FP as finite validation + `Round` + SP delegation; remove the old commented FP block and `EllipseInRectOnlyFillFP`. `FPEllipse` color dispatch uses `PushDrawColor`/`PopDrawColor`.

### Tests
- `Tests/SmokePrimitives.pas`: FP ellipse smoke cases (border, fill, fill-only, colors, rounding, negatives, W/H negatives, NaN, large radii, off-screen).
- `Tests/TestPrimitivesPixels.pas`: new 320x240 pixel suite (17 cases, 972 assertions) for ellipses and the other primitives; integrated in `run_tests.sh`, `RunTests.bat` and `Tests/Readme.md`.

### Docs
- `CheatSheet.md`: drawing families, FP rounding/limits and ellipse signatures.
- `README.md`: headless suite list and renderer variant limitations.
- `RoadMap.md`, `ToDo.md`: phase tracking and ToDo updates.

Verification: 6 headless suites green, debug and -dRELEASE builds, no memory leaks.
## 2026-11-27 00:47

Harden bitmap fonts: renderer wrappers, texture state and pixel tests

### Abstracts/ucaCHXSDL3Font.pas
- Store a `cCHXSDL3Renderer` reference, exposed as the new `Render` property.
- Keep `Renderer` as a read-only `PSDL_Renderer` shortcut to `Render.SDLRenderer`.

### Classes/ucCHXSDL3FontBitmap.pas
- Draw through `cCHXSDL3Renderer.RenderTexture`; texture functions still call SDL directly on purpose.
- Restore blend mode, color mod and alpha mod independently and only when saved.
- Add read-only `AtlasCols`/`AtlasRows` from `SDL_GetTextureSize`; warn on incomplete atlases and skip out-of-range glyphs.
- Draw a visible fallback (`'?'` if present in the atlas, otherwise the first glyph) for non-ASCII bytes and missing codepoints.
- Guard `RenderDynStrClipped` against empty text, zero clip width, missing texture/renderer and non-finite coordinates.
- Replace the Gray RTTI check with a virtual `GetTintEnabled` method.
- Fix `AColorKey`: `TSDL_Color` components are 0..255 bytes, not floats.

### Classes/ucCHXSDL3FontDebug.pas, ucCHXSDL3Engine.pas, Tests/TestComponents.pas
- Use `SetDrawColor`/`DebugText` renderer wrappers and pass `Render` when creating fonts.

### Classes/ucCHXSDL3Renderer.pas
- Remove `Get/SetTextureBlendMode`: they are texture functions, not renderer functions.

### Tests/TestFontBitmap.pas
- New headless pixel suite (8 cases, 53 assertions): Gray/Color rendering, tint, alpha, texture state restoration, color key, fallback glyph, clipping and invalid inputs.
- Generates its BMP atlas at runtime and removes its temporary directory.

### Tests/
- Add `TestFontBitmap` to `run_tests.sh` and `RunTests.bat`; document the suite in `Readme.md`.
- Fix the stale `uaCHXSDL3Component` unit name in `TestComponentsSetup.pas`.
- Use float `SameValue` assertions with sigma for colors and drop redundant integer casts.

### Docs
- `CheatSheet.md`: renderer-based font API, atlas limits, fallback rule and color key handling.
- `README.md`: known limitations for bitmap fonts, alignment and unfinished primitives.

## 2026-11-26 23:00

FontBitmap: refactor to Gray/Color variants and renderer helpers

### Classes/ucCHXSDL3FontBitmap.pas
- Refactor to `caCHXSDL3FontBitmap` base, `cCHXSDL3FontBitmapGray` (alpha mask from luminance, white=opaque/black=transparent, color/alpha mod from `Font.Color`), and `cCHXSDL3FontBitmapColor` (optional color key via `AColorKey`, no default key; respects surface alpha if no key). Keep `cCHXSDL3FontBitmap` as alias to Gray for compatibility.
- Add basic validation/logging for glyph size and columns; document atlas/grid format in comments.
- Render uses `SDL_RenderTexture` and restores texture color/alpha mod and blend mode as needed.

### Classes/ucCHXSDL3Renderer.pas
- Add `RenderTexture`, `SetTextureBlendMode`, and `GetTextureBlendMode` wrappers (no `inline` in implementation).

### Tests/TestComponents.pas
- Add comments clarifying default Gray usage and `cCHXSDL3FontBitmapColor` example with optional color key.

### CheatSheet.md
- Update FontBitmap section (base/Gray/Color/alias and notes).

## 2026-11-26 17:24

Cleanup text input and add Tab focus cycling

### `ucCHXSDL3Engine.pas`
- Removed obsolete commented text input code (STI*/TextInput/IsEditingText, IME/text input event handling, related Run/Init/Destroy comments). Kept `SDL3_textinput.h` style flow replaced by `cCHXSDL3TextEdit`.
- Added Tab/Shift+Tab to cycle focus among components in `HandleEvent` (fallback).

### `ToDo.md`
- Marked engine text input cleanup as done; noted Tab/Shift+Tab focus cycling done, arrows pending.

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

