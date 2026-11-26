unit ucCHXSDL3FontBitmap;
{< Unit of cCHXSDL3FontBitmap classes (grid bitmap fonts).

  Atlas format (current): BMP grid, glyphs in row-major order, @code(Columns)
  per row, @code(FirstChar) is the codepoint offset for the first glyph (byte-based
  mapping in the current implementation). Glyph size @code(GlyphW x GlyphH).
  Future: external metadata/mapping for variable widths and full UTF-8.

  (C) 2026 Chixpy https://github.com/Chixpy
}
{$mode ObjFPC}{$H+}{$INLINE ON}{$WARN 6058 OFF}

interface

uses
  Classes, SysUtils, CTypes, Math,
  SDL3,
  uCHXSDL3TypeHelpers,
  ucaCHXSDL3Font;

type
  { caCHXSDL3FontBitmap - base for grid bitmap fonts }

  caCHXSDL3FontBitmap = class(caCHXSDL3Font)
  private
    FTexture: PSDL_Texture;
    FGlyphW: Integer;
    FGlyphH: Integer;
    FColumns: Integer;
    FFirstChar: Integer;

  protected
    function GetLineHeight: Integer; override;
    procedure FreeTexture;

  public
    property GlyphW: Integer read FGlyphW;
    property GlyphH: Integer read FGlyphH;
    property Columns: Integer read FColumns;
    property FirstChar: Integer read FFirstChar;
    property Texture: PSDL_Texture read FTexture;

    constructor Create(const ARenderer: PSDL_Renderer; const AColor: TSDL_FColor;
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
  public
    constructor Create(const ARenderer: PSDL_Renderer; const AColor: TSDL_FColor;
      const BMPFile: string; AGlyphW, AGlyphH, AColumns, AFirstChar: Integer);
      reintroduce;
  end;

  { cCHXSDL3FontBitmapColor - multicolor atlas.
    If AColorKey is provided, use it (SDL_SetSurfaceColorKey).
    If not provided, do not force a key (keeps surface alpha if present). }

  cCHXSDL3FontBitmapColor = class(caCHXSDL3FontBitmap)
  public
    constructor Create(const ARenderer: PSDL_Renderer; const AColor: TSDL_FColor;
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

procedure caCHXSDL3FontBitmap.FreeTexture;
begin
  if FTexture <> nil then
  begin
    SDL_DestroyTexture(FTexture);
    FTexture := nil;
  end;
end;

constructor caCHXSDL3FontBitmap.Create(const ARenderer: PSDL_Renderer;
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
  BlendChanged: Boolean;
  OldR, OldG, OldB, OldA: Byte;
  HasColorMod: Boolean;
begin
  Result := 0;
  if (FTexture = nil) or (FGlyphW <= 0) or (FGlyphH <= 0) or (FRenderer = nil) then Exit;
  if Text = '' then Exit;

  TotalW := MeasureText(Text);
  case Align of
    taCenter: DrawX := X + (ClipWidth - TotalW) / 2;
    taRight:  DrawX := X + ClipWidth - TotalW;
  else
    DrawX := X;
  end;
  if DrawX < X then DrawX := X;

  BlendChanged := False;
  OldBlend := SDL_BLENDMODE_NONE;
  if SDL_GetTextureBlendMode(FTexture, @OldBlend) then
  begin
    if OldBlend = SDL_BLENDMODE_NONE then
    begin
      SDL_SetTextureBlendMode(FTexture, SDL_BLENDMODE_BLEND);
      BlendChanged := True;
    end;
  end;

  HasColorMod := False;
  if Self is cCHXSDL3FontBitmapGray then
  begin
    if SDL_GetTextureColorMod(FTexture, @OldR, @OldG, @OldB) then
      HasColorMod := True;
    SDL_SetTextureColorMod(FTexture,
      Round(EnsureRange(Color.R, 0.0, 1.0) * 255),
      Round(EnsureRange(Color.G, 0.0, 1.0) * 255),
      Round(EnsureRange(Color.B, 0.0, 1.0) * 255));
    SDL_GetTextureAlphaMod(FTexture, @OldA);
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
    CharIdx := b - FFirstChar;
    if (CharIdx >= 0) and (FColumns > 0) then
    begin
      Col := CharIdx mod FColumns;
      Row := CharIdx div FColumns;
      SrcRect := SDLFRect(Col * FGlyphW, Row * FGlyphH, FGlyphW, FGlyphH);
      DstRect := SDLFRect(DrawX + Result, Y, FGlyphW, FGlyphH);
      if (DstRect.X + DstRect.W <= X + ClipWidth) then
      begin
        SDL_RenderTexture(FRenderer, FTexture, @SrcRect, @DstRect);
      end;
    end;
    Inc(Result, FGlyphW);
    Inc(i);
    while (i <= Length(Text)) and ((Ord(Text[i]) and $C0) = $80) do
      Inc(i);
  end;
  Result := Trunc(TotalW);

  if (Self is cCHXSDL3FontBitmapGray) and HasColorMod then
  begin
    SDL_SetTextureColorMod(FTexture, OldR, OldG, OldB);
    SDL_SetTextureAlphaMod(FTexture, OldA);
  end;

  if BlendChanged then
    SDL_SetTextureBlendMode(FTexture, OldBlend);
end;

{ cCHXSDL3FontBitmapGray }

constructor cCHXSDL3FontBitmapGray.Create(const ARenderer: PSDL_Renderer;
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
      FTexture := SDL_CreateTextureFromSurface(ARenderer, aMaskSurf);
      if FTexture = nil then
      begin
        SDL_LogWarn(SDL_LOG_CATEGORY_APPLICATION,
          'FontBitmapGray: cannot create texture: %s', [SDL_GetError]);
        Exit;
      end;
      SDL_SetTextureBlendMode(FTexture, SDL_BLENDMODE_BLEND);
    finally
      SDL_DestroySurface(aMaskSurf);
    end;
  finally
    SDL_DestroySurface(aSurf);
  end;
end;

{ cCHXSDL3FontBitmapColor }

constructor cCHXSDL3FontBitmapColor.Create(const ARenderer: PSDL_Renderer;
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
      keyVal := SDL_MapSurfaceRGB(aSurf,
        Round(EnsureRange(AColorKey^.r, 0.0, 1.0) * 255),
        Round(EnsureRange(AColorKey^.g, 0.0, 1.0) * 255),
        Round(EnsureRange(AColorKey^.b, 0.0, 1.0) * 255));
      SDL_SetSurfaceColorKey(aSurf, True, keyVal);
    end;
    FTexture := SDL_CreateTextureFromSurface(ARenderer, aSurf);
    if FTexture = nil then
    begin
      SDL_LogWarn(SDL_LOG_CATEGORY_APPLICATION,
        'FontBitmapColor: cannot create texture: %s', [SDL_GetError]);
      Exit;
    end;
    SDL_SetTextureBlendMode(FTexture, SDL_BLENDMODE_BLEND);
  finally
    SDL_DestroySurface(aSurf);
  end;
end;

end.
