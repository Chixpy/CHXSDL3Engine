{ Ellipse methods.

  This file is part of ucCHXSDL3Renderer.

  (C) 2026 Chixpy https://github.com/Chixpy

  In general in all methods with Alois Zingl's algorithm uses squares and
  multiplications that can overflow easily `Integer` range AND break
  `CFloat` (`Single`) unit precision which must be handled:

  - Integer: Abs(`RX` or `RY`) > 46340 overflows Integer size. Creating an
    exception.
  - CFloat: Abs(`RX` or `RY`) > 4096 will break single unit precision
    of CFloat and can hang the program.
  - In both cases variables `e2` and `err` can overflow by themself
    with smaller radii.

  ToDo:

  - Check visibility `((IntX - IntRX) < Width)` or `((IntY - IntRY) < Height)`
  - If we can do CurrX and dX positives, we can use 32 bits unsigned integer.
    Well, we can use it for other variables, but implies many internal
    type conversions.
}

{
  EllipseVertices
}

procedure cCHXSDL3Renderer.EllipseVertices(var PArr: TSDLFPointDynArray;
  const X, Y, RX, RY: CFloat; QuadPoints : CInt);
const
  // ToDo: Make these as cCHXSDL3Renderer properties
  kMinTEllipse = 0; // Additional vertices for each quadrant of the ellipse
  kMaxTEllipse = 16; //
  kTEllipseRatio = {2 * } Pi / 2;
var
  Angle, dAng, aSin, aCos: CFloat;
  i, k: Integer;
begin
  if not (CHXSDL3IsFinite(X) and CHXSDL3IsFinite(Y)
    and CHXSDL3IsFinite(RX) and CHXSDL3IsFinite(RY)) then
  begin
    SDL_SetError('%s(%s) %s: Non-finite X, Y, RX or RY',
      [{$I %FILE%}, {$I %LINE%}, {$I %CURRENTROUTINE%}]);
    SetLength(PArr, 0);
    Exit;
  end;

  if QuadPoints < kMinTEllipse then
  begin
    if Abs(Min(RX, RY)) > 1e9 then
      QuadPoints := kMaxTEllipse
    else
      QuadPoints := Round(kTEllipseRatio * SqRt(Abs(Min(RX, RY))));
  end;

  if QuadPoints < kMinTEllipse then QuadPoints := kMinTEllipse
  else if QuadPoints > kMaxTEllipse then QuadPoints := kMaxTEllipse;

  SetLength(PArr, (QuadPoints + 1) * 4);

  // Basic points
  k := (QuadPoints + 1);
  PArr[0].Init(X + RX, Y);
  PArr[k].Init(X, Y - RY);
  PArr[k * 2].Init(X - RX, Y);
  PArr[k * 3].Init(X, Y + RY);

  if QuadPoints <= 0 then Exit;

  // Rest of the points.
  Angle := 0;
  dAng := (2 * Pi) / Length(PArr);
  //k := (QuadPoints + 1); // Already set
  for i := 1 to QuadPoints do
  begin
    Angle += dAng;
    SinCos(Angle, aSin, aCos);
    aCos *= RX; aSin *= RY;

    PArr[i].Init(X + aCos, Y - aSin);
    PArr[Length(PArr) - i].Init(X + aCos, Y + aSin);

    PArr[(k * 2) - i].Init(X - aCos, Y - aSin);
    PArr[(k * 2) + i].Init(X - aCos, Y + aSin);
  end;
end;

{
  Ellipse[x]
}

function cCHXSDL3Renderer.Ellipse(const X, Y, RX, RY: CFloat;
  const BorderC, FillC: TSDL_FColor; const QuadPoints : CInt): Boolean;
begin
  Result := PushDrawColor(FillC);

  if BorderC = FillC then
  begin
    Result := EllipseFilled(X, Y, RX, RY, QuadPoints)
      and Result;
    Exit(PopDrawColor and Result);
  end;

  if FillC.A > 0 then
    Result := EllipseFillOnly(X, Y, RX, RY, QuadPoints)
      and Result;

  if BorderC.A > 0 then
    Result := SetDrawColor(BorderC) // Don't Push
      and EllipseBorder(X, Y, RX, RY, QuadPoints)
      and Result;

  Result := PopDrawColor and Result;
end;

function cCHXSDL3Renderer.EllipseBorder(const X, Y, RX, RY: CFloat;
  const QuadPoints : CInt): Boolean;
var
  PArr: TSDLFPointDynArray;
begin
  EllipseVertices(PArr, X, Y, RX, RY, QuadPoints);
  if Length(PArr) = 0 then
    Exit(False); // EllipseVertices already set the error.

  Result := PolygonBorder(PArr);
end;

function cCHXSDL3Renderer.EllipseFilled(const X, Y, RX, RY: CFloat;
  const QuadPoints : CInt): Boolean;
var
  PArr: TSDLFPointDynArray;
  Indices: Array of Cardinal;
  FColor: TSDL_FColor;
  i, j: CInt;
begin
  EllipseVertices(PArr, X + 0.5, Y + 0.5, RX + 0.5, RY + 0.5, QuadPoints);
  if Length(PArr) < 3 then
    Exit(False);

  SetLength(Indices, Length(PArr) * 3);

  // Adding center point for creating triangles
  SetLength(PArr, Length(PArr) + 1);
  PArr[High(PArr)] := SDLFPoint(X, Y);

  for i := 0 to (High(PArr) - 2) do
  begin
    j := i * 3;
    Indices[j] := Cardinal(High(PArr));
    Indices[j + 1] := Cardinal(i);
    Indices[j + 2] := Cardinal(i + 1);
  end;
  j := (High(PArr) - 1) * 3;
  Indices[j] := Cardinal(High(PArr));
  Indices[j + 1] := Cardinal(High(PArr) - 1);
  Indices[j + 2] := Cardinal(Low(PArr));

  Result := GetDrawColor(FColor)
    and SDL_RenderGeometryRaw(SDLRenderer, nil,
      @PArr[0], SizeOf(TSDL_FPoint), // Puntos
      @FColor, 0, // Colores
      nil, 0, // uv
      CInt(Length(PArr)), @Indices[0], CInt(Length(Indices)),
      SizeOf(Cardinal)); // Indices
end;

function cCHXSDL3Renderer.EllipseFillOnly(const X, Y: CFloat; RX, RY: CFloat;
  const QuadPoints : CInt): Boolean;
begin
  RX := Abs(RX); RY := Abs(RY);
  if (RX <= 1) or (RY <= 1) then
    Exit(True);
  Result := EllipseFilled(X, Y, RX - 1, RY - 1, QuadPoints);
end;

{
  SPEllipse[X]
}

function cCHXSDL3Renderer.SPEllipse(const X, Y, RX, RY: CFloat;
  const BorderC, FillC: TSDL_FColor): Boolean;
begin
  Result := PushDrawColor(FillC);

  if BorderC = FillC then
  begin
    Result := SPEllipseFilled(X, Y, RX, RY)
      and Result;
    Exit(PopDrawColor and Result);
  end;

  if FillC.A > 0 then
    Result := SPEllipseFillOnly(X, Y, RX, RY)
      and Result;

  if BorderC.A > 0 then
    Result := SetDrawColor(BorderC) // Don't Push
      and SPEllipseBorder(X, Y, RX, RY)
      and Result;

  Result := PopDrawColor and Result;
end;

function cCHXSDL3Renderer.SPEllipseBorder(const X, Y: CFloat; RX, RY: CFloat)
  : Boolean;
{ Modification of Alois Zingl's implementation (https://zingl.github.io)
  of Bresenham's algorithm:
  - Special cases: `Floor(RX) < 1` or `Floor(RY) < 1` are drawn as a filled
    rectangle covering the ellipse bounding box (the border is the whole
    degenerate shape).
  - Avoid redrawing pixels at cardinal points.
  - Precalculate constant terms.
  - Use Int64 for the Bresenham error terms to avoid overflow with large
    radii (up to `MaxRasterIterations`).
  - Adaptation to Logical Presentation subpixels.
}
var
  CurrX, CurrY, IntRX, IntRY: Integer;
  dX, dY, err, e2, StepX, StepY, RY2Sq: Int64;
  FracRX, FracRY: CFloat;
  MinX, MinY, MaxX, MaxY: CFloat;
begin
  if not (CHXSDL3IsFinite(X) and CHXSDL3IsFinite(Y)
    and CHXSDL3IsFinite(RX) and CHXSDL3IsFinite(RY)) then
  begin
    SDL_SetError('%s(%s) %s: Non-finite X, Y, RX or RY',
      [{$I %FILE%}, {$I %LINE%}, {$I %CURRENTROUTINE%}]);
    Exit(False);
  end;

  RX := Abs(RX); RY := Abs(RY);

  if GetRenderBounds(MinX, MinY, MaxX, MaxY)
    and ((X + RX < MinX) or (X - RX > MaxX)
      or (Y + RY < MinY) or (Y - RY > MaxY)) then
    Exit(True); // Completely outside the visible area.

  if (RX > MaxRasterIterations) or (RY > MaxRasterIterations) then
  begin
    SDL_SetError('%s(%s) %s: Radius(%f, %f) > %d',
      [{$I %FILE%}, {$I %LINE%}, {$I %CURRENTROUTINE%},
      RX, RY, MaxRasterIterations]);
    Exit(False);
  end;

  IntRX := Floor(RX); IntRY := Floor(RY);
  FracRX := RX - IntRX; FracRY := RY - IntRY;

  // Special cases
  if (IntRX < 1) or (IntRY < 1) then
    // Draws both vertical and horizontal degenerate cases
    Exit(RectFilled(X - RX, Y - RY, 2 * RX + 1, 2 * RY + 1));

  try // Safety net for unexpected exceptions
    RY2Sq := Int64(IntRY) * IntRY;

    // Initialization
    CurrX := -IntRX; CurrY := 0;
    dX := (1 + Int64(CurrX) * 2) * RY2Sq;
    dY := Int64(IntRX) * IntRX;
    err := dX + dY;
    StepX := dY * 2;
    StepY := RY2Sq * 2;

    // 1st Iteration: Draw first points only once
    if IsZero(FracRY) then
      Result := PointMirrorH(RX, Y, X)
    else
      Result := RectFilled(X - RX, Y - FracRY, 1, 2 * FracRY + 1)
          and RectFilled(X + RX, Y - FracRY, 1, 2 * FracRY + 1);

    // Main Loop
    while CurrX < 0 do
    begin
      e2 := err * 2;
      if e2 >= dX then
      begin
        Inc(CurrX); Inc(dX, StepY); Inc(err, dX);
      end;
      if e2 <= dY then
      begin
        Inc(CurrY); Inc(dY, StepX); Inc(err, dY);
      end;

      if CurrX >= 0 then Break;

      Result := PointMirrorHV(CurrX - FracRX, CurrY + FracRY, X, Y) and Result;
    end;

    // Finish the vertical center segment. The loop only draws the sides, so
    // the center column still has to be completed from the last drawn row
    // (`CurrY`) to the top/bottom cardinal row. The +1 also covers the case
    // where the final iteration incremented `CurrY` before breaking.
    if CurrY <= IntRY then
      Result := RectFilled(X - FracRX, Y - RY,
          2 * FracRX + 1, IntRY - CurrY + 1)
        and RectFilled(X - FracRX, Y + CurrY + FracRY,
          2 * FracRX + 1, IntRY - CurrY + 1)
        and Result;

  except
    on e: Exception do
    begin
      SDL_SetError('%s(%s) %s: %s',
        [{$I %FILE%}, {$I %LINE%}, {$I %CURRENTROUTINE%},
        PAnsiChar(e.ToString)]);
      Exit(False);
    end;
  end;
end;

function cCHXSDL3Renderer.SPEllipseFilled(const X, Y: CFloat; RX, RY: CFloat)
  : Boolean;
{ Modification of Alois Zingl's implementation (https://zingl.github.io)
  of Bresenham's algorithm:

  - Special cases: `Floor(RX) < 1` or `Floor(RY) < 1` are drawn as a filled
    rectangle covering the ellipse bounding box.
  - Draws a horizontal line for every Y change, including the first and last
    rows (including tall ellipses, `RY >> RX`).
  - Avoid redrawing pixels at cardinal points.
  - Fill the ellipse with horizontal lines.
  - Precalculate constant terms.
  - Use Int64 for the Bresenham error terms to avoid overflow with large
    radii (up to `MaxRasterIterations`).
  - Adaptation to Logical Presentation subpixels.
}
var
  CurrX, CurrY, IntRX, IntRY, DrawnY: Integer;
  dX, dY, err, e2, StepX, StepY, RY2Sq: Int64;
  FracRX, FracRY: CFloat;
  MinX, MinY, MaxX, MaxY: CFloat;
begin
  if not (CHXSDL3IsFinite(X) and CHXSDL3IsFinite(Y)
    and CHXSDL3IsFinite(RX) and CHXSDL3IsFinite(RY)) then
  begin
    SDL_SetError('%s(%s) %s: Non-finite X, Y, RX or RY',
      [{$I %FILE%}, {$I %LINE%}, {$I %CURRENTROUTINE%}]);
    Exit(False);
  end;

  RX := Abs(RX); RY := Abs(RY);

  if GetRenderBounds(MinX, MinY, MaxX, MaxY)
    and ((X + RX < MinX) or (X - RX > MaxX)
      or (Y + RY < MinY) or (Y - RY > MaxY)) then
    Exit(True); // Completely outside the visible area.

  if (RX > MaxRasterIterations) or (RY > MaxRasterIterations) then
  begin
    SDL_SetError('%s(%s) %s: Radius(%f, %f) > %d',
      [{$I %FILE%}, {$I %LINE%}, {$I %CURRENTROUTINE%},
      RX, RY, MaxRasterIterations]);
    Exit(False);
  end;

  IntRX := Floor(RX); IntRY := Floor(RY);
  FracRX := RX - IntRX; FracRY := RY - IntRY;

  // Special cases
  if (IntRX < 1) or (IntRY < 1) then
    // Draws both vertical and horizontal degenerate cases
    Exit(RectFilled(X - RX, Y - RY, 2 * RX + 1, 2 * RY + 1));

  try // Safety net for unexpected exceptions
    RY2Sq := Int64(IntRY) * IntRY;

    // Initialization
    CurrX := -IntRX; CurrY := 0;
    dX := (1 + Int64(CurrX) * 2) * RY2Sq;
    dY := Int64(IntRX) * IntRX;
    err := dX + dY;
    StepX := dY * 2;
    StepY := RY2Sq * 2;
    DrawnY := 0; // The first fill below covers y = 0.

    // 1st Iteration: Draw first points only once
    if IsZero(FracRY) then
      Result := RectFilled(X - RX, Y, 2 * RX + 1, 1)
    else
      Result := RectFilled(X - RX, Y - FracRY, 2 * RX + 1, 2 * FracRY + 1);

    // Main Loop
    while CurrX < 0 do
    begin
      e2 := err * 2;
      if e2 >= dX then
      begin
        Inc(CurrX); Inc(dX, StepY); Inc(err, dX);
      end;
      if e2 <= dY then
      begin
        Inc(CurrY); Inc(dY, StepX); Inc(err, dY);
        Result := PointMirrorHVFilled(CurrX - FracRX, CurrY + FracRY, True,
            False, X, Y)
          and Result;
        DrawnY := CurrY;
      end;
    end;

    // Finish the top and bottom center columns. The main loop draws every
    // Y change, so `DrawnY` is the last filled row.
    if DrawnY < IntRY then
      Result := RectFilled(X - FracRX, Y - RY,
          2 * FracRX + 1, IntRY - DrawnY)
        and RectFilled(X - FracRX, Y + DrawnY + FracRY + 1,
          2 * FracRX + 1, IntRY - DrawnY)
        and Result;

  except
    on e: Exception do
    begin
      SDL_SetError('%s(%s) %s: %s',
        [{$I %FILE%}, {$I %LINE%}, {$I %CURRENTROUTINE%},
        PAnsiChar(e.ToString)]);
      Exit(False);
    end;
  end;
end;

function cCHXSDL3Renderer.SPEllipseFillOnly(const X, Y: CFloat; RX, RY: CFloat)
  : Boolean;
{ Modification of Alois Zingl's implementation (https://zingl.github.io)
  of Bresenham's algorithm:

  - Special cases: `Floor(RX) < 1` or `Floor(RY) < 1` draw nothing (the
    border is the whole degenerate shape).
  - Avoid redrawing pixels at cardinal points.
  - Fill the ellipse with horizontal lines without border. The top and bottom
    center columns belong to the border and are intentionally left to
    `SPEllipseBorder`.
  - Precalculate constant terms.
  - Use Int64 for the Bresenham error terms to avoid overflow with large
    radii (up to `MaxRasterIterations`).
  - Adaptation to Logical Presentation subpixels.
}
var
  CurrX, CurrY, IntRX, IntRY: Integer;
  dX, dY, err, e2, StepX, StepY, RY2Sq: Int64;
  FracRX, FracRY: CFloat;
  MinX, MinY, MaxX, MaxY: CFloat;
begin
  if not (CHXSDL3IsFinite(X) and CHXSDL3IsFinite(Y)
    and CHXSDL3IsFinite(RX) and CHXSDL3IsFinite(RY)) then
  begin
    SDL_SetError('%s(%s) %s: Non-finite X, Y, RX or RY',
      [{$I %FILE%}, {$I %LINE%}, {$I %CURRENTROUTINE%}]);
    Exit(False);
  end;

  RX := Abs(RX); RY := Abs(RY);

  if GetRenderBounds(MinX, MinY, MaxX, MaxY)
    and ((X + RX < MinX) or (X - RX > MaxX)
      or (Y + RY < MinY) or (Y - RY > MaxY)) then
    Exit(True); // Completely outside the visible area.

  if (RX > MaxRasterIterations) or (RY > MaxRasterIterations) then
  begin
    SDL_SetError('%s(%s) %s: Radius(%f, %f) > %d',
      [{$I %FILE%}, {$I %LINE%}, {$I %CURRENTROUTINE%},
      RX, RY, MaxRasterIterations]);
    Exit(False);
  end;

  IntRX := Floor(RX); IntRY := Floor(RY);
  FracRX := RX - IntRX; FracRY := RY - IntRY;

  // Special cases
  if (IntRX < 1) or (IntRY < 1) then
    Exit(True); // Nothing to fill

  try // Safety net for unexpected exceptions
    RY2Sq := Int64(IntRY) * IntRY;

    // Initialization
    CurrX := -IntRX; CurrY := 0;
    dX := (1 + Int64(CurrX) * 2) * RY2Sq;
    dY := Int64(IntRX) * IntRX;
    err := dX + dY;
    StepX := dY * 2;
    StepY := RY2Sq * 2;

    // 1st Iteration: Draw first points only once
    //if IsZero(FracRY) then
    //  Result := RectFilled(X - RX + 1, Y, 2 * RX - 1, 1)
    //else
    Result := RectFilled(X - RX + 1, Y - FracRY, 2 * RX - 1, 2 * FracRY + 1);

    // Skip 1st iteration
    e2 := err * 2;
    if e2 >= dX then
    begin
      Inc(CurrX); Inc(dX, StepY); Inc(err, dX);
    end;
    if e2 <= dY then
    begin
      Inc(CurrY); Inc(dY, StepX); Inc(err, dY);
    end;

    // Main Loop
    while CurrX < 0 do
    begin
      e2 := err * 2;
      if e2 <= dY then
      begin
        Result := PointMirrorHVFilled(CurrX - FracRX + 1, CurrY + FracRY,
            True, False, X, Y)
          and Result;
        Inc(CurrY); Inc(dY, StepX); Inc(err, dY);
      end;
      if e2 >= dX then
      begin
        Inc(CurrX); Inc(dX, StepY); Inc(err, dX);
      end;
    end;

  except
    on e: Exception do
    begin
      SDL_SetError('%s(%s) %s: %s',
        [{$I %FILE%}, {$I %LINE%}, {$I %CURRENTROUTINE%},
        PAnsiChar(e.ToString)]);
      Exit(False);
    end;
  end;
end;

{
  FPEllipse[x]
}

function cCHXSDL3Renderer.FPEllipse(const X, Y, RX, RY: CFloat;
  const BorderC, FillC: TSDL_FColor): Boolean;
begin
  if not (CHXSDL3IsFinite(X) and CHXSDL3IsFinite(Y)
    and CHXSDL3IsFinite(RX) and CHXSDL3IsFinite(RY)) then
  begin
    SDL_SetError('%s(%s) %s: Non-finite X, Y, RX or RY',
      [{$I %FILE%}, {$I %LINE%}, {$I %CURRENTROUTINE%}]);
    Exit(False);
  end;

  Result := PushDrawColor(FillC);

  if BorderC = FillC then
  begin
    Result := SPEllipseFilled(Round(X), Round(Y), Round(RX), Round(RY))
      and Result;
    Exit(PopDrawColor and Result);
  end;

  if FillC.A > 0 then
    Result := SPEllipseFillOnly(Round(X), Round(Y), Round(RX), Round(RY))
      and Result;

  if BorderC.A > 0 then
    Result := SetDrawColor(BorderC) // Don't Push
      and SPEllipseBorder(Round(X), Round(Y), Round(RX), Round(RY))
      and Result;

  Result := PopDrawColor and Result;
end;

function cCHXSDL3Renderer.FPEllipseBorder(const X, Y, RX, RY: CFloat)
  : Boolean;
begin
  if not (CHXSDL3IsFinite(X) and CHXSDL3IsFinite(Y)
    and CHXSDL3IsFinite(RX) and CHXSDL3IsFinite(RY)) then
  begin
    SDL_SetError('%s(%s) %s: Non-finite X, Y, RX or RY',
      [{$I %FILE%}, {$I %LINE%}, {$I %CURRENTROUTINE%}]);
    Exit(False);
  end;

  Result := SPEllipseBorder(Round(X), Round(Y), Round(RX), Round(RY));
end;

function cCHXSDL3Renderer.FPEllipseFilled(const X, Y, RX, RY: CFloat)
  : Boolean;
begin
  if not (CHXSDL3IsFinite(X) and CHXSDL3IsFinite(Y)
    and CHXSDL3IsFinite(RX) and CHXSDL3IsFinite(RY)) then
  begin
    SDL_SetError('%s(%s) %s: Non-finite X, Y, RX or RY',
      [{$I %FILE%}, {$I %LINE%}, {$I %CURRENTROUTINE%}]);
    Exit(False);
  end;

  Result := SPEllipseFilled(Round(X), Round(Y), Round(RX), Round(RY));
end;

function cCHXSDL3Renderer.FPEllipseFillOnly(const X, Y, RX, RY: CFloat)
  : Boolean;
begin
  if not (CHXSDL3IsFinite(X) and CHXSDL3IsFinite(Y)
    and CHXSDL3IsFinite(RX) and CHXSDL3IsFinite(RY)) then
  begin
    SDL_SetError('%s(%s) %s: Non-finite X, Y, RX or RY',
      [{$I %FILE%}, {$I %LINE%}, {$I %CURRENTROUTINE%}]);
    Exit(False);
  end;

  Result := SPEllipseFillOnly(Round(X), Round(Y), Round(RX), Round(RY));
end;

{
  EllipseInRect[x]
}

function cCHXSDL3Renderer.EllipseInRect(const aRect: TSDL_FRect;
  const BorderC, FillC: TSDL_FColor; const QuadPoints : CInt): Boolean;
begin
  Result := EllipseInRect(aRect.X, aRect.Y, aRect.W, aRect.H, BorderC,
    FillC, QuadPoints);
end;

function cCHXSDL3Renderer.EllipseInRect(const X, Y, W, H: CFloat;
 const BorderC, FillC: TSDL_FColor; const QuadPoints : CInt): Boolean;
begin
  Result := PushDrawColor(FillC);

  if BorderC = FillC then
  begin
    Result := EllipseInRectFilled(X, Y, W, H, QuadPoints)
      and Result;
    Exit(PopDrawColor and Result);
  end;

  if FillC.A > 0 then
    Result := EllipseInRectFillOnly(X, Y, W, H, QuadPoints)
      and Result;

  if BorderC.A > 0 then
    Result := SetDrawColor(BorderC) // Don't Push
      and EllipseInRectBorder(X, Y, W, H, QuadPoints)
      and Result;

  Result := PopDrawColor and Result;
end;

function cCHXSDL3Renderer.EllipseInRectBorder(const aRect: TSDL_FRect;
  const QuadPoints : CInt) : Boolean;
begin
  Result := EllipseInRectBorder(aRect.X, aRect.Y, aRect.W, aRect.H,
    QuadPoints);
end;

function cCHXSDL3Renderer.EllipseInRectBorder(X, Y, W, H: CFloat;
  const QuadPoints : CInt) : Boolean;
{ With integers there are algorithms to rasterize this ellipses.

  With floats... we can call EllipseBorder with tweaked parameters.
}
begin
  // Normalizing rectangle coordinates
  if W < 0 then
    begin W := -W + 2; X -= W - 1; end;
  if H < 0 then
    begin H := -H + 2; Y -= H - 1; end;
  W := (W - 1) * 0.5; H := (H - 1) * 0.5;
  Result := EllipseBorder(X + W, Y + H, W, H, QuadPoints);
end;

function cCHXSDL3Renderer.EllipseInRectFilled(const aRect: TSDL_FRect;
  const QuadPoints : CInt) : Boolean;
begin
  Result := EllipseInRectFilled(aRect.X, aRect.Y, aRect.W, aRect.H,
    QuadPoints);
end;

function cCHXSDL3Renderer.EllipseInRectFilled(X, Y, W, H: CFloat;
  const QuadPoints : CInt): Boolean;
{ With integers there are algorithms to rasterize this ellipses.

  With floats... we can call EllipseFilled with tweaked parameters.
}
begin
  // Normalizing rectangle coordinates
  if W < 0 then
    begin W := -W + 2; X -= W - 1; end;
  if H < 0 then
    begin H := -H + 2; Y -= H - 1; end;
  W := (W - 1) * 0.5; H := (H - 1) * 0.5;
  Result := EllipseFilled(X + W, Y + H, W, H, QuadPoints);
end;

function cCHXSDL3Renderer.EllipseInRectFillOnly(const aRect: TSDL_FRect;
  const QuadPoints : CInt) : Boolean;
begin
  Result := EllipseInRectFillOnly(aRect.X, aRect.Y, aRect.W, aRect.H,
    QuadPoints);
end;

function cCHXSDL3Renderer.EllipseInRectFillOnly(X, Y, W, H: CFloat;
  const QuadPoints : CInt): Boolean;
{ With integers there are algorithms to rasterize this ellipses.

  With floats... we can call EllipseFillOnly with tweaked parameters.
}
begin
  // Normalizing rectangle coordinates
  if W < 0 then
    begin W := -W + 2; X -= W - 1; end;
  if H < 0 then
    begin H := -H + 2; Y -= H - 1; end;
  W := (W - 1) * 0.5; H := (H - 1) * 0.5;
  Result := EllipseFillOnly(X + W, Y + H, W, H, QuadPoints);
end;

{
  SPEllipseInRect[x]
}

function cCHXSDL3Renderer.SPEllipseInRect(const aRect: TSDL_FRect;
  const BorderC, FillC: TSDL_FColor): Boolean;
begin
  Result := SPEllipseInRect(aRect.X, aRect.Y, aRect.W, aRect.H, BorderC,
    FillC);
end;

function cCHXSDL3Renderer.SPEllipseInRect(const X, Y, W, H: CFloat;
 const BorderC, FillC: TSDL_FColor): Boolean;
begin
  Result := PushDrawColor(FillC);

  if BorderC = FillC then
  begin
    Result := SPEllipseInRectFilled(X, Y, W, H)
      and Result;
    Exit(PopDrawColor and Result);
  end;

  if FillC.A > 0 then
    Result := SPEllipseInRectFillOnly(X, Y, W, H)
      and Result;

  if BorderC.A > 0 then
    Result := SetDrawColor(BorderC) // Don't Push
      and SPEllipseInRectBorder(X, Y, W, H)
      and Result;

  Result := PopDrawColor and Result;
end;

function cCHXSDL3Renderer.SPEllipseInRectBorder(const aRect: TSDL_FRect)
  : Boolean;
begin
  Result := SPEllipseInRectBorder(aRect.X, aRect.Y, aRect.W, aRect.H);
end;

function cCHXSDL3Renderer.SPEllipseInRectBorder(X, Y, W, H: CFloat)
  : Boolean;
{ With integers there are algorithms to rasterize this ellipses.

  With floats... we can call EllipseBorder with tweaked parameters.
}
begin
  // Normalizing rectangle coordinates
  if W < 0 then
    begin W := -W + 2; X -= W - 1; end;
  if H < 0 then
    begin H := -H + 2; Y -= H - 1; end;
  W := (W - 1) * 0.5; H := (H - 1) * 0.5;
  Result := SPEllipseBorder(X + W, Y + H, W, H);
end;

function cCHXSDL3Renderer.SPEllipseInRectFilled(const aRect: TSDL_FRect)
  : Boolean;
begin
  Result := SPEllipseInRectFilled(aRect.X, aRect.Y, aRect.W, aRect.H);
end;

function cCHXSDL3Renderer.SPEllipseInRectFilled(X, Y, W, H: CFloat): Boolean;
{ With integers there are algorithms to rasterize this ellipses.

  With floats... we can call EllipseFilled with tweaked parameters.
}
begin
  // Normalizing rectangle coordinates
  if W < 0 then
    begin W := -W + 2; X -= W - 1; end;
  if H < 0 then
    begin H := -H + 2; Y -= H - 1; end;
  W := (W - 1) * 0.5; H := (H - 1) * 0.5;
  Result := SPEllipseFilled(X + W, Y + H, W, H);
end;

function cCHXSDL3Renderer.SPEllipseInRectFillOnly(const aRect: TSDL_FRect)
 : Boolean;
begin
  Result := SPEllipseInRectFillOnly(aRect.X, aRect.Y, aRect.W, aRect.H);
end;

function cCHXSDL3Renderer.SPEllipseInRectFillOnly(X, Y, W, H: CFloat): Boolean;
{ With integers there are algorithms to rasterize this ellipses.

  With floats... we can call EllipseFillOnly with tweaked parameters.
}
begin
  // Normalizing rectangle coordinates
  if W < 0 then
    begin W := -W + 2; X -= W - 1; end;
  if H < 0 then
    begin H := -H + 2; Y -= H - 1; end;
  W := (W - 1) * 0.5; H := (H - 1) * 0.5;
  Result := SPEllipseFillOnly(X + W, Y + H, W, H);
end;

{
  FPEllipseInRect[x]
}

function cCHXSDL3Renderer.FPEllipseInRect(const aRect: TSDL_FRect;
  const BorderC, FillC: TSDL_FColor): Boolean;
begin
  Result := FPEllipseInRect(aRect.x, aRect.y, aRect.w, aRect.h, BorderC, FillC);
end;

function cCHXSDL3Renderer.FPEllipseInRect(const X, Y, W, H: CFloat;
  const BorderC, FillC: TSDL_FColor): Boolean;
begin
  if not (CHXSDL3IsFinite(X) and CHXSDL3IsFinite(Y)
    and CHXSDL3IsFinite(W) and CHXSDL3IsFinite(H)) then
  begin
    SDL_SetError('%s(%s) %s: Non-finite X, Y, W or H',
      [{$I %FILE%}, {$I %LINE%}, {$I %CURRENTROUTINE%}]);
    Exit(False);
  end;

  Result := SPEllipseInRect(Round(X), Round(Y), Round(W), Round(H),
    BorderC, FillC);
end;

function cCHXSDL3Renderer.FPEllipseInRectBorder(const aRect: TSDL_FRect)
  : Boolean;
begin
  Result := FPEllipseInRectBorder(aRect.x, aRect.y, aRect.w, aRect.h);
end;

function cCHXSDL3Renderer.FPEllipseInRectBorder(X, Y, W, H: CFloat): Boolean;
begin
  if not (CHXSDL3IsFinite(X) and CHXSDL3IsFinite(Y)
    and CHXSDL3IsFinite(W) and CHXSDL3IsFinite(H)) then
  begin
    SDL_SetError('%s(%s) %s: Non-finite X, Y, W or H',
      [{$I %FILE%}, {$I %LINE%}, {$I %CURRENTROUTINE%}]);
    Exit(False);
  end;

  Result := SPEllipseInRectBorder(Round(X), Round(Y), Round(W), Round(H));
end;

function cCHXSDL3Renderer.FPEllipseInRectFilled(const aRect: TSDL_FRect)
  : Boolean;
begin
  Result := FPEllipseInRectFilled(aRect.x, aRect.y, aRect.w, aRect.h);
end;

function cCHXSDL3Renderer.FPEllipseInRectFilled(X, Y, W, H: CFloat): Boolean;
begin
  if not (CHXSDL3IsFinite(X) and CHXSDL3IsFinite(Y)
    and CHXSDL3IsFinite(W) and CHXSDL3IsFinite(H)) then
  begin
    SDL_SetError('%s(%s) %s: Non-finite X, Y, W or H',
      [{$I %FILE%}, {$I %LINE%}, {$I %CURRENTROUTINE%}]);
    Exit(False);
  end;

  Result := SPEllipseInRectFilled(Round(X), Round(Y), Round(W), Round(H));
end;

function cCHXSDL3Renderer.FPEllipseInRectFillOnly(const aRect: TSDL_FRect)
  : Boolean;
begin
  Result := FPEllipseInRectFillOnly(aRect.x, aRect.y, aRect.w, aRect.h);
end;

function cCHXSDL3Renderer.FPEllipseInRectFillOnly(X, Y, W, H: CFloat): Boolean;
begin
  if not (CHXSDL3IsFinite(X) and CHXSDL3IsFinite(Y)
    and CHXSDL3IsFinite(W) and CHXSDL3IsFinite(H)) then
  begin
    SDL_SetError('%s(%s) %s: Non-finite X, Y, W or H',
      [{$I %FILE%}, {$I %LINE%}, {$I %CURRENTROUTINE%}]);
    Exit(False);
  end;

  Result := SPEllipseInRectFillOnly(Round(X), Round(Y), Round(W), Round(H));
end;

{< This source is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License as published by the Free
  Software Foundation; either version 3 of the License, or (at your option)
  any later version.

  This code is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.

  A copy of the GNU General Public License is available on the World Wide Web
  at <http://www.gnu.org/copyleft/gpl.html>. You can also obtain it by writing
  to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
  MA 02111-1307, USA.
}
