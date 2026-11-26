unit ucCHXSDL3FontBitmap;
{< Unit of cCHXSDL3FontBitmap (minimal grid bitmap font).

  (C) 2026 Chixpy https://github.com/Chixpy
}
{$mode ObjFPC}{$H+}{$INLINE ON}{$WARN 6058 OFF}

interface

uses
  Classes, SysUtils, CTypes,
  SDL3,
  uCHXSDL3TypeHelpers,
  ucaCHXSDL3Font;

type
  { cCHXSDL3FontBitmap }

  cCHXSDL3FontBitmap = class(caCHXSDL3Font)
  private
    FTexture: PSDL_Texture;
    FGlyphW: Integer;
    FGlyphH: Integer;
    FColumns: Integer;
    FFirstChar: Integer;

  protected
    function GetLineHeight: Integer; override;

  public
    property GlyphW: Integer read FGlyphW;
    property GlyphH: Integer read FGlyphH;
    property Columns: Integer read FColumns;
    property FirstChar: Integer read FFirstChar;
    property Texture: PSDL_Texture read FTexture;

    constructor Create(const ARenderer: PSDL_Renderer; const AColor: TSDL_FColor;
      const BMPFile: string; AGlyphW, AGlyphH, AColumns, AFirstChar: Integer);
      reintroduce;
    destructor Destroy; override;

    function MeasureText(const Text: string): Integer; override;
    function RenderDynStr(X, Y: CFloat; const Text: string): Integer; override;
    function RenderDynStrClipped(X, Y: CFloat; const Text: string;
      ClipWidth: Integer; Align: TCHXSDL3TextAlign): Integer; override;
  end;

implementation

{ cCHXSDL3FontBitmap }

function cCHXSDL3FontBitmap.GetLineHeight: Integer;
begin
  Result := FGlyphH;
end;

constructor cCHXSDL3FontBitmap.Create(const ARenderer: PSDL_Renderer;
  const AColor: TSDL_FColor; const BMPFile: string;
  AGlyphW, AGlyphH, AColumns, AFirstChar: Integer);
var
  aSurf: PSDL_Surface;
begin
  inherited Create(ARenderer, AColor);
  FTexture := nil;
  FGlyphW := AGlyphW;
  FGlyphH := AGlyphH;
  FColumns := AColumns;
  FFirstChar := AFirstChar;

  if (ARenderer = nil) or (BMPFile = '') then Exit;

  aSurf := SDL_LoadSurface(PAnsiChar(AnsiString(BMPFile)));
  if aSurf = nil then
  begin
    SDL_LogWarn(SDL_LOG_CATEGORY_APPLICATION,
      'FontBitmap: cannot load "%s": %s', [PAnsiChar(AnsiString(BMPFile)), SDL_GetError]);
    Exit;
  end;
  try
    FTexture := SDL_CreateTextureFromSurface(ARenderer, aSurf);
    if FTexture = nil then
    begin
      SDL_LogWarn(SDL_LOG_CATEGORY_APPLICATION,
        'FontBitmap: cannot create texture: %s', [SDL_GetError]);
      Exit;
    end;
    SDL_SetTextureBlendMode(FTexture, SDL_BLENDMODE_BLEND);
  finally
    SDL_DestroySurface(aSurf);
  end;
end;

destructor cCHXSDL3FontBitmap.Destroy;
begin
  if FTexture <> nil then
  begin
    SDL_DestroyTexture(FTexture);
    FTexture := nil;
  end;
  inherited Destroy;
end;

function cCHXSDL3FontBitmap.MeasureText(const Text: string): Integer;
var
  i, Count: Integer;
begin
  // Count UTF-8 chars roughly like debug font
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

function cCHXSDL3FontBitmap.RenderDynStr(X, Y: CFloat; const Text: string): Integer;
begin
  Result := RenderDynStrClipped(X, Y, Text, High(Integer), taLeft);
end;

function cCHXSDL3FontBitmap.RenderDynStrClipped(X, Y: CFloat;
  const Text: string; ClipWidth: Integer; Align: TCHXSDL3TextAlign): Integer;
var
  i, CharIdx, Col, Row: Integer;
  SrcRect, DstRect: TSDL_FRect;
  TotalW, DrawX: CFloat;
  b: Byte;
begin
  Result := 0;
  if (FTexture = nil) or (FGlyphW <= 0) or (FGlyphH <= 0) then Exit;
  if Text = '' then Exit;

  TotalW := MeasureText(Text);
  case Align of
    taCenter: DrawX := X + (ClipWidth - TotalW) / 2;
    taRight:  DrawX := X + ClipWidth - TotalW;
  else
    DrawX := X;
  end;
  if DrawX < X then DrawX := X;

  i := 1;
  while i <= Length(Text) do
  begin
    b := Ord(Text[i]);
    // Simple: treat each byte as char for ASCII; skip UTF-8 continuation bytes
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
        SDL_RenderTexture(Renderer, FTexture, @SrcRect, @DstRect);
    end;
    Inc(Result, FGlyphW);
    Inc(i);
    // Skip remaining UTF-8 bytes of this char
    while (i <= Length(Text)) and ((Ord(Text[i]) and $C0) = $80) do
      Inc(i);
  end;
  Result := Trunc(TotalW);
end;

end.