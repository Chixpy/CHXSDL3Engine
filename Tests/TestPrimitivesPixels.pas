program TestPrimitivesPixels;
{<
  Non-interactive pixel tests for cCHXSDL3Renderer primitives, using CHXTests.

  A 320x240 software renderer with logical presentation disabled is used, so
  the expected pixels are deterministic. The suite focuses on the SP/FP
  ellipse families and checks minimal known pixels for the other primitives.

  Run with:

    SDL_VIDEODRIVER=dummy ./bin/TestPrimitivesPixels

  (C) 2026 Chixpy https://github.com/Chixpy
}
{$mode ObjFPC}{$H+}{$INLINE ON}{$WARN 6058 OFF}

uses
  SysUtils, Classes, CTypes, Math, SDL3,
  uCHXSDL3TypeHelpers,
  ucCHXSDL3Renderer,
  ucCHXTestGroup, ucCHXTWConsole, ucCHXTWJSON, uCHXTestJSON;

const
  kWidth = 320;
  kHeight = 240;
  kTol = 2; // Color tolerance for opaque drawing.
  kAlphaTol = 12; // Color tolerance for alpha blending.

  kRedR = 255;
  kRedG = 0;
  kRedB = 0;
  kGreenR = 0;
  kGreenG = 255;
  kGreenB = 0;
  kBlueR = 0;
  kBlueG = 0;
  kBlueB = 255;

type
  TPixel = record
    R, G, B, A: Byte;
  end;

  TFrame = array of TPixel;

  { cPrimitivesPixelsTests }

  cPrimitivesPixelsTests = class(cCHXTestGroup)
  private
    FWindow: PSDL_Window;
    FRender: cCHXSDL3Renderer;

    procedure ClearBlack;
    procedure SetRed;
    procedure SetGreen;
    procedure SetBlue;

    function Capture(out Frame: TFrame): Boolean;
    function ReadPixel(const Frame: TFrame; const X, Y: Integer;
      out R, G, B, A: Byte): Boolean;
    procedure CheckPixel(const Frame: TFrame; const X, Y: Integer;
      const ExpR, ExpG, ExpB, Tol: Integer; const Msg: String);
    procedure CheckAnyPixel(const Frame: TFrame;
      const X0, Y0, X1, Y1: Integer;
      const ExpR, ExpG, ExpB, Tol: Integer; const Msg: String);
    function CountNonBg(const Frame: TFrame): Integer;
    function BoundingBox(const Frame: TFrame;
      out MinX, MinY, MaxX, MaxY: Integer): Boolean;
    procedure CheckBounds(const Frame: TFrame;
      const MinX, MinY, MaxX, MaxY: Integer; const Msg: String);
    procedure CheckBoundsTol(const Frame: TFrame;
      const MinX, MinY, MaxX, MaxY, Tol: Integer; const Msg: String);
    function CompareFrames(const A, B: TFrame; out Diff: Integer): Boolean;
    procedure CheckFrameEqual(const A, B: TFrame; const Msg: String);
    procedure CheckFrameEmpty(const Frame: TFrame; const Msg: String);
    function MirrorFrameH(const Src: TFrame; const Cx: Integer): TFrame;
    function MirrorFrameV(const Src: TFrame; const Cy: Integer): TFrame;

    procedure CheckSPFP(const X, Y, RX, RY: CFloat; const Msg: String);
    procedure CheckFPRounding(const X, Y, RX, RY: CFloat; const Msg: String);
    procedure CheckSPFPInRect(const X, Y, W, H: CFloat; const Msg: String);
    procedure CheckFPRoundingInRect(const X, Y, W, H: CFloat;
      const Msg: String);
  protected
    procedure DoBeforeStart; override;
    procedure DoAfterEnd; override;
  published
    procedure TestEllipseBorder;
    procedure TestEllipseFilled;
    procedure TestEllipseFillOnly;
    procedure TestEllipseSymmetry;
    procedure TestEllipseExtremeRatios;
    procedure TestEllipseDegenerate;
    procedure TestEllipseNegativeRadii;
    procedure TestEllipseInRect;
    procedure TestEllipseAlpha;
    procedure TestEllipseClipping;
    procedure TestEllipseNonFinite;
    procedure TestEllipseColors;
    procedure TestFPvsSP;
    procedure TestPointAndLine;
    procedure TestRectAndFrame;
    procedure TestCirclePixels;
    procedure TestTriangleQuadPolygon;
  end;

{ cPrimitivesPixelsTests }

procedure cPrimitivesPixelsTests.DoBeforeStart;
var
  Raw: PSDL_Renderer;
begin
  inherited DoBeforeStart;

  SDL_Init(SDL_INIT_VIDEO);
  FWindow := SDL_CreateWindow('TestPrimitivesPixels', kWidth, kHeight, 0);
  if FWindow = nil then
  begin
    SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
      'TestPrimitivesPixels: cannot create window: %s', [SDL_GetError]);
    Exit;
  end;

  Raw := SDL_CreateRenderer(FWindow, PAnsiChar('software'));
  if Raw = nil then
  begin
    SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
      'TestPrimitivesPixels: cannot create renderer: %s', [SDL_GetError]);
    Exit;
  end;

  if not SDL_SetRenderLogicalPresentation(Raw, kWidth, kHeight,
    SDL_LOGICAL_PRESENTATION_DISABLED) then
  begin
    SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
      'TestPrimitivesPixels: cannot disable logical presentation: %s',
      [SDL_GetError]);
    Exit;
  end;

  FRender := cCHXSDL3Renderer.Create(Raw, True);
end;

procedure cPrimitivesPixelsTests.DoAfterEnd;
begin
  FreeAndNil(FRender);
  if FWindow <> nil then
  begin
    SDL_DestroyWindow(FWindow);
    FWindow := nil;
  end;
  SDL_Quit;
  inherited DoAfterEnd;
end;

procedure cPrimitivesPixelsTests.ClearBlack;
begin
  FRender.Clear(0, 0, 0, 1);
end;

procedure cPrimitivesPixelsTests.SetRed;
begin
  MustTrue(FRender.SetDrawColor(1, 0, 0, 1), 'set red');
end;

procedure cPrimitivesPixelsTests.SetGreen;
begin
  MustTrue(FRender.SetDrawColor(0, 1, 0, 1), 'set green');
end;

procedure cPrimitivesPixelsTests.SetBlue;
begin
  MustTrue(FRender.SetDrawColor(0, 0, 1, 1), 'set blue');
end;

function cPrimitivesPixelsTests.Capture(out Frame: TFrame): Boolean;
var
  Surf: PSDL_Surface;
  P: TPixel;
  x, y: Integer;
begin
  Frame := nil;
  Result := False;
  if FRender = nil then Exit;

  Surf := SDL_RenderReadPixels(FRender.SDLRenderer, nil);
  if Surf = nil then Exit;
  try
    SetLength(Frame, kWidth * kHeight);
    for y := 0 to kHeight - 1 do
      for x := 0 to kWidth - 1 do
      begin
        P.R := 0; P.G := 0; P.B := 0; P.A := 0;
        SDL_ReadSurfacePixel(Surf, x, y, @P.R, @P.G, @P.B, @P.A);
        Frame[y * kWidth + x] := P;
      end;
    Result := True;
  finally
    SDL_DestroySurface(Surf);
  end;
end;

function cPrimitivesPixelsTests.ReadPixel(const Frame: TFrame;
  const X, Y: Integer; out R, G, B, A: Byte): Boolean;
var
  P: TPixel;
begin
  R := 0; G := 0; B := 0; A := 0;
  Result := False;
  if (X < 0) or (X >= kWidth) or (Y < 0) or (Y >= kHeight) then Exit;
  if Length(Frame) <> kWidth * kHeight then Exit;

  P := Frame[Y * kWidth + X];
  R := P.R; G := P.G; B := P.B; A := P.A;
  Result := True;
end;

procedure cPrimitivesPixelsTests.CheckPixel(const Frame: TFrame;
  const X, Y: Integer; const ExpR, ExpG, ExpB, Tol: Integer;
  const Msg: String);
var
  R, G, B, A: Byte;
begin
  MustTrue(ReadPixel(Frame, X, Y, R, G, B, A), Msg + ': read pixel');
  MustTrue((Abs(R - ExpR) <= Tol) and (Abs(G - ExpG) <= Tol)
    and (Abs(B - ExpB) <= Tol),
    Format('%s: got (%d,%d,%d), expected (%d,%d,%d) +-%d',
    [Msg, R, G, B, ExpR, ExpG, ExpB, Tol]));
end;

procedure cPrimitivesPixelsTests.CheckAnyPixel(const Frame: TFrame;
  const X0, Y0, X1, Y1: Integer;
  const ExpR, ExpG, ExpB, Tol: Integer; const Msg: String);
var
  x, y: Integer;
  P: TPixel;
  Found: Boolean;
begin
  Found := False;
  for y := Y0 to Y1 do
    for x := X0 to X1 do
      if (x >= 0) and (x < kWidth) and (y >= 0) and (y < kHeight) then
      begin
        P := Frame[y * kWidth + x];
        if (Abs(P.R - ExpR) <= Tol) and (Abs(P.G - ExpG) <= Tol)
          and (Abs(P.B - ExpB) <= Tol) then
          Found := True;
      end;
  MustTrue(Found,
    Format('%s: no (%d,%d,%d) pixel in (%d,%d)-(%d,%d)',
    [Msg, ExpR, ExpG, ExpB, X0, Y0, X1, Y1]));
end;

function cPrimitivesPixelsTests.CountNonBg(const Frame: TFrame): Integer;
var
  i: Integer;
  P: TPixel;
begin
  Result := 0;
  for i := 0 to Length(Frame) - 1 do
  begin
    P := Frame[i];
    if (P.R > kTol) or (P.G > kTol) or (P.B > kTol) then
      Inc(Result);
  end;
end;

function cPrimitivesPixelsTests.BoundingBox(const Frame: TFrame;
  out MinX, MinY, MaxX, MaxY: Integer): Boolean;
var
  x, y: Integer;
  P: TPixel;
begin
  MinX := kWidth;
  MinY := kHeight;
  MaxX := -1;
  MaxY := -1;
  for y := 0 to kHeight - 1 do
    for x := 0 to kWidth - 1 do
    begin
      P := Frame[y * kWidth + x];
      if (P.R > kTol) or (P.G > kTol) or (P.B > kTol) then
      begin
        if x < MinX then MinX := x;
        if y < MinY then MinY := y;
        if x > MaxX then MaxX := x;
        if y > MaxY then MaxY := y;
      end;
    end;
  Result := MaxX >= MinX;
  if not Result then
  begin
    MinX := 0; MinY := 0; MaxX := -1; MaxY := -1;
  end;
end;

procedure cPrimitivesPixelsTests.CheckBounds(const Frame: TFrame;
  const MinX, MinY, MaxX, MaxY: Integer; const Msg: String);
var
  a, b, c, d: Integer;
begin
  MustTrue(BoundingBox(Frame, a, b, c, d), Msg + ': frame is empty');
  MustTrue((a = MinX) and (b = MinY) and (c = MaxX) and (d = MaxY),
    Format('%s: bbox (%d,%d)-(%d,%d), expected (%d,%d)-(%d,%d)',
    [Msg, a, b, c, d, MinX, MinY, MaxX, MaxY]));
end;

procedure cPrimitivesPixelsTests.CheckBoundsTol(const Frame: TFrame;
  const MinX, MinY, MaxX, MaxY, Tol: Integer; const Msg: String);
var
  a, b, c, d: Integer;
begin
  MustTrue(BoundingBox(Frame, a, b, c, d), Msg + ': frame is empty');
  MustTrue((Abs(a - MinX) <= Tol) and (Abs(b - MinY) <= Tol)
    and (Abs(c - MaxX) <= Tol) and (Abs(d - MaxY) <= Tol),
    Format('%s: bbox (%d,%d)-(%d,%d), expected (%d,%d)-(%d,%d) +-%d',
    [Msg, a, b, c, d, MinX, MinY, MaxX, MaxY, Tol]));
end;

function cPrimitivesPixelsTests.CompareFrames(const A, B: TFrame;
  out Diff: Integer): Boolean;
var
  i: Integer;
begin
  Diff := 0;
  Result := Length(A) = Length(B);
  if not Result then
  begin
    Diff := Abs(Length(A) - Length(B));
    Exit;
  end;

  for i := 0 to Length(A) - 1 do
    if (A[i].R <> B[i].R) or (A[i].G <> B[i].G)
      or (A[i].B <> B[i].B) then
      Inc(Diff);
  Result := Diff = 0;
end;

procedure cPrimitivesPixelsTests.CheckFrameEqual(const A, B: TFrame;
  const Msg: String);
var
  Diff: Integer;
begin
  Diff := 0;
  MustTrue(CompareFrames(A, B, Diff),
    Format('%s: %d pixels differ', [Msg, Diff]));
end;

procedure cPrimitivesPixelsTests.CheckFrameEmpty(const Frame: TFrame;
  const Msg: String);
begin
  MustTrue(CountNonBg(Frame) = 0, Msg + ': frame must be empty');
end;

function cPrimitivesPixelsTests.MirrorFrameH(const Src: TFrame;
  const Cx: Integer): TFrame;
var
  x, y, mx: Integer;
  P: TPixel;
begin
  Result := nil;
  SetLength(Result, Length(Src));
  P.R := 0; P.G := 0; P.B := 0; P.A := 255;
  for y := 0 to kHeight - 1 do
    for x := 0 to kWidth - 1 do
    begin
      mx := 2 * Cx - x;
      if (mx >= 0) and (mx < kWidth) then
        Result[y * kWidth + x] := Src[y * kWidth + mx]
      else
        Result[y * kWidth + x] := P;
    end;
end;

function cPrimitivesPixelsTests.MirrorFrameV(const Src: TFrame;
  const Cy: Integer): TFrame;
var
  x, y, my: Integer;
  P: TPixel;
begin
  Result := nil;
  SetLength(Result, Length(Src));
  P.R := 0; P.G := 0; P.B := 0; P.A := 255;
  for y := 0 to kHeight - 1 do
    for x := 0 to kWidth - 1 do
    begin
      my := 2 * Cy - y;
      if (my >= 0) and (my < kHeight) then
        Result[y * kWidth + x] := Src[my * kWidth + x]
      else
        Result[y * kWidth + x] := P;
    end;
end;

procedure cPrimitivesPixelsTests.CheckSPFP(const X, Y, RX, RY: CFloat;
  const Msg: String);
var
  A, B: TFrame;
begin
  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseBorder(X, Y, RX, RY), Msg + ': SP border');
  MustTrue(Capture(A), Msg + ': capture SP border');
  ClearBlack; SetRed;
  MustTrue(FRender.FPEllipseBorder(X, Y, RX, RY), Msg + ': FP border');
  MustTrue(Capture(B), Msg + ': capture FP border');
  CheckFrameEqual(A, B, Msg + ': border');

  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseFilled(X, Y, RX, RY), Msg + ': SP filled');
  MustTrue(Capture(A), Msg + ': capture SP filled');
  ClearBlack; SetRed;
  MustTrue(FRender.FPEllipseFilled(X, Y, RX, RY), Msg + ': FP filled');
  MustTrue(Capture(B), Msg + ': capture FP filled');
  CheckFrameEqual(A, B, Msg + ': filled');

  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseFillOnly(X, Y, RX, RY),
    Msg + ': SP fill-only');
  MustTrue(Capture(A), Msg + ': capture SP fill-only');
  ClearBlack; SetRed;
  MustTrue(FRender.FPEllipseFillOnly(X, Y, RX, RY),
    Msg + ': FP fill-only');
  MustTrue(Capture(B), Msg + ': capture FP fill-only');
  CheckFrameEqual(A, B, Msg + ': fill-only');
end;

procedure cPrimitivesPixelsTests.CheckFPRounding(const X, Y, RX, RY: CFloat;
  const Msg: String);
var
  A, B: TFrame;
  Xr, Yr, RXr, RYr: CFloat;
begin
  Xr := Round(X); Yr := Round(Y);
  RXr := Round(RX); RYr := Round(RY);

  ClearBlack; SetRed;
  MustTrue(FRender.FPEllipseBorder(X, Y, RX, RY), Msg + ': FP border');
  MustTrue(Capture(A), Msg + ': capture FP border');
  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseBorder(Xr, Yr, RXr, RYr),
    Msg + ': SP border rounded');
  MustTrue(Capture(B), Msg + ': capture SP border rounded');
  CheckFrameEqual(A, B, Msg + ': border rounding');

  ClearBlack; SetRed;
  MustTrue(FRender.FPEllipseFilled(X, Y, RX, RY), Msg + ': FP filled');
  MustTrue(Capture(A), Msg + ': capture FP filled');
  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseFilled(Xr, Yr, RXr, RYr),
    Msg + ': SP filled rounded');
  MustTrue(Capture(B), Msg + ': capture SP filled rounded');
  CheckFrameEqual(A, B, Msg + ': filled rounding');

  ClearBlack; SetRed;
  MustTrue(FRender.FPEllipseFillOnly(X, Y, RX, RY),
    Msg + ': FP fill-only');
  MustTrue(Capture(A), Msg + ': capture FP fill-only');
  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseFillOnly(Xr, Yr, RXr, RYr),
    Msg + ': SP fill-only rounded');
  MustTrue(Capture(B), Msg + ': capture SP fill-only rounded');
  CheckFrameEqual(A, B, Msg + ': fill-only rounding');
end;

procedure cPrimitivesPixelsTests.CheckSPFPInRect(const X, Y, W, H: CFloat;
  const Msg: String);
var
  A, B: TFrame;
begin
  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseInRectBorder(X, Y, W, H),
    Msg + ': SP border');
  MustTrue(Capture(A), Msg + ': capture SP border');
  ClearBlack; SetRed;
  MustTrue(FRender.FPEllipseInRectBorder(X, Y, W, H),
    Msg + ': FP border');
  MustTrue(Capture(B), Msg + ': capture FP border');
  CheckFrameEqual(A, B, Msg + ': border');

  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseInRectFilled(X, Y, W, H),
    Msg + ': SP filled');
  MustTrue(Capture(A), Msg + ': capture SP filled');
  ClearBlack; SetRed;
  MustTrue(FRender.FPEllipseInRectFilled(X, Y, W, H),
    Msg + ': FP filled');
  MustTrue(Capture(B), Msg + ': capture FP filled');
  CheckFrameEqual(A, B, Msg + ': filled');

  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseInRectFillOnly(X, Y, W, H),
    Msg + ': SP fill-only');
  MustTrue(Capture(A), Msg + ': capture SP fill-only');
  ClearBlack; SetRed;
  MustTrue(FRender.FPEllipseInRectFillOnly(X, Y, W, H),
    Msg + ': FP fill-only');
  MustTrue(Capture(B), Msg + ': capture FP fill-only');
  CheckFrameEqual(A, B, Msg + ': fill-only');
end;

procedure cPrimitivesPixelsTests.CheckFPRoundingInRect(
  const X, Y, W, H: CFloat; const Msg: String);
var
  A, B: TFrame;
  Xr, Yr, Wr, Hr: CFloat;
begin
  Xr := Round(X); Yr := Round(Y);
  Wr := Round(W); Hr := Round(H);

  ClearBlack; SetRed;
  MustTrue(FRender.FPEllipseInRectBorder(X, Y, W, H),
    Msg + ': FP border');
  MustTrue(Capture(A), Msg + ': capture FP border');
  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseInRectBorder(Xr, Yr, Wr, Hr),
    Msg + ': SP border rounded');
  MustTrue(Capture(B), Msg + ': capture SP border rounded');
  CheckFrameEqual(A, B, Msg + ': border rounding');

  ClearBlack; SetRed;
  MustTrue(FRender.FPEllipseInRectFilled(X, Y, W, H),
    Msg + ': FP filled');
  MustTrue(Capture(A), Msg + ': capture FP filled');
  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseInRectFilled(Xr, Yr, Wr, Hr),
    Msg + ': SP filled rounded');
  MustTrue(Capture(B), Msg + ': capture SP filled rounded');
  CheckFrameEqual(A, B, Msg + ': filled rounding');

  ClearBlack; SetRed;
  MustTrue(FRender.FPEllipseInRectFillOnly(X, Y, W, H),
    Msg + ': FP fill-only');
  MustTrue(Capture(A), Msg + ': capture FP fill-only');
  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseInRectFillOnly(Xr, Yr, Wr, Hr),
    Msg + ': SP fill-only rounded');
  MustTrue(Capture(B), Msg + ': capture SP fill-only rounded');
  CheckFrameEqual(A, B, Msg + ': fill-only rounding');
end;

{
  Ellipse pixel tests.
}

procedure cPrimitivesPixelsTests.TestEllipseBorder;
var
  F: TFrame;
begin
  MustTrue(Assigned(FRender), 'setup: renderer');
  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseBorder(160, 120, 40, 20),
    'SPEllipseBorder');
  MustTrue(Capture(F), 'capture border');

  CheckPixel(F, 120, 120, kRedR, kRedG, kRedB, kTol, 'left cardinal');
  CheckPixel(F, 200, 120, kRedR, kRedG, kRedB, kTol, 'right cardinal');
  CheckPixel(F, 160, 100, kRedR, kRedG, kRedB, kTol, 'top cardinal');
  CheckPixel(F, 160, 140, kRedR, kRedG, kRedB, kTol, 'bottom cardinal');
  CheckPixel(F, 160, 120, 0, 0, 0, kTol, 'center is empty');
  CheckBounds(F, 120, 100, 200, 140, 'border bbox');
end;

procedure cPrimitivesPixelsTests.TestEllipseFilled;
var
  F: TFrame;
begin
  MustTrue(Assigned(FRender), 'setup: renderer');
  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseFilled(160, 120, 40, 20),
    'SPEllipseFilled');
  MustTrue(Capture(F), 'capture filled');

  CheckPixel(F, 160, 120, kRedR, kRedG, kRedB, kTol, 'center filled');
  CheckPixel(F, 120, 120, kRedR, kRedG, kRedB, kTol, 'left cardinal');
  CheckPixel(F, 200, 120, kRedR, kRedG, kRedB, kTol, 'right cardinal');
  CheckPixel(F, 160, 100, kRedR, kRedG, kRedB, kTol, 'top cardinal');
  CheckPixel(F, 160, 140, kRedR, kRedG, kRedB, kTol, 'bottom cardinal');
  CheckPixel(F, 160, 110, kRedR, kRedG, kRedB, kTol, 'inside vertical');
  CheckPixel(F, 140, 120, kRedR, kRedG, kRedB, kTol, 'inside horizontal');

  CheckPixel(F, 160, 99, 0, 0, 0, kTol, 'outside top');
  CheckPixel(F, 160, 141, 0, 0, 0, kTol, 'outside bottom');
  CheckPixel(F, 119, 120, 0, 0, 0, kTol, 'outside left');
  CheckPixel(F, 201, 120, 0, 0, 0, kTol, 'outside right');

  CheckBounds(F, 120, 100, 200, 140, 'filled bbox');
  MustTrue(CountNonBg(F) > 2000,
    Format('filled area too small: %d', [CountNonBg(F)]));

  // RX = RY: a circular ellipse.
  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseFilled(160, 120, 30, 30),
    'SPEllipseFilled RX = RY');
  MustTrue(Capture(F), 'capture circular ellipse');
  CheckPixel(F, 160, 120, kRedR, kRedG, kRedB, kTol, 'circular center');
  CheckPixel(F, 130, 120, kRedR, kRedG, kRedB, kTol, 'circular left');
  CheckPixel(F, 190, 120, kRedR, kRedG, kRedB, kTol, 'circular right');
  CheckPixel(F, 160, 90, kRedR, kRedG, kRedB, kTol, 'circular top');
  CheckPixel(F, 160, 150, kRedR, kRedG, kRedB, kTol, 'circular bottom');
  CheckPixel(F, 129, 120, 0, 0, 0, kTol, 'circular outside left');
  CheckPixel(F, 160, 89, 0, 0, 0, kTol, 'circular outside top');
  CheckBounds(F, 130, 90, 190, 150, 'circular ellipse bbox');
end;

procedure cPrimitivesPixelsTests.TestEllipseFillOnly;
var
  F: TFrame;
begin
  MustTrue(Assigned(FRender), 'setup: renderer');
  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseBorder(160, 120, 40, 20), 'border');
  SetBlue;
  MustTrue(FRender.SPEllipseFillOnly(160, 120, 40, 20), 'fill-only');
  MustTrue(Capture(F), 'capture fill-only');

  CheckPixel(F, 160, 120, kBlueR, kBlueG, kBlueB, kTol, 'center filled');
  CheckPixel(F, 120, 120, kRedR, kRedG, kRedB, kTol, 'left border');
  CheckPixel(F, 200, 120, kRedR, kRedG, kRedB, kTol, 'right border');
  CheckPixel(F, 160, 100, kRedR, kRedG, kRedB, kTol, 'top border');
  CheckPixel(F, 160, 140, kRedR, kRedG, kRedB, kTol, 'bottom border');
  CheckPixel(F, 121, 120, kBlueR, kBlueG, kBlueB, kTol, 'inside left');
  CheckPixel(F, 199, 120, kBlueR, kBlueG, kBlueB, kTol, 'inside right');
  CheckPixel(F, 160, 101, kBlueR, kBlueG, kBlueB, kTol, 'inside top');
  CheckPixel(F, 160, 139, kBlueR, kBlueG, kBlueB, kTol, 'inside bottom');

  CheckPixel(F, 160, 99, 0, 0, 0, kTol, 'outside top');
  CheckPixel(F, 119, 120, 0, 0, 0, kTol, 'outside left');
  CheckBounds(F, 120, 100, 200, 140, 'fill-only bbox');
end;

procedure cPrimitivesPixelsTests.TestEllipseSymmetry;
var
  F: TFrame;
begin
  MustTrue(Assigned(FRender), 'setup: renderer');

  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseFilled(160, 120, 40, 20), 'filled');
  MustTrue(Capture(F), 'capture filled');
  CheckFrameEqual(F, MirrorFrameH(F, 160), 'filled horizontal symmetry');
  CheckFrameEqual(F, MirrorFrameV(F, 120), 'filled vertical symmetry');

  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseBorder(160, 120, 40, 20), 'border');
  MustTrue(Capture(F), 'capture border');
  CheckFrameEqual(F, MirrorFrameH(F, 160), 'border horizontal symmetry');
  CheckFrameEqual(F, MirrorFrameV(F, 120), 'border vertical symmetry');
end;

procedure cPrimitivesPixelsTests.TestEllipseExtremeRatios;
var
  F: TFrame;
begin
  MustTrue(Assigned(FRender), 'setup: renderer');

  // Tall ellipse: RY >> RX.
  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseFilled(160, 120, 5, 80), 'tall filled');
  MustTrue(Capture(F), 'capture tall filled');
  CheckPixel(F, 160, 120, kRedR, kRedG, kRedB, kTol, 'tall center');
  CheckPixel(F, 160, 40, kRedR, kRedG, kRedB, kTol, 'tall top');
  CheckPixel(F, 160, 200, kRedR, kRedG, kRedB, kTol, 'tall bottom');
  CheckPixel(F, 155, 120, kRedR, kRedG, kRedB, kTol, 'tall left');
  CheckPixel(F, 165, 120, kRedR, kRedG, kRedB, kTol, 'tall right');
  CheckPixel(F, 160, 50, kRedR, kRedG, kRedB, kTol, 'tall near top');
  CheckBounds(F, 155, 40, 165, 200, 'tall filled bbox');

  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseBorder(160, 120, 5, 80), 'tall border');
  MustTrue(Capture(F), 'capture tall border');
  CheckPixel(F, 160, 40, kRedR, kRedG, kRedB, kTol, 'tall border top');
  CheckPixel(F, 160, 200, kRedR, kRedG, kRedB, kTol, 'tall border bottom');
  CheckPixel(F, 155, 120, kRedR, kRedG, kRedB, kTol, 'tall border left');
  CheckPixel(F, 165, 120, kRedR, kRedG, kRedB, kTol, 'tall border right');
  CheckPixel(F, 160, 50, 0, 0, 0, kTol, 'tall border interior');
  CheckBounds(F, 155, 40, 165, 200, 'tall border bbox');

  // Flat ellipse: RX >> RY.
  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseFilled(160, 120, 80, 5), 'flat filled');
  MustTrue(Capture(F), 'capture flat filled');
  CheckPixel(F, 160, 120, kRedR, kRedG, kRedB, kTol, 'flat center');
  CheckPixel(F, 80, 120, kRedR, kRedG, kRedB, kTol, 'flat left');
  CheckPixel(F, 240, 120, kRedR, kRedG, kRedB, kTol, 'flat right');
  CheckPixel(F, 160, 115, kRedR, kRedG, kRedB, kTol, 'flat top');
  CheckPixel(F, 160, 125, kRedR, kRedG, kRedB, kTol, 'flat bottom');
  CheckPixel(F, 90, 120, kRedR, kRedG, kRedB, kTol, 'flat near left');
  CheckBounds(F, 80, 115, 240, 125, 'flat filled bbox');

  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseBorder(160, 120, 80, 5), 'flat border');
  MustTrue(Capture(F), 'capture flat border');
  CheckPixel(F, 80, 120, kRedR, kRedG, kRedB, kTol, 'flat border left');
  CheckPixel(F, 240, 120, kRedR, kRedG, kRedB, kTol, 'flat border right');
  CheckPixel(F, 160, 115, kRedR, kRedG, kRedB, kTol, 'flat border top');
  CheckPixel(F, 160, 125, kRedR, kRedG, kRedB, kTol, 'flat border bottom');
  CheckPixel(F, 90, 120, 0, 0, 0, kTol, 'flat border interior');
  CheckBounds(F, 80, 115, 240, 125, 'flat border bbox');
end;

procedure cPrimitivesPixelsTests.TestEllipseDegenerate;
var
  F: TFrame;
begin
  MustTrue(Assigned(FRender), 'setup: renderer');

  // RX = 0: vertical line.
  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseBorder(160, 120, 0, 10), 'vertical border');
  MustTrue(Capture(F), 'capture vertical border');
  CheckPixel(F, 160, 110, kRedR, kRedG, kRedB, kTol, 'vertical top');
  CheckPixel(F, 160, 120, kRedR, kRedG, kRedB, kTol, 'vertical center');
  CheckPixel(F, 160, 130, kRedR, kRedG, kRedB, kTol, 'vertical bottom');
  CheckPixel(F, 159, 120, 0, 0, 0, kTol, 'vertical left empty');
  CheckPixel(F, 161, 120, 0, 0, 0, kTol, 'vertical right empty');
  CheckBounds(F, 160, 110, 160, 130, 'vertical bbox');

  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseFilled(160, 120, 0, 10), 'vertical filled');
  MustTrue(Capture(F), 'capture vertical filled');
  CheckPixel(F, 160, 110, kRedR, kRedG, kRedB, kTol, 'vertical filled top');
  CheckPixel(F, 160, 130, kRedR, kRedG, kRedB, kTol, 'vertical filled bottom');
  CheckBounds(F, 160, 110, 160, 130, 'vertical filled bbox');

  ClearBlack; SetBlue;
  MustTrue(FRender.SPEllipseFillOnly(160, 120, 0, 10),
    'vertical fill-only');
  MustTrue(Capture(F), 'capture vertical fill-only');
  CheckFrameEmpty(F, 'vertical fill-only');

  // RY = 0: horizontal line.
  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseBorder(160, 120, 10, 0), 'horizontal border');
  MustTrue(Capture(F), 'capture horizontal border');
  CheckPixel(F, 150, 120, kRedR, kRedG, kRedB, kTol, 'horizontal left');
  CheckPixel(F, 160, 120, kRedR, kRedG, kRedB, kTol, 'horizontal center');
  CheckPixel(F, 170, 120, kRedR, kRedG, kRedB, kTol, 'horizontal right');
  CheckPixel(F, 160, 119, 0, 0, 0, kTol, 'horizontal top empty');
  CheckPixel(F, 160, 121, 0, 0, 0, kTol, 'horizontal bottom empty');
  CheckBounds(F, 150, 120, 170, 120, 'horizontal bbox');

  // RX = RY = 0: one pixel.
  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseBorder(160, 120, 0, 0), 'point border');
  MustTrue(Capture(F), 'capture point border');
  CheckPixel(F, 160, 120, kRedR, kRedG, kRedB, kTol, 'point');
  CheckBounds(F, 160, 120, 160, 120, 'point bbox');

  // Subpixel degenerate: a small rectangle around the center.
  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseBorder(160, 120, 0.5, 10.5),
    'subpixel degenerate border');
  MustTrue(Capture(F), 'capture subpixel degenerate border');
  CheckPixel(F, 160, 120, kRedR, kRedG, kRedB, kTol,
    'subpixel degenerate center');
  CheckBoundsTol(F, 159, 109, 161, 131, 1,
    'subpixel degenerate bbox');

  ClearBlack; SetBlue;
  MustTrue(FRender.SPEllipseFillOnly(160, 120, 0.5, 10.5),
    'subpixel degenerate fill-only');
  MustTrue(Capture(F), 'capture subpixel degenerate fill-only');
  CheckFrameEmpty(F, 'subpixel degenerate fill-only');
end;

procedure cPrimitivesPixelsTests.TestEllipseNegativeRadii;
var
  A, B: TFrame;
begin
  MustTrue(Assigned(FRender), 'setup: renderer');

  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseBorder(160, 120, -40, -20),
    'negative border');
  MustTrue(Capture(A), 'capture negative border');
  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseBorder(160, 120, 40, 20),
    'positive border');
  MustTrue(Capture(B), 'capture positive border');
  CheckFrameEqual(A, B, 'negative border equals positive');

  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseFilled(160, 120, -40, -20),
    'negative filled');
  MustTrue(Capture(A), 'capture negative filled');
  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseFilled(160, 120, 40, 20),
    'positive filled');
  MustTrue(Capture(B), 'capture positive filled');
  CheckFrameEqual(A, B, 'negative filled equals positive');

  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseFillOnly(160, 120, -40, -20),
    'negative fill-only');
  MustTrue(Capture(A), 'capture negative fill-only');
  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseFillOnly(160, 120, 40, 20),
    'positive fill-only');
  MustTrue(Capture(B), 'capture positive fill-only');
  CheckFrameEqual(A, B, 'negative fill-only equals positive');
end;

procedure cPrimitivesPixelsTests.TestEllipseInRect;
var
  F: TFrame;
begin
  MustTrue(Assigned(FRender), 'setup: renderer');

  // Odd diameter: the ellipse touches both rect edges.
  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseInRectBorder(100, 50, 61, 41),
    'in-rect border');
  MustTrue(Capture(F), 'capture in-rect border');
  CheckPixel(F, 130, 70, 0, 0, 0, kTol, 'in-rect center empty');
  CheckPixel(F, 100, 70, kRedR, kRedG, kRedB, kTol, 'in-rect left');
  CheckPixel(F, 160, 70, kRedR, kRedG, kRedB, kTol, 'in-rect right');
  CheckPixel(F, 130, 50, kRedR, kRedG, kRedB, kTol, 'in-rect top');
  CheckPixel(F, 130, 90, kRedR, kRedG, kRedB, kTol, 'in-rect bottom');
  CheckBounds(F, 100, 50, 160, 90, 'in-rect border bbox');

  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseInRectFilled(100, 50, 61, 41),
    'in-rect filled');
  MustTrue(Capture(F), 'capture in-rect filled');
  CheckPixel(F, 130, 70, kRedR, kRedG, kRedB, kTol, 'in-rect center filled');
  CheckPixel(F, 100, 70, kRedR, kRedG, kRedB, kTol, 'in-rect filled left');
  CheckPixel(F, 160, 70, kRedR, kRedG, kRedB, kTol, 'in-rect filled right');
  CheckPixel(F, 130, 50, kRedR, kRedG, kRedB, kTol, 'in-rect filled top');
  CheckPixel(F, 130, 90, kRedR, kRedG, kRedB, kTol, 'in-rect filled bottom');
  CheckPixel(F, 99, 70, 0, 0, 0, kTol, 'in-rect outside left');
  CheckPixel(F, 161, 70, 0, 0, 0, kTol, 'in-rect outside right');
  CheckPixel(F, 130, 49, 0, 0, 0, kTol, 'in-rect outside top');
  CheckPixel(F, 130, 91, 0, 0, 0, kTol, 'in-rect outside bottom');
  CheckBounds(F, 100, 50, 160, 90, 'in-rect filled bbox');

  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseInRectBorder(100, 50, 61, 41),
    'in-rect fill-only border');
  SetBlue;
  MustTrue(FRender.SPEllipseInRectFillOnly(100, 50, 61, 41),
    'in-rect fill-only');
  MustTrue(Capture(F), 'capture in-rect fill-only');
  CheckPixel(F, 130, 70, kBlueR, kBlueG, kBlueB, kTol,
    'in-rect fill-only center');
  CheckPixel(F, 100, 70, kRedR, kRedG, kRedB, kTol,
    'in-rect fill-only left border');
  CheckPixel(F, 160, 70, kRedR, kRedG, kRedB, kTol,
    'in-rect fill-only right border');
  CheckPixel(F, 130, 50, kRedR, kRedG, kRedB, kTol,
    'in-rect fill-only top border');
  CheckPixel(F, 130, 90, kRedR, kRedG, kRedB, kTol,
    'in-rect fill-only bottom border');
  CheckPixel(F, 130, 51, kBlueR, kBlueG, kBlueB, kTol,
    'in-rect fill-only inside top');
  CheckPixel(F, 130, 89, kBlueR, kBlueG, kBlueB, kTol,
    'in-rect fill-only inside bottom');

  // Even diameter: subpixel center and radii.
  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseInRectBorder(100, 50, 60, 40),
    'even in-rect border');
  MustTrue(Capture(F), 'capture even in-rect border');
  CheckPixel(F, 129, 69, 0, 0, 0, kTol, 'even in-rect center empty');
  CheckAnyPixel(F, 100, 68, 100, 70, kRedR, kRedG, kRedB, kTol,
    'even in-rect left');
  CheckAnyPixel(F, 159, 68, 159, 70, kRedR, kRedG, kRedB, kTol,
    'even in-rect right');
  CheckAnyPixel(F, 128, 50, 130, 50, kRedR, kRedG, kRedB, kTol,
    'even in-rect top');
  CheckAnyPixel(F, 128, 89, 130, 89, kRedR, kRedG, kRedB, kTol,
    'even in-rect bottom');
  CheckBounds(F, 100, 50, 159, 89, 'even in-rect border bbox');

  // Negative W/H: FP normalizes through SP.
  ClearBlack; SetRed;
  MustTrue(FRender.FPEllipseInRectBorder(160, 90, -60, -40),
    'negative in-rect border');
  MustTrue(Capture(F), 'capture negative in-rect border');
  CheckAnyPixel(F, 99, 69, 99, 70, kRedR, kRedG, kRedB, kTol,
    'negative in-rect left');
  CheckAnyPixel(F, 160, 69, 160, 70, kRedR, kRedG, kRedB, kTol,
    'negative in-rect right');
  CheckAnyPixel(F, 129, 49, 130, 49, kRedR, kRedG, kRedB, kTol,
    'negative in-rect top');
  CheckAnyPixel(F, 129, 90, 130, 90, kRedR, kRedG, kRedB, kTol,
    'negative in-rect bottom');
  CheckBoundsTol(F, 99, 49, 160, 90, 1,
    'negative in-rect border bbox');
end;

procedure cPrimitivesPixelsTests.TestEllipseAlpha;
var
  F: TFrame;
begin
  MustTrue(Assigned(FRender), 'setup: renderer');

  ClearBlack;
  MustTrue(FRender.SetDrawColor(1, 0, 0, 0.5), 'set alpha red');
  MustTrue(FRender.SPEllipseFilled(160, 120, 20, 10), 'alpha filled');
  MustTrue(Capture(F), 'capture alpha filled');
  CheckPixel(F, 160, 120, 128, 0, 0, kAlphaTol, 'alpha center');
  CheckPixel(F, 160, 89, 0, 0, 0, kTol, 'alpha outside top');

  ClearBlack;
  MustTrue(FRender.SetDrawColor(1, 0, 0, 0.5), 'set FP alpha red');
  MustTrue(FRender.FPEllipseFilled(160, 120, 20, 10), 'FP alpha filled');
  MustTrue(Capture(F), 'capture FP alpha filled');
  CheckPixel(F, 160, 120, 128, 0, 0, kAlphaTol, 'FP alpha center');
end;

procedure cPrimitivesPixelsTests.TestEllipseClipping;
var
  F: TFrame;
begin
  MustTrue(Assigned(FRender), 'setup: renderer');

  // Partially off-screen on the left.
  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseFilled(0, 120, 40, 20),
    'clipped filled');
  MustTrue(Capture(F), 'capture clipped filled');
  CheckPixel(F, 0, 120, kRedR, kRedG, kRedB, kTol, 'clipped at x=0');
  CheckPixel(F, 1, 120, kRedR, kRedG, kRedB, kTol, 'clipped at x=1');
  CheckPixel(F, 39, 120, kRedR, kRedG, kRedB, kTol, 'clipped at x=39');
  CheckPixel(F, 40, 120, kRedR, kRedG, kRedB, kTol, 'clipped right cardinal');
  CheckPixel(F, 41, 120, 0, 0, 0, kTol, 'clipped outside right');
  CheckBounds(F, 0, 100, 40, 140, 'clipped bbox');

  // Completely off-screen.
  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseFilled(1000, 1000, 10, 10),
    'off-screen bottom-right');
  MustTrue(Capture(F), 'capture off-screen bottom-right');
  CheckFrameEmpty(F, 'off-screen bottom-right');

  MustTrue(FRender.SPEllipseFilled(-1000, 120, 10, 10),
    'off-screen left');
  MustTrue(Capture(F), 'capture off-screen left');
  CheckFrameEmpty(F, 'off-screen left');

  // Huge ellipse covering the whole window.
  ClearBlack; SetRed;
  MustTrue(FRender.SPEllipseFilled(160, 120, 1000, 1000),
    'huge filled');
  MustTrue(Capture(F), 'capture huge filled');
  CheckPixel(F, 0, 0, kRedR, kRedG, kRedB, kTol, 'huge top-left');
  CheckPixel(F, kWidth - 1, 0, kRedR, kRedG, kRedB, kTol, 'huge top-right');
  CheckPixel(F, 0, kHeight - 1, kRedR, kRedG, kRedB, kTol, 'huge bottom-left');
  CheckPixel(F, kWidth - 1, kHeight - 1, kRedR, kRedG, kRedB, kTol,
    'huge bottom-right');
end;

procedure cPrimitivesPixelsTests.TestEllipseNonFinite;
var
  F: TFrame;
begin
  MustTrue(Assigned(FRender), 'setup: renderer');
  ClearBlack; SetRed;

  MustFalse(FRender.SPEllipseBorder(NaN, 120, 40, 20),
    'SP border NaN');
  MustFalse(FRender.SPEllipseFilled(160, 120, Infinity, 20),
    'SP filled Infinity');
  MustFalse(FRender.SPEllipseFillOnly(160, 120, 40, NaN),
    'SP fill-only NaN');
  MustFalse(FRender.FPEllipseBorder(NaN, 120, 40, 20),
    'FP border NaN');
  MustFalse(FRender.FPEllipseFilled(160, 120, Infinity, 20),
    'FP filled Infinity');
  MustFalse(FRender.FPEllipseFillOnly(160, 120, 40, NaN),
    'FP fill-only NaN');
  MustFalse(FRender.FPEllipseInRectBorder(NaN, 50, 60, 40),
    'FP in-rect border NaN');
  MustFalse(FRender.FPEllipseInRectFilled(100, 50, Infinity, 40),
    'FP in-rect filled Infinity');
  MustFalse(FRender.FPEllipseInRectFillOnly(100, 50, 60, NaN),
    'FP in-rect fill-only NaN');

  MustTrue(Capture(F), 'capture non-finite');
  CheckFrameEmpty(F, 'non-finite draws nothing');
end;

procedure cPrimitivesPixelsTests.TestEllipseColors;
var
  F: TFrame;
begin
  MustTrue(Assigned(FRender), 'setup: renderer');

  ClearBlack;
  MustTrue(FRender.FPEllipse(160, 120, 40, 20,
    SDLFColor(1, 0, 0, 1), SDLFColor(0, 0, 1, 1)), 'FPEllipse colors');
  MustTrue(Capture(F), 'capture FPEllipse colors');
  CheckPixel(F, 160, 120, kBlueR, kBlueG, kBlueB, kTol, 'FP center fill');
  CheckPixel(F, 120, 120, kRedR, kRedG, kRedB, kTol, 'FP left border');
  CheckPixel(F, 160, 100, kRedR, kRedG, kRedB, kTol, 'FP top border');
  CheckPixel(F, 160, 99, 0, 0, 0, kTol, 'FP outside');

  ClearBlack;
  MustTrue(FRender.FPEllipse(160, 120, 40, 20,
    SDLFColor(0, 1, 0, 1), SDLFColor(0, 1, 0, 1)), 'FPEllipse same color');
  MustTrue(Capture(F), 'capture FPEllipse same color');
  CheckPixel(F, 160, 120, kGreenR, kGreenG, kGreenB, kTol,
    'FP same color center');
  CheckPixel(F, 120, 120, kGreenR, kGreenG, kGreenB, kTol,
    'FP same color left');

  ClearBlack;
  MustTrue(FRender.FPEllipse(160, 120, 40, 20,
    SDLFColor(1, 0, 0, 1), SDLFColor(0, 0, 1, 0)),
    'FPEllipse no fill');
  MustTrue(Capture(F), 'capture FPEllipse no fill');
  CheckPixel(F, 160, 120, 0, 0, 0, kTol, 'FP no fill center');
  CheckPixel(F, 120, 120, kRedR, kRedG, kRedB, kTol, 'FP no fill border');

  ClearBlack;
  MustTrue(FRender.FPEllipse(160, 120, 40, 20,
    SDLFColor(1, 0, 0, 0), SDLFColor(0, 0, 1, 1)),
    'FPEllipse no border');
  MustTrue(Capture(F), 'capture FPEllipse no border');
  CheckPixel(F, 160, 120, kBlueR, kBlueG, kBlueB, kTol,
    'FP no border center');
  CheckPixel(F, 120, 120, 0, 0, 0, kTol, 'FP no border left');
end;

procedure cPrimitivesPixelsTests.TestFPvsSP;
begin
  MustTrue(Assigned(FRender), 'setup: renderer');

  CheckSPFP(160, 120, 40, 20, 'int 40x20');
  CheckSPFP(160, 120, 1, 1, 'int 1x1');
  CheckSPFP(160, 120, 0, 10, 'int 0x10');
  CheckSPFP(160, 120, 10, 0, 'int 10x0');
  CheckSPFP(160, 120, -20, -10, 'int negative');

  CheckFPRounding(160.4, 120.6, 40.4, 20.6, 'fractional .4/.6');
  CheckFPRounding(160.5, 120.5, 40.5, 20.5, 'fractional .5');

  CheckSPFPInRect(100, 50, 61, 41, 'in-rect odd');
  CheckSPFPInRect(100, 50, 60, 40, 'in-rect even');
  CheckSPFPInRect(160, 90, -60, -40, 'in-rect negative');
  CheckFPRoundingInRect(100.4, 50.6, 60.6, 40.4, 'in-rect fractional');
end;

{
  Minimal pixel tests for the other primitives.
}

procedure cPrimitivesPixelsTests.TestPointAndLine;
var
  F: TFrame;
begin
  MustTrue(Assigned(FRender), 'setup: renderer');

  ClearBlack; SetRed;
  MustTrue(FRender.SPPoint(10, 10), 'SPPoint');
  MustTrue(Capture(F), 'capture point');
  CheckPixel(F, 10, 10, kRedR, kRedG, kRedB, kTol, 'point');
  CheckPixel(F, 9, 10, 0, 0, 0, kTol, 'point left empty');
  CheckPixel(F, 11, 10, 0, 0, 0, kTol, 'point right empty');
  CheckBounds(F, 10, 10, 10, 10, 'point bbox');

  ClearBlack; SetRed;
  MustTrue(FRender.FPPoint(20, 20), 'FPPoint');
  MustTrue(Capture(F), 'capture FP point');
  CheckPixel(F, 20, 20, kRedR, kRedG, kRedB, kTol, 'FP point');

  ClearBlack; SetRed;
  MustTrue(FRender.SPLine(20, 40, 60, 40), 'SPLine horizontal');
  MustTrue(Capture(F), 'capture horizontal line');
  CheckPixel(F, 20, 40, kRedR, kRedG, kRedB, kTol, 'horizontal start');
  CheckPixel(F, 40, 40, kRedR, kRedG, kRedB, kTol, 'horizontal middle');
  CheckPixel(F, 60, 40, kRedR, kRedG, kRedB, kTol, 'horizontal end');
  CheckPixel(F, 20, 39, 0, 0, 0, kTol, 'horizontal above empty');
  CheckPixel(F, 20, 41, 0, 0, 0, kTol, 'horizontal below empty');
  CheckBounds(F, 20, 40, 60, 40, 'horizontal line bbox');

  ClearBlack; SetRed;
  MustTrue(FRender.SPLine(80, 20, 80, 60), 'SPLine vertical');
  MustTrue(Capture(F), 'capture vertical line');
  CheckPixel(F, 80, 20, kRedR, kRedG, kRedB, kTol, 'vertical start');
  CheckPixel(F, 80, 40, kRedR, kRedG, kRedB, kTol, 'vertical middle');
  CheckPixel(F, 80, 60, kRedR, kRedG, kRedB, kTol, 'vertical end');
  CheckPixel(F, 79, 40, 0, 0, 0, kTol, 'vertical left empty');
  CheckPixel(F, 81, 40, 0, 0, 0, kTol, 'vertical right empty');
  CheckBounds(F, 80, 20, 80, 60, 'vertical line bbox');

  ClearBlack; SetRed;
  MustTrue(FRender.SPLine(10, 80, 50, 120), 'SPLine diagonal');
  MustTrue(Capture(F), 'capture diagonal line');
  CheckPixel(F, 10, 80, kRedR, kRedG, kRedB, kTol, 'diagonal start');
  CheckPixel(F, 50, 120, kRedR, kRedG, kRedB, kTol, 'diagonal end');
  CheckPixel(F, 9, 80, 0, 0, 0, kTol, 'diagonal start left empty');
  CheckPixel(F, 51, 120, 0, 0, 0, kTol, 'diagonal end right empty');
end;

procedure cPrimitivesPixelsTests.TestRectAndFrame;
var
  F: TFrame;
begin
  MustTrue(Assigned(FRender), 'setup: renderer');

  // Filled rect: X + W and Y + H are not included.
  ClearBlack; SetRed;
  MustTrue(FRender.SPRectFilled(10, 10, 20, 20), 'SPRectFilled');
  MustTrue(Capture(F), 'capture filled rect');
  CheckPixel(F, 10, 10, kRedR, kRedG, kRedB, kTol, 'rect top-left');
  CheckPixel(F, 29, 29, kRedR, kRedG, kRedB, kTol, 'rect bottom-right');
  CheckPixel(F, 30, 10, 0, 0, 0, kTol, 'rect excludes X + W');
  CheckPixel(F, 10, 30, 0, 0, 0, kTol, 'rect excludes Y + H');
  CheckPixel(F, 30, 30, 0, 0, 0, kTol, 'rect excludes corner');
  CheckPixel(F, 9, 10, 0, 0, 0, kTol, 'rect excludes left');
  CheckBounds(F, 10, 10, 29, 29, 'filled rect bbox');

  // Rect border.
  ClearBlack; SetRed;
  MustTrue(FRender.SPRectBorder(10, 10, 20, 20), 'SPRectBorder');
  MustTrue(Capture(F), 'capture rect border');
  CheckPixel(F, 10, 10, kRedR, kRedG, kRedB, kTol, 'border top-left');
  CheckPixel(F, 29, 10, kRedR, kRedG, kRedB, kTol, 'border top-right');
  CheckPixel(F, 10, 29, kRedR, kRedG, kRedB, kTol, 'border bottom-left');
  CheckPixel(F, 29, 29, kRedR, kRedG, kRedB, kTol, 'border bottom-right');
  CheckPixel(F, 20, 20, 0, 0, 0, kTol, 'border center empty');
  CheckPixel(F, 30, 10, 0, 0, 0, kTol, 'border excludes X + W');
  CheckPixel(F, 10, 30, 0, 0, 0, kTol, 'border excludes Y + H');
  CheckBounds(F, 10, 10, 29, 29, 'rect border bbox');

  // Negative W/H filled rect.
  ClearBlack; SetRed;
  MustTrue(FRender.SPRectFilled(30, 30, -20, -20),
    'SPRectFilled negative');
  MustTrue(Capture(F), 'capture negative filled rect');
  CheckPixel(F, 10, 10, kRedR, kRedG, kRedB, kTol, 'negative rect top-left');
  CheckPixel(F, 29, 29, kRedR, kRedG, kRedB, kTol,
    'negative rect bottom-right');
  CheckPixel(F, 30, 30, 0, 0, 0, kTol, 'negative rect excludes corner');
  CheckBounds(F, 10, 10, 29, 29, 'negative filled rect bbox');

  // FrameFilled: a 4 px band around a hole.
  ClearBlack; SetRed;
  MustTrue(FRender.SPFrameFilled(20, 20, 40, 30, 4), 'SPFrameFilled');
  MustTrue(Capture(F), 'capture frame filled');
  CheckPixel(F, 20, 20, kRedR, kRedG, kRedB, kTol, 'frame top-left');
  CheckPixel(F, 22, 22, kRedR, kRedG, kRedB, kTol, 'frame top band');
  CheckPixel(F, 40, 22, kRedR, kRedG, kRedB, kTol, 'frame top middle');
  CheckPixel(F, 22, 40, kRedR, kRedG, kRedB, kTol, 'frame left band');
  CheckPixel(F, 58, 22, kRedR, kRedG, kRedB, kTol, 'frame right band');
  CheckPixel(F, 40, 48, kRedR, kRedG, kRedB, kTol, 'frame bottom band');
  CheckPixel(F, 40, 40, 0, 0, 0, kTol, 'frame hole');
  CheckPixel(F, 60, 20, 0, 0, 0, kTol, 'frame outside right');
end;

procedure cPrimitivesPixelsTests.TestCirclePixels;
var
  F: TFrame;
begin
  MustTrue(Assigned(FRender), 'setup: renderer');

  ClearBlack; SetRed;
  MustTrue(FRender.SPCircleBorder(160, 120, 30), 'SPCircleBorder');
  MustTrue(Capture(F), 'capture circle border');
  CheckPixel(F, 130, 120, kRedR, kRedG, kRedB, kTol, 'circle left');
  CheckPixel(F, 190, 120, kRedR, kRedG, kRedB, kTol, 'circle right');
  CheckPixel(F, 160, 90, kRedR, kRedG, kRedB, kTol, 'circle top');
  CheckPixel(F, 160, 150, kRedR, kRedG, kRedB, kTol, 'circle bottom');
  CheckPixel(F, 160, 120, 0, 0, 0, kTol, 'circle center empty');
  CheckAnyPixel(F, 180, 98, 182, 100, kRedR, kRedG, kRedB, kTol,
    'circle diagonal');
  CheckBounds(F, 130, 90, 190, 150, 'circle border bbox');

  ClearBlack; SetRed;
  MustTrue(FRender.SPCircleFilled(160, 120, 30), 'SPCircleFilled');
  MustTrue(Capture(F), 'capture circle filled');
  CheckPixel(F, 160, 120, kRedR, kRedG, kRedB, kTol, 'circle filled center');
  CheckPixel(F, 130, 120, kRedR, kRedG, kRedB, kTol, 'circle filled left');
  CheckPixel(F, 190, 120, kRedR, kRedG, kRedB, kTol, 'circle filled right');
  CheckPixel(F, 160, 90, kRedR, kRedG, kRedB, kTol, 'circle filled top');
  CheckPixel(F, 160, 150, kRedR, kRedG, kRedB, kTol, 'circle filled bottom');
  CheckPixel(F, 160, 100, kRedR, kRedG, kRedB, kTol,
    'circle filled inside top');
  CheckPixel(F, 160, 89, 0, 0, 0, kTol, 'circle filled outside top');
  CheckPixel(F, 129, 120, 0, 0, 0, kTol, 'circle filled outside left');
  CheckBounds(F, 130, 90, 190, 150, 'circle filled bbox');

  ClearBlack; SetRed;
  MustTrue(FRender.SPCircleBorder(160, 120, 30), 'circle fill-only border');
  SetBlue;
  MustTrue(FRender.SPCircleFillOnly(160, 120, 30), 'SPCircleFillOnly');
  MustTrue(Capture(F), 'capture circle fill-only');
  CheckPixel(F, 160, 120, kBlueR, kBlueG, kBlueB, kTol,
    'circle fill-only center');
  CheckPixel(F, 130, 120, kRedR, kRedG, kRedB, kTol,
    'circle fill-only left border');
  CheckPixel(F, 190, 120, kRedR, kRedG, kRedB, kTol,
    'circle fill-only right border');
  CheckPixel(F, 160, 90, kRedR, kRedG, kRedB, kTol,
    'circle fill-only top border');
  CheckPixel(F, 160, 150, kRedR, kRedG, kRedB, kTol,
    'circle fill-only bottom border');
  CheckPixel(F, 160, 100, kBlueR, kBlueG, kBlueB, kTol,
    'circle fill-only inside top');
  CheckPixel(F, 131, 120, kBlueR, kBlueG, kBlueB, kTol,
    'circle fill-only inside left');

  // Radius < 1: border/filled draw a point, fill-only draws nothing.
  ClearBlack; SetRed;
  MustTrue(FRender.SPCircleBorder(160, 120, 0.5), 'SPCircleBorder R<1');
  MustTrue(Capture(F), 'capture circle R<1');
  CheckPixel(F, 160, 120, kRedR, kRedG, kRedB, kTol, 'circle R<1 point');
  CheckBounds(F, 160, 120, 160, 120, 'circle R<1 bbox');

  ClearBlack; SetBlue;
  MustTrue(FRender.SPCircleFillOnly(160, 120, 0.5),
    'SPCircleFillOnly R<1');
  MustTrue(Capture(F), 'capture circle fill-only R<1');
  CheckFrameEmpty(F, 'circle fill-only R<1');
end;

procedure cPrimitivesPixelsTests.TestTriangleQuadPolygon;
var
  F: TFrame;
  PArr: TSDLFPointDynArray;
begin
  MustTrue(Assigned(FRender), 'setup: renderer');

  // Triangle border.
  ClearBlack; SetRed;
  MustTrue(FRender.SPTriangleBorder(60, 20, 100, 20, 80, 60),
    'SPTriangleBorder');
  MustTrue(Capture(F), 'capture triangle border');
  CheckPixel(F, 60, 20, kRedR, kRedG, kRedB, kTol, 'triangle v1');
  CheckPixel(F, 100, 20, kRedR, kRedG, kRedB, kTol, 'triangle v2');
  CheckPixel(F, 80, 60, kRedR, kRedG, kRedB, kTol, 'triangle v3');
  CheckPixel(F, 80, 20, kRedR, kRedG, kRedB, kTol, 'triangle top middle');
  CheckPixel(F, 70, 40, kRedR, kRedG, kRedB, kTol, 'triangle left middle');
  CheckPixel(F, 90, 40, kRedR, kRedG, kRedB, kTol, 'triangle right middle');
  CheckPixel(F, 80, 33, 0, 0, 0, kTol, 'triangle center empty');
  CheckBounds(F, 60, 20, 100, 60, 'triangle border bbox');

  // Triangle filled.
  ClearBlack; SetRed;
  MustTrue(FRender.SPTriangleFilled(60, 20, 100, 20, 80, 60),
    'SPTriangleFilled');
  MustTrue(Capture(F), 'capture triangle filled');
  CheckPixel(F, 80, 33, kRedR, kRedG, kRedB, kTol, 'triangle center');
  CheckPixel(F, 80, 25, kRedR, kRedG, kRedB, kTol, 'triangle inside top');
  CheckPixel(F, 80, 50, kRedR, kRedG, kRedB, kTol, 'triangle inside bottom');
  CheckPixel(F, 59, 20, 0, 0, 0, kTol, 'triangle outside left');
  CheckPixel(F, 101, 20, 0, 0, 0, kTol, 'triangle outside right');
  CheckPixel(F, 80, 61, 0, 0, 0, kTol, 'triangle outside bottom');
  CheckBoundsTol(F, 60, 20, 100, 60, 1, 'triangle filled bbox');

  // Quad border.
  ClearBlack; SetRed;
  MustTrue(FRender.SPQuadBorder(60, 60, 100, 60, 100, 100, 60, 100),
    'SPQuadBorder');
  MustTrue(Capture(F), 'capture quad border');
  CheckPixel(F, 60, 60, kRedR, kRedG, kRedB, kTol, 'quad corner 1');
  CheckPixel(F, 100, 60, kRedR, kRedG, kRedB, kTol, 'quad corner 2');
  CheckPixel(F, 100, 100, kRedR, kRedG, kRedB, kTol, 'quad corner 3');
  CheckPixel(F, 60, 100, kRedR, kRedG, kRedB, kTol, 'quad corner 4');
  CheckPixel(F, 80, 60, kRedR, kRedG, kRedB, kTol, 'quad top middle');
  CheckPixel(F, 80, 100, kRedR, kRedG, kRedB, kTol, 'quad bottom middle');
  CheckPixel(F, 60, 80, kRedR, kRedG, kRedB, kTol, 'quad left middle');
  CheckPixel(F, 100, 80, kRedR, kRedG, kRedB, kTol, 'quad right middle');
  CheckPixel(F, 80, 80, 0, 0, 0, kTol, 'quad center empty');
  CheckBounds(F, 60, 60, 100, 100, 'quad border bbox');

  // Quad filled.
  ClearBlack; SetRed;
  MustTrue(FRender.SPQuadFilled(60, 60, 100, 60, 100, 100, 60, 100),
    'SPQuadFilled');
  MustTrue(Capture(F), 'capture quad filled');
  CheckPixel(F, 80, 80, kRedR, kRedG, kRedB, kTol, 'quad center');
  CheckPixel(F, 70, 70, kRedR, kRedG, kRedB, kTol, 'quad inside');
  CheckPixel(F, 59, 60, 0, 0, 0, kTol, 'quad outside left');
  CheckPixel(F, 101, 60, 0, 0, 0, kTol, 'quad outside right');
  CheckPixel(F, 80, 59, 0, 0, 0, kTol, 'quad outside top');
  CheckPixel(F, 80, 101, 0, 0, 0, kTol, 'quad outside bottom');
  CheckBoundsTol(F, 60, 60, 100, 100, 1, 'quad filled bbox');

  // Polygon border/filled/fill-only.
  SetLength(PArr, 4);
  PArr[0].Init(10, 10);
  PArr[1].Init(50, 10);
  PArr[2].Init(50, 50);
  PArr[3].Init(10, 50);

  ClearBlack; SetRed;
  MustTrue(FRender.SPPolygonBorder(PArr), 'SPPolygonBorder');
  MustTrue(Capture(F), 'capture polygon border');
  CheckPixel(F, 10, 10, kRedR, kRedG, kRedB, kTol, 'polygon corner 1');
  CheckPixel(F, 50, 10, kRedR, kRedG, kRedB, kTol, 'polygon corner 2');
  CheckPixel(F, 50, 50, kRedR, kRedG, kRedB, kTol, 'polygon corner 3');
  CheckPixel(F, 10, 50, kRedR, kRedG, kRedB, kTol, 'polygon corner 4');
  CheckPixel(F, 30, 10, kRedR, kRedG, kRedB, kTol, 'polygon top middle');
  CheckPixel(F, 30, 50, kRedR, kRedG, kRedB, kTol, 'polygon bottom middle');
  CheckPixel(F, 30, 30, 0, 0, 0, kTol, 'polygon center empty');
  CheckBounds(F, 10, 10, 50, 50, 'polygon border bbox');

  ClearBlack; SetRed;
  MustTrue(FRender.SPPolygonFilled(PArr), 'SPPolygonFilled');
  MustTrue(Capture(F), 'capture polygon filled');
  CheckPixel(F, 30, 30, kRedR, kRedG, kRedB, kTol, 'polygon center');
  CheckPixel(F, 20, 20, kRedR, kRedG, kRedB, kTol, 'polygon inside');
  CheckPixel(F, 9, 10, 0, 0, 0, kTol, 'polygon outside left');
  CheckPixel(F, 51, 10, 0, 0, 0, kTol, 'polygon outside right');
  CheckPixel(F, 30, 9, 0, 0, 0, kTol, 'polygon outside top');
  CheckPixel(F, 30, 51, 0, 0, 0, kTol, 'polygon outside bottom');
  CheckBoundsTol(F, 10, 10, 50, 50, 1, 'polygon filled bbox');

  ClearBlack; SetRed;
  MustTrue(FRender.SPPolygonBorder(PArr), 'polygon fill-only border');
  SetBlue;
  MustTrue(FRender.SPPolygonFillOnly(PArr), 'SPPolygonFillOnly');
  MustTrue(Capture(F), 'capture polygon fill-only');
  CheckPixel(F, 30, 30, kBlueR, kBlueG, kBlueB, kTol,
    'polygon fill-only center');
  CheckPixel(F, 10, 10, kRedR, kRedG, kRedB, kTol,
    'polygon fill-only corner border');
  CheckPixel(F, 30, 10, kRedR, kRedG, kRedB, kTol,
    'polygon fill-only top border');
  CheckPixel(F, 20, 20, kBlueR, kBlueG, kBlueB, kTol,
    'polygon fill-only inside');
end;

{
  Main program
}

var
  MainTest: cPrimitivesPixelsTests;
  JSONWriter: cCHXTWJSON;

begin
  SDL_SetAppMetadata('TestPrimitivesPixels', '1.0',
    'com.chixpy.TestPrimitivesPixels');
  MainTest := cPrimitivesPixelsTests.Create('CHXSDL3 primitive pixel tests');
  try
    MainTest.AddWriter(cCHXTWConsole);
    AddJSONWriter(MainTest, 'TestPrimitivesPixels', JSONWriter);
    ExitCode := MainTest.RunAllCases;
    CheckJSONSaveError(JSONWriter, ExitCode);
  finally
    MainTest.Free;
  end;
end.
