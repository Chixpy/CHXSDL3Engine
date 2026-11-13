program SmokePrimitives;
{<
  Non-interactive smoke test for cCHXSDL3Renderer error handling.

  It needs an SDL video driver. On headless environments it can be run with:

    SDL_VIDEODRIVER=dummy ./bin/SmokePrimitives

  The program returns exit code 0 when all checks pass.

  (C) 2026 Chixpy https://github.com/Chixpy
}
{$mode ObjFPC}{$H+}{$INLINE ON}{$WARN 6058 OFF}
uses
  SysUtils, CTypes, Math, SDL3,
  ucCHXSDL3Window, ucCHXSDL3Renderer, uCHXSDL3TypeHelpers;

var
  Failures: Integer = 0;

procedure Check(const aName: String; const aGot, aExpected: Boolean);
begin
  if aGot <> aExpected then
  begin
    Inc(Failures);
    WriteLn('FAIL: ', aName, ' (got ', aGot, ', expected ', aExpected, ')');
  end;
end;

procedure CheckTrue(const aName: String; const aValue: Boolean);
begin
  Check(aName, aValue, True);
end;

procedure CheckFalse(const aName: String; const aValue: Boolean);
begin
  Check(aName, aValue, False);
end;

var
  Win: cCHXSDL3Window;
  R: cCHXSDL3Renderer;
  PArr: TSDLFPointDynArray;
  SegArr: TSDLFSegmentDynArray;
  i: Integer;
begin
  SDL_SetAppMetadata('SmokePrimitives', '1.0',
    'com.chixpy.SmokePrimitives');

  Win := cCHXSDL3Window.Create('SmokePrimitives', 320, 240, 1, False,
    'software');
  try
    R := Win.Renderer;

    // Basic valid primitives.
    CheckTrue('Point', R.Point(10, 10));
    CheckTrue('Line', R.Line(0, 0, 20, 20));
    CheckTrue('RectBorder', R.RectBorder(0, 0, 20, 20));
    CheckTrue('RectFilled', R.RectFilled(0, 0, 20, 20));

    // Valid shapes: exercise the rasterization loops and index arrays.
    CheckTrue('CircleBorder', R.CircleBorder(40, 40, 12));
    CheckTrue('CircleFilled', R.CircleFilled(40, 40, 12));
    CheckTrue('CircleFillOnly', R.CircleFillOnly(40, 40, 12));
    CheckTrue('SPCircleBorder', R.SPCircleBorder(80, 40, 12));
    CheckTrue('SPCircleFilled', R.SPCircleFilled(80, 40, 12));
    CheckTrue('SPCircleFillOnly', R.SPCircleFillOnly(80, 40, 12));

    CheckTrue('EllipseBorder', R.EllipseBorder(40, 100, 20, 10));
    CheckTrue('EllipseFilled', R.EllipseFilled(40, 100, 20, 10));
    CheckTrue('EllipseFillOnly', R.EllipseFillOnly(40, 100, 20, 10));
    CheckTrue('SPEllipseBorder', R.SPEllipseBorder(100, 100, 20, 10));
    CheckTrue('SPEllipseFilled', R.SPEllipseFilled(100, 100, 20, 10));
    CheckTrue('SPEllipseFillOnly', R.SPEllipseFillOnly(100, 100, 20, 10));

    CheckTrue('EllipseInRectBorder',
      R.EllipseInRectBorder(150, 20, 40, 20));
    CheckTrue('EllipseInRectFilled',
      R.EllipseInRectFilled(150, 20, 40, 20));
    CheckTrue('EllipseInRectFillOnly',
      R.EllipseInRectFillOnly(150, 20, 40, 20));

    CheckTrue('RndRectCBorder', R.SPRndRectCBorder(20, 160, 40, 30, 8));
    CheckTrue('RndRectCFilled', R.SPRndRectCFilled(20, 160, 40, 30, 8));
    CheckTrue('RndRectCFillOnly',
      R.SPRndRectCFillOnly(20, 160, 40, 30, 8));
    CheckTrue('RndRectEBorder',
      R.SPRndRectEBorder(80, 160, 40, 30, 12, 8));
    CheckTrue('RndRectEFilled',
      R.SPRndRectEFilled(80, 160, 40, 30, 12, 8));
    CheckTrue('RndRectEFillOnly',
      R.SPRndRectEFillOnly(80, 160, 40, 30, 12, 8));

    CheckTrue('RegPolyCCBorder', R.RegPolyCCBorder(200, 60, 20, 5));
    CheckTrue('RegPolyCCFilled', R.RegPolyCCFilled(200, 60, 20, 5));
    CheckTrue('RegPolyCCFillOnly', R.RegPolyCCFillOnly(200, 60, 20, 5));
    CheckTrue('RegPolySSBorder', R.RegPolySSBorder(250, 60, 20, 6));
    CheckTrue('RegPolySSFilled', R.RegPolySSFilled(250, 60, 20, 6));
    CheckTrue('RegPolySSFillOnly', R.RegPolySSFillOnly(250, 60, 20, 6));

    CheckTrue('QuadBorder',
      R.QuadBorder(180, 100, 220, 100, 220, 140, 180, 140));
    CheckTrue('QuadFilled',
      R.QuadFilled(180, 100, 220, 100, 220, 140, 180, 140));
    CheckTrue('QuadFillOnly',
      R.QuadFillOnly(180, 100, 220, 100, 220, 140, 180, 140));
    CheckTrue('SPQuadBorder',
      R.SPQuadBorder(180, 100, 220, 100, 220, 140, 180, 140));
    CheckTrue('SPQuadFilled',
      R.SPQuadFilled(180, 100, 220, 100, 220, 140, 180, 140));
    CheckTrue('SPQuadFillOnly',
      R.SPQuadFillOnly(180, 100, 220, 100, 220, 140, 180, 140));

    CheckTrue('TriangleBorder',
      R.TriangleBorder(240, 160, 280, 160, 260, 200));
    CheckTrue('TriangleFilled',
      R.TriangleFilled(240, 160, 280, 160, 260, 200));
    CheckTrue('TriangleFillOnly',
      R.TriangleFillOnly(240, 160, 280, 160, 260, 200));
    CheckTrue('SPTriangleBorder',
      R.SPTriangleBorder(240, 160, 280, 160, 260, 200));
    CheckTrue('SPTriangleFilled',
      R.SPTriangleFilled(240, 160, 280, 160, 260, 200));
    CheckTrue('SPTriangleFillOnly',
      R.SPTriangleFillOnly(240, 160, 280, 160, 260, 200));

    CheckTrue('FrameBorder', R.FrameBorder(20, 210, 40, 20, 2));
    CheckTrue('FrameFilled', R.FrameFilled(20, 210, 40, 20, 2));
    CheckTrue('FrameFillOnly', R.FrameFillOnly(20, 210, 40, 20, 2));

    // Valid polygon variants.
    SetLength(PArr, 4);
    PArr[0].Init(10, 10);
    PArr[1].Init(50, 10);
    PArr[2].Init(50, 50);
    PArr[3].Init(10, 50);
    CheckTrue('PolygonBorder', R.PolygonBorder(PArr));
    CheckTrue('PolygonFilled', R.PolygonFilled(PArr));
    CheckTrue('PolygonFillOnly', R.PolygonFillOnly(PArr));
    CheckTrue('SPPolygonBorder', R.SPPolygonBorder(PArr));
    CheckTrue('SPPolygonFilled', R.SPPolygonFilled(PArr));
    CheckTrue('SPPolygonFillOnly', R.SPPolygonFillOnly(PArr));

    // Non-finite geometry must fail instead of hanging.
    CheckFalse('CircleBorder(NaN)', R.CircleBorder(10, 10, NaN));
    CheckFalse('CircleFilled(NaN)', R.CircleFilled(10, 10, NaN));
    CheckFalse('SPCircleBorder(NaN)', R.SPCircleBorder(10, 10, NaN));
    CheckFalse('EllipseBorder(NaN)',
      R.EllipseBorder(10, 10, NaN, 10));
    CheckFalse('EllipseFilled(NaN)',
      R.EllipseFilled(10, 10, NaN, 10));
    CheckFalse('RndRectCBorder(NaN)',
      R.SPRndRectCBorder(0, 0, 20, 20, NaN));
    CheckFalse('RndRectEBorder(NaN)',
      R.SPRndRectEBorder(0, 0, 20, 20, NaN, NaN));
    CheckFalse('RegPolyCCBorder(NaN)',
      R.RegPolyCCBorder(10, 10, NaN, 5));

    // Huge radii must be rejected by the rasterization limits.
    CheckFalse('SPCircleBorder(1e30)', R.SPCircleBorder(10, 10, 1e30));
    CheckFalse('SPCircleFilled(1e30)', R.SPCircleFilled(10, 10, 1e30));
    CheckFalse('SPEllipseBorder(1e30)',
      R.SPEllipseBorder(10, 10, 1e30, 10));

    // Completely off-screen primitives are a successful no-op.
    CheckTrue('SPCircleBorder(off-screen)',
      R.SPCircleBorder(1e30, 1e30, 1));
    CheckTrue('SPEllipseBorder(off-screen)',
      R.SPEllipseBorder(1e30, 1e30, 10, 10));

    // Invalid polygon ranges.
    SetLength(PArr, 4);
    for i := 0 to High(PArr) do
      PArr[i].Init(10 + i * 10, 10);
    CheckFalse('PolygonBorder(count too big)',
      R.PolygonBorder(PArr, 0, 10));
    CheckFalse('PolygonBorder(negative index)',
      R.PolygonBorder(PArr, -1, 4));
    CheckTrue('PolygonBorder(empty)', R.PolygonBorder(PArr, 0, 0));

    // Non-finite polygon points.
    PArr[2].X := NaN;
    CheckFalse('SPPolygonFilled(NaN)', R.SPPolygonFilled(PArr, 0, 4));
    CheckFalse('SPPolygonFillOnly(NaN)', R.SPPolygonFillOnly(PArr, 0, 4));

    // Huge polygon must be clipped to the viewport, not loop forever.
    SetLength(PArr, 4);
    PArr[0].Init(-1e30, -1e30);
    PArr[1].Init(1e30, -1e30);
    PArr[2].Init(1e30, 1e30);
    PArr[3].Init(-1e30, 1e30);
    CheckTrue('SPPolygonFilled(huge)', R.SPPolygonFilled(PArr, 0, 4));

    // Regular polygon safety limits.
    CheckFalse('RegPolyCCBorder(NSides=0)',
      R.RegPolyCCBorder(10, 10, 10, 0));
    CheckFalse('RegPolyCCBorder(NSides too big)',
      R.RegPolyCCBorder(10, 10, 10, MaxRegPolySides + 1));

    // Odd number of points is valid for pair-based segments.
    SetLength(PArr, 3);
    PArr[0].Init(0, 0);
    PArr[1].Init(10, 0);
    PArr[2].Init(20, 0);
    CheckTrue('Segments(odd point count)', R.Segments(PArr, 0, 0));

    // Segment array variant.
    SetLength(SegArr, 2);
    SegArr[0].P1.Init(0, 0); SegArr[0].P2.Init(10, 10);
    SegArr[1].P1.Init(10, 10); SegArr[1].P2.Init(20, 0);
    CheckTrue('Segments(array)', R.Segments(SegArr, 0, 0));
    CheckFalse('Segments(array, bad count)', R.Segments(SegArr, 0, 5));

    // Color stack must stay balanced.
    CheckTrue('PushDrawColor', R.PushDrawColor(1, 0, 0, 1));
    CheckTrue('PushDrawColor(same)', R.PushDrawColor(1, 0, 0, 1));
    CheckTrue('PopDrawColor', R.PopDrawColor);
    CheckTrue('PopDrawColor', R.PopDrawColor);

    // Logical presentation stack must survive failed pushes/pops.
    CheckTrue('PushRenderSize', Win.PushRenderSize(160, 120));
    CheckTrue('PopRenderSize', Win.PopRenderSize);
    CheckTrue('PushRenderSize(0)', Win.PushRenderSize(0, 0));
    CheckTrue('PopRenderSize', Win.PopRenderSize);
  finally
    Win.Free;
  end;

  SDL_Quit;

  if Failures = 0 then
    WriteLn('All smoke checks passed.')
  else
    WriteLn(Failures, ' smoke check(s) failed.');

  if Failures <> 0 then
    Halt(1);
end.
