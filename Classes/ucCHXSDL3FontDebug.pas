unit ucCHXSDL3FontDebug;
{< Debug font wrapper using SDL_RenderDebugText (fixed 8x8 glyphs).

  (C) 2026 Chixpy https://github.com/Chixpy
}
{$mode ObjFPC}{$H+}{$INLINE ON}{$WARN 6058 OFF}

interface

uses
  Classes, SysUtils, CTypes, fgl,
  SDL3,
  uCHXSDL3TypeHelpers,
  ucaCHXSDL3Font;

const
  CHXSDL3DebugFontCharW = 8;
  CHXSDL3DebugFontCharH = 8;

type
  cSDL3FontList = specialize TFPGObjectList<caCHXSDL3Font>;

  { cCHXSDL3FontDebug }

  cCHXSDL3FontDebug = class(caCHXSDL3Font)
  protected
    function GetLineHeight: Integer; override;
    function UTF8CharCount(const S: string): Integer;

  public
    function MeasureText(const Text: string): Integer; override;
    function RenderDynStr(X, Y: CFloat; const Text: string): Integer; override;
    function RenderDynStrClipped(X, Y: CFloat; const Text: string;
      ClipWidth: Integer; Align: TCHXSDL3TextAlign): Integer; override;

    constructor Create(const ARenderer: PSDL_Renderer;
      const AColor: TSDL_FColor); override;
    destructor Destroy; override;
  end;

implementation

{ cCHXSDL3FontDebug }

function cCHXSDL3FontDebug.UTF8CharCount(const S: string): Integer;
var
  i: Integer;
begin
  Result := 0;
  i := 1;
  while i <= Length(S) do
  begin
    Inc(Result);
    // Skip UTF-8 continuation bytes (10xxxxxx)
    Inc(i);
    while (i <= Length(S)) and ((Ord(S[i]) and $C0) = $80) do
      Inc(i);
  end;
end;

function cCHXSDL3FontDebug.GetLineHeight: Integer;
begin
  Result := CHXSDL3DebugFontCharH;
end;

function cCHXSDL3FontDebug.MeasureText(const Text: string): Integer;
begin
  Result := UTF8CharCount(Text) * CHXSDL3DebugFontCharW;
end;

function cCHXSDL3FontDebug.RenderDynStr(X, Y: CFloat; const Text: string): Integer;
begin
  Result := MeasureText(Text);
  if (Renderer = nil) or (Text = '') then Exit;
  // Set draw color from font color before drawing debug text
  SDL_SetRenderDrawColorFloat(Renderer, Color.R, Color.G, Color.B, Color.A);
  SDL_RenderDebugText(Renderer, X, Y, PAnsiChar(Text));
end;

function cCHXSDL3FontDebug.RenderDynStrClipped(X, Y: CFloat;
  const Text: string; ClipWidth: Integer; Align: TCHXSDL3TextAlign): Integer;
var
  MaxChars, Count, UsedW: Integer;
  S: string;
  i: Integer;
begin
  if ClipWidth <= 0 then
  begin
    Result := 0;
    Exit;
  end;
  MaxChars := ClipWidth div CHXSDL3DebugFontCharW;
  if MaxChars <= 0 then
  begin
    Result := 0;
    Exit;
  end;
  // Build clipped string by char count
  Count := 0;
  i := 1;
  while (i <= Length(Text)) and (Count < MaxChars) do
  begin
    Inc(Count);
    Inc(i);
    while (i <= Length(Text)) and ((Ord(Text[i]) and $C0) = $80) do
      Inc(i);
  end;
  S := Copy(Text, 1, i - 1);
  UsedW := Count * CHXSDL3DebugFontCharW;

  case Align of
    taCenter: X := X + (ClipWidth - UsedW) / 2;
    taRight: X := X + (ClipWidth - UsedW);
  else
    // taLeft
  end;

  Result := RenderDynStr(X, Y, S);
end;

constructor cCHXSDL3FontDebug.Create(const ARenderer: PSDL_Renderer;
  const AColor: TSDL_FColor);
begin
  inherited Create(ARenderer, AColor);
end;

destructor cCHXSDL3FontDebug.Destroy;
begin
  inherited Destroy;
end;

end.
