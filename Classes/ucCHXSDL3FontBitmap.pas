unit ucCHXSDL3FontBitmap;
{< Unit of cCHXSDL3FontBitmap classes (grid bitmap fonts).

  Atlas format (current): BMP grid, glyphs in row-major order, @code(Columns)
  per row, @code(FirstChar) is the codepoint offset for the first glyph (byte-based
  mapping in the current implementation). Glyph size @code(GlyphW x GlyphH).
  Future: external metadata/mapping for variable widths and full UTF-8.

  Character mapping: ASCII bytes below @code($80) map to
  @code(byte - FirstChar). Non-ASCII bytes (UTF-8 lead bytes) and codepoints
  outside the atlas are drawn with a fallback glyph: @code('?') when it exists
  in the atlas, otherwise the first glyph. This makes missing characters
  visible until real UTF-8/TTF support is added.

  SDL usage: renderer functions (@code(SDL_RenderTexture)) go through
  @code(cCHXSDL3Renderer). Texture functions (color/alpha mod, blend mode,
  size) are called directly to SDL on purpose: they are not
  @code(SDL_Renderer) functions and there is no texture wrapper class yet.

  (C) 2026 Chixpy https://github.com/Chixpy
}
{$mode ObjFPC}{$H+}{$INLINE ON}{$WARN 6058 OFF}

interface

uses
  Classes, SysUtils, CTypes, Math,
  SDL3,
  uCHXSDL3TypeHelpers,
  ucaCHXSDL3Font,
  ucCHXSDL3Renderer;

type
  { caCHXSDL3FontBitmap - base for grid bitmap fonts }

  caCHXSDL3FontBitmap = class(caCHXSDL3Font)
  private
    FTexture: PSDL_Texture;
    FGlyphW: Integer;
    FGlyphH: Integer;
    FColumns: Integer;
    FFirstChar: Integer;
    FAtlasCols: Integer;
    FAtlasRows: Integer;

  protected
    function GetLineHeight: Integer; override;
    function GetTintEnabled: Boolean; virtual;
    procedure FreeTexture;
    procedure UpdateAtlasSize;
    function GetGlyphCount: Integer;
    function GetGlyphIndex(const aChar: Byte): Integer;

  public
    property GlyphW: Integer read FGlyphW;
    property GlyphH: Integer read FGlyphH;
    property Columns: Integer read FColumns;
    property FirstChar: Integer read FFirstChar;
    property AtlasCols: Integer read FAtlasCols;
    property AtlasRows: Integer read FAtlasRows;
    property Texture: PSDL_Texture read FTexture;

    constructor Create(const ARenderer: cCHXSDL3Renderer; const AColor: TSDL_FColor;
      AGlyphW, AGlyphH, AColumns, AFirstChar: Integer); reintroduce; virtual;
    destructor Destroy; override;

    function MeasureText(const Text: string): Integer; override;
    function RenderDynStr(X, Y: CFloat; const Text: string): Integer; override;
    function RenderDynStrClipped(X, Y: CFloat; const Text: string;
      ClipWidth: Integer; Align: TCHXSDL3TextAlign): Integer; override;
  end;

  { cCHXSDL3FontBitmapGray - grayscale mask: white=opaque, black=transparent.
    Font.Color is applied via texture color mod. }

  cCHXSDL3FontBitmapGray = class(caCHXSDL3FontBitmap)
  protected
    function GetTintEnabled: Boolean; override;
  public
    constructor Create(const ARenderer: cCHXSDL3Renderer; const AColor: TSDL_FColor;
      const BMPFile: string; AGlyphW, AGlyphH, AColumns, AFirstChar: Integer);
      reintroduce;
  end;

  { cCHXSDL3FontBitmapColor - multicolor atlas.
    If AColorKey is provided, use it (SDL_SetSurfaceColorKey).
    If not provided, do not force a key (keeps surface alpha if present). }

  cCHXSDL3FontBitmapColor = class(caCHXSDL3FontBitmap)
  public
    constructor Create(const ARenderer: cCHXSDL3Renderer; const AColor: TSDL_FColor;
      const BMPFile: string; AGlyphW, AGlyphH, AColumns, AFirstChar: Integer;
      const AColorKey: PSDL_Color = nil); reintroduce;
  end;

  { Backward-compatible alias: behaves like grayscale/mask by default for existing code. }
  cCHXSDL3FontBitmap = class(cCHXSDL3FontBitmapGray);

implementation

function caCHXSDL3FontBitmap.GetLineHeight: Integer;
begin
  Result := FGlyphH;
end;

function caCHXSDL3FontBitmap.GetTintEnabled: Boolean;
begin
  Result := False;
end;

procedure caCHXSDL3FontBitmap.UpdateAtlasSize;
var
  W, H: CFloat;
  Cols, Rows: Integer;
begin
  FAtlasCols := 0;
  FAtlasRows := 0;
  if (FTexture = nil) or (FGlyphW <= 0) or (FGlyphH <= 0) then Exit;
  if not SDL_GetTextureSize(FTexture, @W, @H) then
  begin
    SDL_LogWarn(SDL_LOG_CATEGORY_APPLICATION,
      'FontBitmap: cannot query atlas size: %s', [SDL_GetError]);
    Exit;
  end;

  Cols := Trunc(W) div FGlyphW;
  Rows := Trunc(H) div FGlyphH;
  FAtlasCols := Cols;
  FAtlasRows := Rows;

  if (FColumns > 0) and (Cols < FColumns) then
    SDL_LogWarn(SDL_LOG_CATEGORY_APPLICATION,
      'FontBitmap: atlas has %d columns but Columns=%d', [Cols, FColumns]);
  if (Trunc(W) mod FGlyphW <> 0) or (Trunc(H) mod FGlyphH <> 0) then
    SDL_LogWarn(SDL_LOG_CATEGORY_APPLICATION,
      'FontBitmap: atlas size %dx%d is not a multiple of glyph size %dx%d',
      [Trunc(W), Trunc(H), FGlyphW, FGlyphH]);
end;

function caCHXSDL3FontBitmap.GetGlyphCount: Integer;
begin
  if (FAtlasCols <= 0) or (FAtlasRows <= 0) then
    Result := High(Integer)
  else
    Result := FAtlasCols * FAtlasRows;
end;

function caCHXSDL3FontBitmap.GetGlyphIndex(const aChar: Byte): Integer;
var
  Count: Integer;
begin
  Count := GetGlyphCount;

  // ASCII bytes map directly; anything else (UTF-8 lead bytes) is missing.
  if aChar < $80 then
    Result := aChar - FFirstChar
  else
    Result := -1;

  // Fallback: '?' if it is in the atlas, otherwise the first glyph.
  if (Result < 0) or (Result >= Count) then
  begin
    Result := Ord('?') - FFirstChar;
    if (Result < 0) or (Result >= Count) then
      Result := 0;
  end;

  if (Result < 0) or (Result >= Count) then
    Result := -1;
end;

procedure caCHXSDL3FontBitmap.FreeTexture;
begin
  if FTexture <> nil then
  begin
    SDL_DestroyTexture(FTexture);
    FTexture := nil;
  end;
end;

constructor caCHXSDL3FontBitmap.Create(const ARenderer: cCHXSDL3Renderer;
  const AColor: TSDL_FColor; AGlyphW, AGlyphH, AColumns, AFirstChar: Integer);
begin
  inherited Create(ARenderer, AColor);
  FTexture := nil;
  FGlyphW := AGlyphW;
  FGlyphH := AGlyphH;
  FColumns := AColumns;
  FFirstChar := AFirstChar;
  if (FGlyphW <= 0) or (FGlyphH <= 0) then
    SDL_LogWarn(SDL_LOG_CATEGORY_APPLICATION,
      'FontBitmap: invalid glyph size %dx%d', [FGlyphW, FGlyphH]);
  if FColumns <= 0 then
    SDL_LogWarn(SDL_LOG_CATEGORY_APPLICATION,
      'FontBitmap: invalid Columns=%d', [FColumns]);
end;

destructor caCHXSDL3FontBitmap.Destroy;
begin
  FreeTexture;
  inherited Destroy;
end;

function caCHXSDL3FontBitmap.MeasureText(const Text: string): Integer;
var
  i, Count: Integer;
begin
  Count := 0;
  i := 1;
  while i <= Length(Text) do
  begin
    Inc(Count);
    Inc(i);
    while (i <= Length(Text)) and ((Ord(Text[i]) and $C0) = $80) do
      Inc(i);
  end;
  Result := Count * FGlyphW;
end;

function caCHXSDL3FontBitmap.RenderDynStr(X, Y: CFloat; const Text: string): Integer;
begin
  Result := RenderDynStrClipped(X, Y, Text, High(Integer), taLeft);
end;

function caCHXSDL3FontBitmap.RenderDynStrClipped(X, Y: CFloat;
  const Text: string; ClipWidth: Integer; Align: TCHXSDL3TextAlign): Integer;
var
  i, CharIdx, Col, Row: Integer;
  SrcRect, DstRect: TSDL_FRect;
  TotalW, DrawX: CFloat;
  b: Byte;
  OldBlend: TSDL_BlendMode;
  BlendChanged, ColorModSaved, AlphaModSaved: Boolean;
  OldR, OldG, OldB, OldA: Byte;
begin
  Result := 0;
  if (FTexture = nil) or (FGlyphW <= 0) or (FGlyphH <= 0) or (FColumns <= 0)
    or (FRender = nil) then Exit;
  if (Text = '') or (ClipWidth <= 0) then Exit;
  if IsNan(X) or IsInfinite(X) or IsNan(Y) or IsInfinite(Y) then Exit;

  TotalW := MeasureText(Text);
  case Align of
    taCenter: DrawX := X + (ClipWidth - TotalW) / 2;
    taRight:  DrawX := X + ClipWidth - TotalW;
  else
    DrawX := X;
  end;
  if DrawX < X then DrawX := X;

  OldBlend := SDL_BLENDMODE_NONE;
  BlendChanged := False;
  if SDL_GetTextureBlendMode(FTexture, @OldBlend) then
  begin
    if OldBlend = SDL_BLENDMODE_NONE then
      BlendChanged := SDL_SetTextureBlendMode(FTexture, SDL_BLENDMODE_BLEND);
  end;

  // Default values in case the queries fail; only restore what was saved.
  OldR := 255;
  OldG := 255;
  OldB := 255;
  OldA := 255;
  ColorModSaved := False;
  AlphaModSaved := False;
  if GetTintEnabled then
  begin
    ColorModSaved := SDL_GetTextureColorMod(FTexture, @OldR, @OldG, @OldB);
    AlphaModSaved := SDL_GetTextureAlphaMod(FTexture, @OldA);
    SDL_SetTextureColorMod(FTexture,
      Round(EnsureRange(Color.R, 0.0, 1.0) * 255),
      Round(EnsureRange(Color.G, 0.0, 1.0) * 255),
      Round(EnsureRange(Color.B, 0.0, 1.0) * 255));
    SDL_SetTextureAlphaMod(FTexture, Round(EnsureRange(Color.A, 0.0, 1.0) * 255));
  end;

  i := 1;
  while i <= Length(Text) do
  begin
    b := Ord(Text[i]);
    if (b and $C0) = $80 then
    begin
      Inc(i);
      Continue;
    end;
    CharIdx := GetGlyphIndex(b);
    if CharIdx >= 0 then
    begin
      Col := CharIdx mod FColumns;
      Row := CharIdx div FColumns;
      SrcRect := SDLFRect(Col * FGlyphW, Row * FGlyphH, FGlyphW, FGlyphH);
      DstRect := SDLFRect(DrawX + Result, Y, FGlyphW, FGlyphH);
      if (DstRect.X + DstRect.W <= X + ClipWidth) then
      begin
        FRender.RenderTexture(FTexture, @SrcRect, @DstRect);
      end;
    end;
    Inc(Result, FGlyphW);
    Inc(i);
    while (i <= Length(Text)) and ((Ord(Text[i]) and $C0) = $80) do
      Inc(i);
  end;
  Result := Trunc(TotalW);

  if GetTintEnabled then
  begin
    if ColorModSaved then
      SDL_SetTextureColorMod(FTexture, OldR, OldG, OldB);
    if AlphaModSaved then
      SDL_SetTextureAlphaMod(FTexture, OldA);
  end;

  if BlendChanged then
    SDL_SetTextureBlendMode(FTexture, OldBlend);
end;

{ cCHXSDL3FontBitmapGray }

function cCHXSDL3FontBitmapGray.GetTintEnabled: Boolean;
begin
  Result := True;
end;

constructor cCHXSDL3FontBitmapGray.Create(const ARenderer: cCHXSDL3Renderer;
  const AColor: TSDL_FColor; const BMPFile: string;
  AGlyphW, AGlyphH, AColumns, AFirstChar: Integer);
var
  aSurf, aMaskSurf: PSDL_Surface;
  x, y: Integer;
  px: PByte;
  pitch: Integer;
  r, g, b, lum: Byte;
begin
  inherited Create(ARenderer, AColor, AGlyphW, AGlyphH, AColumns, AFirstChar);
  if (ARenderer = nil) or (BMPFile = '') then Exit;
  if (FGlyphW <= 0) or (FGlyphH <= 0) or (FColumns <= 0) then Exit;

  aSurf := SDL_LoadSurface(PAnsiChar(AnsiString(BMPFile)));
  if aSurf = nil then
  begin
    SDL_LogWarn(SDL_LOG_CATEGORY_APPLICATION,
      'FontBitmapGray: cannot load "%s": %s', [PAnsiChar(AnsiString(BMPFile)), SDL_GetError]);
    Exit;
  end;
  try
    aMaskSurf := SDL_ConvertSurface(aSurf, SDL_PIXELFORMAT_RGBA32);
    if aMaskSurf = nil then
    begin
      SDL_LogWarn(SDL_LOG_CATEGORY_APPLICATION,
        'FontBitmapGray: cannot convert surface: %s', [SDL_GetError]);
      Exit;
    end;
    try
      if SDL_MustLock(aMaskSurf) then SDL_LockSurface(aMaskSurf);
      try
        pitch := aMaskSurf^.pitch;
        for y := 0 to aMaskSurf^.h - 1 do
        begin
          px := PByte(aMaskSurf^.pixels) + y * pitch;
          for x := 0 to aMaskSurf^.w - 1 do
          begin
            r := px[0];
            g := px[1];
            b := px[2];
            lum := (Ord(r) + Ord(g) + Ord(b)) div 3;
            px[0] := 255;
            px[1] := 255;
            px[2] := 255;
            px[3] := lum;
            Inc(px, 4);
          end;
        end;
      finally
        if SDL_MustLock(aMaskSurf) then SDL_UnlockSurface(aMaskSurf);
      end;
      FTexture := SDL_CreateTextureFromSurface(ARenderer.SDLRenderer, aMaskSurf);
      if FTexture = nil then
      begin
        SDL_LogWarn(SDL_LOG_CATEGORY_APPLICATION,
          'FontBitmapGray: cannot create texture: %s', [SDL_GetError]);
        Exit;
      end;
      SDL_SetTextureBlendMode(FTexture, SDL_BLENDMODE_BLEND);
      UpdateAtlasSize;
    finally
      SDL_DestroySurface(aMaskSurf);
    end;
  finally
    SDL_DestroySurface(aSurf);
  end;
end;

{ cCHXSDL3FontBitmapColor }

constructor cCHXSDL3FontBitmapColor.Create(const ARenderer: cCHXSDL3Renderer;
  const AColor: TSDL_FColor; const BMPFile: string;
  AGlyphW, AGlyphH, AColumns, AFirstChar: Integer; const AColorKey: PSDL_Color);
var
  aSurf: PSDL_Surface;
  keyVal: UInt32;
begin
  inherited Create(ARenderer, AColor, AGlyphW, AGlyphH, AColumns, AFirstChar);
  if (ARenderer = nil) or (BMPFile = '') then Exit;
  if (FGlyphW <= 0) or (FGlyphH <= 0) or (FColumns <= 0) then Exit;

  aSurf := SDL_LoadSurface(PAnsiChar(AnsiString(BMPFile)));
  if aSurf = nil then
  begin
    SDL_LogWarn(SDL_LOG_CATEGORY_APPLICATION,
      'FontBitmapColor: cannot load "%s": %s', [PAnsiChar(AnsiString(BMPFile)), SDL_GetError]);
    Exit;
  end;
  try
    if AColorKey <> nil then
    begin
      // TSDL_Color uses 0..255 components; map them directly.
      keyVal := SDL_MapSurfaceRGB(aSurf,
        AColorKey^.r, AColorKey^.g, AColorKey^.b);
      SDL_SetSurfaceColorKey(aSurf, True, keyVal);
    end;
    FTexture := SDL_CreateTextureFromSurface(ARenderer.SDLRenderer, aSurf);
    if FTexture = nil then
    begin
      SDL_LogWarn(SDL_LOG_CATEGORY_APPLICATION,
        'FontBitmapColor: cannot create texture: %s', [SDL_GetError]);
      Exit;
    end;
    SDL_SetTextureBlendMode(FTexture, SDL_BLENDMODE_BLEND);
    UpdateAtlasSize;
  finally
    SDL_DestroySurface(aSurf);
  end;
end;

end.
