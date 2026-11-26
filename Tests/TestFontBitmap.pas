program TestFontBitmap;
{<
  Non-interactive pixel tests for cCHXSDL3FontBitmap, using CHXTests.

  The atlas is generated at runtime so the expected pixels are deterministic:

    FirstChar = '=' (61), Columns = 5, glyphs 8x8
      '=' solid green          (unused)
      '>' solid blue           (unused)
      '?' left red/right black (fallback glyph)
      '@' left red/right magenta (color key)
      'A' left white/right black

  (C) 2026 Chixpy https://github.com/Chixpy
}
{$mode ObjFPC}{$H+}

uses
  SysUtils, Classes, CTypes, SDL3,
  uCHXSDL3TypeHelpers,
  ucaCHXSDL3Font,
  ucCHXSDL3Renderer, ucCHXSDL3FontBitmap,
  ucCHXTestGroup, ucCHXTWConsole, ucCHXTWJSON, uCHXTestJSON;

const
  kGlyphW = 8;
  kGlyphH = 8;
  kColumns = 5;
  kFirstChar = Ord('='); // '=' '>' '?' '@' 'A'
  kAtlasW = kGlyphW * kColumns;
  kAtlasH = kGlyphH;

type
  { cFontBitmapTests }

  cFontBitmapTests = class(cCHXTestGroup)
  private
    FDir: String;
    FAtlasFile: String;
    FWindow: PSDL_Window;
    FRender: cCHXSDL3Renderer;
    procedure CreateAtlas;
    procedure ClearTarget(const R, G, B: Byte);
    function ReadPixel(const X, Y: Integer;
      out R, G, B, A: Byte): Boolean;
    procedure CheckPixel(const X, Y: Integer;
      const ExpR, ExpG, ExpB, Tol: Integer; const Msg: String);
    function NewGray: cCHXSDL3FontBitmap;
    function NewColor(const AKey: Boolean): cCHXSDL3FontBitmapColor;
  protected
    procedure DoBeforeStart; override;
    procedure DoAfterEnd; override;
  published
    procedure TestMeasureText;
    procedure TestGrayTint;
    procedure TestGrayAlpha;
    procedure TestRestoresTextureState;
    procedure TestColorKey;
    procedure TestFallback;
    procedure TestClip;
    procedure TestInvalidInputs;
  end;

procedure RemoveDirRecursive(const ADir: String);
var
  SearchRec: TSearchRec;
  Path: String;
begin
  if not DirectoryExists(ADir) then Exit;
  if FindFirst(IncludeTrailingPathDelimiter(ADir) + '*', faAnyFile, SearchRec) = 0 then
  begin
    repeat
      if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
      begin
        Path := IncludeTrailingPathDelimiter(ADir) + SearchRec.Name;
        if (SearchRec.Attr and faDirectory) <> 0 then
          RemoveDirRecursive(Path)
        else
          DeleteFile(Path);
      end;
    until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
  end;
  RemoveDir(ADir);
end;

{ cFontBitmapTests }

procedure cFontBitmapTests.DoBeforeStart;
var
  Raw: PSDL_Renderer;
begin
  inherited DoBeforeStart;

  FDir := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
    'testfont_tmp';
  FDir := IncludeTrailingPathDelimiter(FDir);
  RemoveDirRecursive(FDir);
  ForceDirectories(FDir);
  FAtlasFile := FDir + 'atlas.bmp';

  SDL_Init(SDL_INIT_VIDEO);
  FWindow := SDL_CreateWindow('TestFontBitmap', 64, 16, 0);
  if FWindow = nil then
  begin
    SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
      'TestFontBitmap: cannot create window: %s', [SDL_GetError]);
    Exit;
  end;
  Raw := SDL_CreateRenderer(FWindow, PAnsiChar('software'));
  if Raw = nil then
  begin
    SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
      'TestFontBitmap: cannot create renderer: %s', [SDL_GetError]);
    Exit;
  end;
  FRender := cCHXSDL3Renderer.Create(Raw, True);
  CreateAtlas;
end;

procedure cFontBitmapTests.DoAfterEnd;
begin
  FreeAndNil(FRender);
  if FWindow <> nil then
  begin
    SDL_DestroyWindow(FWindow);
    FWindow := nil;
  end;
  SDL_Quit;
  RemoveDirRecursive(FDir);
  inherited DoAfterEnd;
end;

procedure cFontBitmapTests.CreateAtlas;
var
  Surf: PSDL_Surface;
  x, y: Integer;

  procedure Put(const Glyph, X, Y: Integer; const R, G, B: Byte);
  begin
    SDL_WriteSurfacePixel(Surf, Glyph * kGlyphW + X, Y, R, G, B, 255);
  end;

begin
  Surf := SDL_CreateSurface(kAtlasW, kAtlasH, SDL_PIXELFORMAT_RGBA32);
  if Surf = nil then Exit;
  try
    for y := 0 to kGlyphH - 1 do
      for x := 0 to kGlyphW - 1 do
      begin
        // '=': solid green (unused, keeps the atlas non-uniform)
        Put(0, x, y, 0, 255, 0);
        // '>': solid blue (unused)
        Put(1, x, y, 0, 0, 255);
        // '?': left red, right black
        if x < kGlyphW div 2 then
          Put(2, x, y, 255, 0, 0)
        else
          Put(2, x, y, 0, 0, 0);
        // '@': left red, right magenta
        if x < kGlyphW div 2 then
          Put(3, x, y, 255, 0, 0)
        else
          Put(3, x, y, 255, 0, 255);
        // 'A': left white, right black
        if x < kGlyphW div 2 then
          Put(4, x, y, 255, 255, 255)
        else
          Put(4, x, y, 0, 0, 0);
      end;
    if not SDL_SaveBMP(Surf, PAnsiChar(AnsiString(FAtlasFile))) then
      SDL_LogError(SDL_LOG_CATEGORY_APPLICATION,
        'TestFontBitmap: cannot save atlas: %s', [SDL_GetError]);
  finally
    SDL_DestroySurface(Surf);
  end;
end;

procedure cFontBitmapTests.ClearTarget(const R, G, B: Byte);
begin
  FRender.Clear(R / 255, G / 255, B / 255, 1);
end;

function cFontBitmapTests.ReadPixel(const X, Y: Integer;
  out R, G, B, A: Byte): Boolean;
var
  Surf: PSDL_Surface;
begin
  R := 0;
  G := 0;
  B := 0;
  A := 0;
  Result := False;
  if FRender = nil then Exit;

  Surf := SDL_RenderReadPixels(FRender.SDLRenderer, nil);
  if Surf = nil then Exit;
  try
    Result := SDL_ReadSurfacePixel(Surf, X, Y, @R, @G, @B, @A);
  finally
    SDL_DestroySurface(Surf);
  end;
end;

procedure cFontBitmapTests.CheckPixel(const X, Y: Integer;
  const ExpR, ExpG, ExpB, Tol: Integer; const Msg: String);
var
  R, G, B, A: Byte;
begin
  MustTrue(ReadPixel(X, Y, R, G, B, A), Msg + ': read pixel');
  MustTrue((Abs(R - ExpR) <= Tol) and (Abs(G - ExpG) <= Tol)
    and (Abs(B - ExpB) <= Tol),
    Format('%s: got (%d,%d,%d), expected (%d,%d,%d) +-%d',
    [Msg, R, G, B, ExpR, ExpG, ExpB, Tol]));
end;

function cFontBitmapTests.NewGray: cCHXSDL3FontBitmap;
begin
  Result := cCHXSDL3FontBitmap.Create(FRender, SDLFColor(1, 1, 1, 1),
    FAtlasFile, kGlyphW, kGlyphH, kColumns, kFirstChar);
end;

function cFontBitmapTests.NewColor(const AKey: Boolean): cCHXSDL3FontBitmapColor;
var
  Key: TSDL_Color;
  KeyPtr: PSDL_Color;
begin
  KeyPtr := nil;
  if AKey then
  begin
    Key.r := 255;
    Key.g := 0;
    Key.b := 255;
    Key.a := 255;
    KeyPtr := @Key;
  end;
  Result := cCHXSDL3FontBitmapColor.Create(FRender, SDLFColor(1, 1, 1, 1),
    FAtlasFile, kGlyphW, kGlyphH, kColumns, kFirstChar, KeyPtr);
end;

procedure cFontBitmapTests.TestMeasureText;
var
  F: cCHXSDL3FontBitmap;
begin
  MustTrue(Assigned(FRender), 'setup: renderer');
  F := NewGray;
  try
    MustTrue(F.MeasureText('') = 0, 'empty text');
    MustTrue(F.MeasureText('A') = kGlyphW, 'one ASCII char');
    MustTrue(F.MeasureText('AA') = 2 * kGlyphW, 'two ASCII chars');
    MustTrue(F.MeasureText('A' + #$C3#$A9) = 2 * kGlyphW,
      'UTF-8 multibyte counts as one char');
  finally
    F.Free;
  end;
end;

procedure cFontBitmapTests.TestGrayTint;
var
  F: cCHXSDL3FontBitmap;
begin
  MustTrue(Assigned(FRender), 'setup: renderer');
  F := NewGray;
  try
    MustTrue(F.Texture <> nil, 'gray: texture created');
    ClearTarget(0, 0, 255);
    F.Color := SDLFColor(1, 0, 0, 1);
    MustTrue(F.RenderDynStr(0, 0, 'A') = kGlyphW, 'gray: render width');
    CheckPixel(0, 0, 255, 0, 0, 8, 'gray: tinted white half');
    CheckPixel(kGlyphW - 1, 0, 0, 0, 255, 8,
      'gray: black half is transparent');
  finally
    F.Free;
  end;
end;

procedure cFontBitmapTests.TestGrayAlpha;
var
  F: cCHXSDL3FontBitmap;
begin
  MustTrue(Assigned(FRender), 'setup: renderer');
  F := NewGray;
  try
    ClearTarget(0, 0, 0);
    F.Color := SDLFColor(1, 0, 0, 0.5);
    F.RenderDynStr(0, 0, 'A');
    CheckPixel(0, 0, 128, 0, 0, 10, 'gray: alpha mod blends at 50%');
  finally
    F.Free;
  end;
end;

procedure cFontBitmapTests.TestRestoresTextureState;
var
  F: cCHXSDL3FontBitmap;
  R, G, B, A: Byte;
  Blend: TSDL_BlendMode;
begin
  MustTrue(Assigned(FRender), 'setup: renderer');
  F := NewGray;
  try
    MustTrue(SDL_SetTextureColorMod(F.Texture, 10, 20, 30),
      'state: set color mod');
    MustTrue(SDL_SetTextureAlphaMod(F.Texture, 40), 'state: set alpha mod');
    MustTrue(SDL_SetTextureBlendMode(F.Texture, SDL_BLENDMODE_NONE),
      'state: set blend none');

    ClearTarget(0, 0, 0);
    F.RenderDynStr(0, 0, 'A');

    MustTrue(SDL_GetTextureColorMod(F.Texture, @R, @G, @B)
      and (R = 10) and (G = 20) and (B = 30),
      Format('state: color mod restored, got (%d,%d,%d)', [R, G, B]));
    MustTrue(SDL_GetTextureAlphaMod(F.Texture, @A) and (A = 40),
      Format('state: alpha mod restored, got %d', [A]));
    MustTrue(SDL_GetTextureBlendMode(F.Texture, @Blend)
      and (Blend = SDL_BLENDMODE_NONE),
      'state: blend mode restored to none');
  finally
    F.Free;
  end;
end;

procedure cFontBitmapTests.TestColorKey;
var
  F: cCHXSDL3FontBitmapColor;
begin
  MustTrue(Assigned(FRender), 'setup: renderer');

  F := NewColor(True);
  try
    MustTrue(F.Texture <> nil, 'color: texture created');
    ClearTarget(0, 0, 255);
    F.RenderDynStr(0, 0, '@');
    CheckPixel(0, 0, 255, 0, 0, 8, 'color: left keeps red');
    CheckPixel(kGlyphW - 1, 0, 0, 0, 255, 8,
      'color: key magenta is transparent');
  finally
    F.Free;
  end;

  F := NewColor(False);
  try
    ClearTarget(0, 0, 255);
    F.RenderDynStr(0, 0, '@');
    CheckPixel(kGlyphW - 1, 0, 255, 0, 255, 8,
      'color: without key magenta is drawn');
  finally
    F.Free;
  end;
end;

procedure cFontBitmapTests.TestFallback;
var
  F: cCHXSDL3FontBitmapColor;
begin
  MustTrue(Assigned(FRender), 'setup: renderer');
  F := NewColor(False);
  try
    ClearTarget(0, 0, 255);
    // 'Z' is outside the atlas: must draw '?' (left red), not 'A' (white).
    MustTrue(F.RenderDynStr(0, 0, 'Z') = kGlyphW, 'fallback: width');
    CheckPixel(0, 0, 255, 0, 0, 8, 'fallback: out-of-range draws ?');

    ClearTarget(0, 0, 255);
    // UTF-8 multibyte lead byte: also the fallback glyph.
    F.RenderDynStr(0, 0, #$C3#$A9);
    CheckPixel(0, 0, 255, 0, 0, 8, 'fallback: non-ASCII draws ?');
  finally
    F.Free;
  end;
end;

procedure cFontBitmapTests.TestClip;
var
  F: cCHXSDL3FontBitmap;
begin
  MustTrue(Assigned(FRender), 'setup: renderer');
  F := NewGray;
  try
    ClearTarget(0, 0, 255);
    MustTrue(F.RenderDynStrClipped(0, 0, 'AA', kGlyphW, taLeft)
      = 2 * kGlyphW, 'clip: returns full width');
    CheckPixel(0, 0, 255, 255, 255, 8, 'clip: first glyph visible');
    CheckPixel(kGlyphW + 1, 0, 0, 0, 255, 8,
      'clip: second glyph not drawn');

    // Current behaviour: right/center alignment is clamped to X when the
    // text is wider than the clip width (see ToDo.md).
    ClearTarget(0, 0, 255);
    F.RenderDynStrClipped(0, 0, 'AA', kGlyphW, taRight);
    CheckPixel(0, 0, 255, 255, 255, 8, 'clip: right align clamps to X');

    MustTrue(F.RenderDynStrClipped(0, 0, 'A', 0, taLeft) = 0,
      'clip: zero width draws nothing');
  finally
    F.Free;
  end;
end;

procedure cFontBitmapTests.TestInvalidInputs;
var
  F: cCHXSDL3FontBitmap;
  Zero, One: CFloat;
begin
  MustTrue(Assigned(FRender), 'setup: renderer');

  F := cCHXSDL3FontBitmap.Create(FRender, SDLFColor(1, 1, 1, 1),
    FDir + 'missing.bmp', kGlyphW, kGlyphH, kColumns, kFirstChar);
  try
    MustTrue(F.Texture = nil, 'invalid: missing BMP has no texture');
    MustTrue(F.RenderDynStr(0, 0, 'A') = 0, 'invalid: missing BMP draws 0');
  finally
    F.Free;
  end;

  F := cCHXSDL3FontBitmap.Create(nil, SDLFColor(1, 1, 1, 1),
    FAtlasFile, kGlyphW, kGlyphH, kColumns, kFirstChar);
  try
    MustTrue(F.Texture = nil, 'invalid: nil renderer has no texture');
    MustTrue(F.RenderDynStr(0, 0, 'A') = 0, 'invalid: nil renderer draws 0');
  finally
    F.Free;
  end;

  F := cCHXSDL3FontBitmap.Create(FRender, SDLFColor(1, 1, 1, 1),
    FAtlasFile, 0, kGlyphH, kColumns, kFirstChar);
  try
    MustTrue(F.Texture = nil, 'invalid: zero glyph width has no texture');
  finally
    F.Free;
  end;

  F := NewGray;
  try
    Zero := 0;
    One := 1;
    MustTrue(F.RenderDynStr(Zero / Zero, 0, 'A') = 0,
      'invalid: NaN X draws 0');
    MustTrue(F.RenderDynStr(One / Zero, 0, 'A') = 0,
      'invalid: infinite X draws 0');
  finally
    F.Free;
  end;
end;

var
  MainTest: cFontBitmapTests;
  JSONWriter: cCHXTWJSON;

begin
  MainTest := cFontBitmapTests.Create('CHXSDL3 bitmap font tests');
  try
    MainTest.AddWriter(cCHXTWConsole);
    AddJSONWriter(MainTest, 'TestFontBitmap', JSONWriter);
    ExitCode := MainTest.RunAllCases;
    CheckJSONSaveError(JSONWriter, ExitCode);
  finally
    MainTest.Free;
  end;
end.
