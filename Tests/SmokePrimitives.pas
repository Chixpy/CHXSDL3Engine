program SmokePrimitives;
{<
  Non-interactive smoke test for cCHXSDL3Renderer error handling, using
  CHXTests.

  It needs an SDL video driver. On headless environments it can be run with:

    SDL_VIDEODRIVER=dummy ./bin/SmokePrimitives

  The program exits with the CHXTests result code.

  (C) 2026 Chixpy https://github.com/Chixpy
}
{$mode ObjFPC}{$H+}{$INLINE ON}{$WARN 6058 OFF}
uses
  SysUtils, CTypes, Math, SDL3,
  ucCHXSDL3Window, ucCHXSDL3Renderer, uCHXSDL3TypeHelpers,
  ucCHXTestGroup, ucCHXTWConsole, ucCHXTWJSON, uCHXTestJSON;

type

  { cCHXSDL3RendererSmokeTests }

  cCHXSDL3RendererSmokeTests = class(cCHXTestGroup)
  private
    Win: cCHXSDL3Window;
    R: cCHXSDL3Renderer;
  protected
    procedure DoBeforeStart; override;
    procedure DoAfterEnd; override;
  published
    procedure TestBasicPrimitives;
    procedure TestCircles;
    procedure TestEllipses;
    procedure TestEllipseInRect;
    procedure TestRoundedRects;
    procedure TestRegularPolygons;
    procedure TestQuad;
    procedure TestTriangle;
    procedure TestFrame;
    procedure TestPolygon;
    procedure TestNonFinite;
    procedure TestHugeRadii;
    procedure TestOffscreen;
    procedure TestPolygonRanges;
    procedure TestRegularPolygonLimits;
    procedure TestSegments;
    procedure TestColorStack;
    procedure TestLogicalPresentation;
  end;

{
  cCHXSDL3RendererSmokeTests
}

procedure cCHXSDL3RendererSmokeTests.DoBeforeStart;
begin
  Win := cCHXSDL3Window.Create('SmokePrimitives', 320, 240, 1, False,
    'software');
  R := Win.Renderer;
end;

procedure cCHXSDL3RendererSmokeTests.DoAfterEnd;
begin
  Win.Free;
  Win := nil;
  R := nil;
  SDL_Quit;
end;

procedure cCHXSDL3RendererSmokeTests.TestBasicPrimitives;
begin
  MustTrue(R.Point(10, 10), 'Point');
  MustTrue(R.Line(0, 0, 20, 20), 'Line');
  MustTrue(R.RectBorder(0, 0, 20, 20), 'RectBorder');
  MustTrue(R.RectFilled(0, 0, 20, 20), 'RectFilled');
end;

procedure cCHXSDL3RendererSmokeTests.TestCircles;
begin
  // Valid shapes: exercise the rasterization loops and index arrays.
  MustTrue(R.CircleBorder(40, 40, 12), 'CircleBorder');
  MustTrue(R.CircleFilled(40, 40, 12), 'CircleFilled');
  MustTrue(R.CircleFillOnly(40, 40, 12), 'CircleFillOnly');
  MustTrue(R.SPCircleBorder(80, 40, 12), 'SPCircleBorder');
  MustTrue(R.SPCircleFilled(80, 40, 12), 'SPCircleFilled');
  MustTrue(R.SPCircleFillOnly(80, 40, 12), 'SPCircleFillOnly');
end;

procedure cCHXSDL3RendererSmokeTests.TestEllipses;
begin
  MustTrue(R.EllipseBorder(40, 100, 20, 10), 'EllipseBorder');
  MustTrue(R.EllipseFilled(40, 100, 20, 10), 'EllipseFilled');
  MustTrue(R.EllipseFillOnly(40, 100, 20, 10), 'EllipseFillOnly');
  MustTrue(R.SPEllipseBorder(100, 100, 20, 10), 'SPEllipseBorder');
  MustTrue(R.SPEllipseFilled(100, 100, 20, 10), 'SPEllipseFilled');
  MustTrue(R.SPEllipseFillOnly(100, 100, 20, 10), 'SPEllipseFillOnly');
end;

procedure cCHXSDL3RendererSmokeTests.TestEllipseInRect;
begin
  MustTrue(R.EllipseInRectBorder(150, 20, 40, 20),
    'EllipseInRectBorder');
  MustTrue(R.EllipseInRectFilled(150, 20, 40, 20),
    'EllipseInRectFilled');
  MustTrue(R.EllipseInRectFillOnly(150, 20, 40, 20),
    'EllipseInRectFillOnly');
end;

procedure cCHXSDL3RendererSmokeTests.TestRoundedRects;
begin
  MustTrue(R.SPRndRectCBorder(20, 160, 40, 30, 8), 'RndRectCBorder');
  MustTrue(R.SPRndRectCFilled(20, 160, 40, 30, 8), 'RndRectCFilled');
  MustTrue(R.SPRndRectCFillOnly(20, 160, 40, 30, 8),
    'RndRectCFillOnly');
  MustTrue(R.SPRndRectEBorder(80, 160, 40, 30, 12, 8),
    'RndRectEBorder');
  MustTrue(R.SPRndRectEFilled(80, 160, 40, 30, 12, 8),
    'RndRectEFilled');
  MustTrue(R.SPRndRectEFillOnly(80, 160, 40, 30, 12, 8),
    'RndRectEFillOnly');
end;

procedure cCHXSDL3RendererSmokeTests.TestRegularPolygons;
begin
  MustTrue(R.RegPolyCCBorder(200, 60, 20, 5), 'RegPolyCCBorder');
  MustTrue(R.RegPolyCCFilled(200, 60, 20, 5), 'RegPolyCCFilled');
  MustTrue(R.RegPolyCCFillOnly(200, 60, 20, 5), 'RegPolyCCFillOnly');
  MustTrue(R.RegPolySSBorder(250, 60, 20, 6), 'RegPolySSBorder');
  MustTrue(R.RegPolySSFilled(250, 60, 20, 6), 'RegPolySSFilled');
  MustTrue(R.RegPolySSFillOnly(250, 60, 20, 6), 'RegPolySSFillOnly');
end;

procedure cCHXSDL3RendererSmokeTests.TestQuad;
begin
  MustTrue(R.QuadBorder(180, 100, 220, 100, 220, 140,
    180, 140), 'QuadBorder');
  MustTrue(R.QuadFilled(180, 100, 220, 100, 220, 140,
    180, 140), 'QuadFilled');
  MustTrue(R.QuadFillOnly(180, 100, 220, 100, 220, 140,
    180, 140), 'QuadFillOnly');
  MustTrue(R.SPQuadBorder(180, 100, 220, 100, 220, 140,
    180, 140), 'SPQuadBorder');
  MustTrue(R.SPQuadFilled(180, 100, 220, 100, 220, 140,
    180, 140), 'SPQuadFilled');
  MustTrue(R.SPQuadFillOnly(180, 100, 220, 100, 220, 140,
    180, 140), 'SPQuadFillOnly');
end;

procedure cCHXSDL3RendererSmokeTests.TestTriangle;
begin
  MustTrue(R.TriangleBorder(240, 160, 280, 160, 260, 200),
    'TriangleBorder');
  MustTrue(R.TriangleFilled(240, 160, 280, 160, 260, 200),
    'TriangleFilled');
  MustTrue(R.TriangleFillOnly(240, 160, 280, 160, 260,
    200), 'TriangleFillOnly');
  MustTrue(R.SPTriangleBorder(240, 160, 280, 160, 260,
    200), 'SPTriangleBorder');
  MustTrue(R.SPTriangleFilled(240, 160, 280, 160, 260,
    200), 'SPTriangleFilled');
  MustTrue(R.SPTriangleFillOnly(240, 160, 280, 160, 260,
    200), 'SPTriangleFillOnly');
end;

procedure cCHXSDL3RendererSmokeTests.TestFrame;
begin
  MustTrue(R.FrameBorder(20, 210, 40, 20, 2), 'FrameBorder');
  MustTrue(R.FrameFilled(20, 210, 40, 20, 2), 'FrameFilled');
  MustTrue(R.FrameFillOnly(20, 210, 40, 20, 2), 'FrameFillOnly');
end;

procedure cCHXSDL3RendererSmokeTests.TestPolygon;
var
  PArr: TSDLFPointDynArray;
begin
  SetLength(PArr, 4);
  PArr[0].Init(10, 10);
  PArr[1].Init(50, 10);
  PArr[2].Init(50, 50);
  PArr[3].Init(10, 50);
  MustTrue(R.PolygonBorder(PArr), 'PolygonBorder');
  MustTrue(R.PolygonFilled(PArr), 'PolygonFilled');
  MustTrue(R.PolygonFillOnly(PArr), 'PolygonFillOnly');
  MustTrue(R.SPPolygonBorder(PArr), 'SPPolygonBorder');
  MustTrue(R.SPPolygonFilled(PArr), 'SPPolygonFilled');
  MustTrue(R.SPPolygonFillOnly(PArr), 'SPPolygonFillOnly');
end;

procedure cCHXSDL3RendererSmokeTests.TestNonFinite;
begin
  // Non-finite geometry must fail instead of hanging.
  MustFalse(R.CircleBorder(10, 10, NaN), 'CircleBorder(NaN)');
  MustFalse(R.CircleFilled(10, 10, NaN), 'CircleFilled(NaN)');
  MustFalse(R.SPCircleBorder(10, 10, NaN), 'SPCircleBorder(NaN)');
  MustFalse(R.EllipseBorder(10, 10, NaN, 10), 'EllipseBorder(NaN)');
  MustFalse(R.EllipseFilled(10, 10, NaN, 10), 'EllipseFilled(NaN)');
  MustFalse(R.SPRndRectCBorder(0, 0, 20, 20, NaN),
    'RndRectCBorder(NaN)');
  MustFalse(R.SPRndRectEBorder(0, 0, 20, 20, NaN, NaN),
    'RndRectEBorder(NaN)');
  MustFalse(R.RegPolyCCBorder(10, 10, NaN, 5), 'RegPolyCCBorder(NaN)');
end;

procedure cCHXSDL3RendererSmokeTests.TestHugeRadii;
begin
  // Huge radii must be rejected by the rasterization limits.
  MustFalse(R.SPCircleBorder(10, 10, 1e30), 'SPCircleBorder(1e30)');
  MustFalse(R.SPCircleFilled(10, 10, 1e30), 'SPCircleFilled(1e30)');
  MustFalse(R.SPEllipseBorder(10, 10, 1e30, 10),
    'SPEllipseBorder(1e30)');
end;

procedure cCHXSDL3RendererSmokeTests.TestOffscreen;
begin
  // Completely off-screen primitives are a successful no-op.
  MustTrue(R.SPCircleBorder(1e30, 1e30, 1),
    'SPCircleBorder(off-screen)');
  MustTrue(R.SPEllipseBorder(1e30, 1e30, 10, 10),
    'SPEllipseBorder(off-screen)');
end;

procedure cCHXSDL3RendererSmokeTests.TestPolygonRanges;
var
  PArr: TSDLFPointDynArray;
  i: Integer;
begin
  // Invalid polygon ranges.
  SetLength(PArr, 4);
  for i := 0 to High(PArr) do
    PArr[i].Init(10 + i * 10, 10);
  MustFalse(R.PolygonBorder(PArr, 0, 10), 'PolygonBorder(count too big)');
  MustFalse(R.PolygonBorder(PArr, -1, 4), 'PolygonBorder(negative index)');
  MustTrue(R.PolygonBorder(PArr, 0, 0), 'PolygonBorder(empty)');

  // Non-finite polygon points.
  PArr[2].X := NaN;
  MustFalse(R.SPPolygonFilled(PArr, 0, 4), 'SPPolygonFilled(NaN)');
  MustFalse(R.SPPolygonFillOnly(PArr, 0, 4), 'SPPolygonFillOnly(NaN)');

  // Huge polygon must be clipped to the viewport, not loop forever.
  SetLength(PArr, 4);
  PArr[0].Init(-1e30, -1e30);
  PArr[1].Init(1e30, -1e30);
  PArr[2].Init(1e30, 1e30);
  PArr[3].Init(-1e30, 1e30);
  MustTrue(R.SPPolygonFilled(PArr, 0, 4), 'SPPolygonFilled(huge)');
end;

procedure cCHXSDL3RendererSmokeTests.TestRegularPolygonLimits;
begin
  // Regular polygon safety limits.
  MustFalse(R.RegPolyCCBorder(10, 10, 10, 0), 'RegPolyCCBorder(NSides=0)');
  MustFalse(R.RegPolyCCBorder(10, 10, 10,
    MaxRegPolySides + 1), 'RegPolyCCBorder(NSides too big)');
end;

procedure cCHXSDL3RendererSmokeTests.TestSegments;
var
  PArr: TSDLFPointDynArray;
  SegArr: TSDLFSegmentDynArray;
begin
  // Odd number of points is valid for pair-based segments.
  SetLength(PArr, 3);
  PArr[0].Init(0, 0);
  PArr[1].Init(10, 0);
  PArr[2].Init(20, 0);
  MustTrue(R.Segments(PArr, 0, 0), 'Segments(odd point count)');

  // Segment array variant.
  SetLength(SegArr, 2);
  SegArr[0].P1.Init(0, 0); SegArr[0].P2.Init(10, 10);
  SegArr[1].P1.Init(10, 10); SegArr[1].P2.Init(20, 0);
  MustTrue(R.Segments(SegArr, 0, 0), 'Segments(array)');
  MustFalse(R.Segments(SegArr, 0, 5), 'Segments(array, bad count)');
end;

procedure cCHXSDL3RendererSmokeTests.TestColorStack;
begin
  // Color stack must stay balanced.
  MustTrue(R.PushDrawColor(1, 0, 0, 1), 'PushDrawColor');
  MustTrue(R.PushDrawColor(1, 0, 0, 1), 'PushDrawColor(same)');
  MustTrue(R.PopDrawColor, 'PopDrawColor');
  MustTrue(R.PopDrawColor, 'PopDrawColor');
end;

procedure cCHXSDL3RendererSmokeTests.TestLogicalPresentation;
begin
  // Logical presentation stack must survive failed pushes/pops.
  MustTrue(Win.PushRenderSize(160, 120), 'PushRenderSize');
  MustTrue(Win.PopRenderSize, 'PopRenderSize');
  MustTrue(Win.PushRenderSize(0, 0), 'PushRenderSize(0)');
  MustTrue(Win.PopRenderSize, 'PopRenderSize');
end;

{
  Main program
}

var
  MainTest: cCHXSDL3RendererSmokeTests;
  JSONWriter: cCHXTWJSON;

begin
  SDL_SetAppMetadata('SmokePrimitives', '1.0',
    'com.chixpy.SmokePrimitives');
  MainTest := cCHXSDL3RendererSmokeTests.Create;
  try
    MainTest.AddWriter(cCHXTWConsole);
    AddJSONWriter(MainTest, 'SmokePrimitives', JSONWriter);
    ExitCode := MainTest.RunAllCases;
    CheckJSONSaveError(JSONWriter, ExitCode);
  finally
    MainTest.Free;
  end;
end.
