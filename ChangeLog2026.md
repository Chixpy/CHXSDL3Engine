# ChangeLog 2026

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

