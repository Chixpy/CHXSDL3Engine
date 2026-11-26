unit ucaCHXSDL3Font;
{< Abstract font interface for CHXSDL3Engine.

  Fonts are the single abstraction used by components and engine code for
  text measurement and dynamic rendering (logical renderer coordinates).

  (C) 2026 Chixpy https://github.com/Chixpy
}
{$mode ObjFPC}{$H+}{$INLINE ON}{$WARN 6058 OFF}

interface

uses
  Classes, SysUtils, CTypes,
  SDL3,
  uCHXSDL3TypeHelpers,
  ucCHXSDL3Renderer;

type
  TCHXSDL3TextAlign = (
    taLeft,
    taCenter,
    taRight
  );

  { caCHXSDL3Font }

  caCHXSDL3Font = class(TPersistent)
  protected
    FRender: cCHXSDL3Renderer;
    function GetLineHeight: Integer; virtual; abstract;
    function GetRenderer: PSDL_Renderer;

  public
    Color: TSDL_FColor;
    property LineHeight: Integer read GetLineHeight;
    property Render: cCHXSDL3Renderer read FRender;
    property Renderer: PSDL_Renderer read GetRenderer;

    {< Measure text width for a single line (UTF-8). }
    function MeasureText(const Text: string): Integer; virtual; abstract;

    {< Render dynamic text at logical coordinates. Returns width used. }
    function RenderDynStr(X, Y: CFloat; const Text: string): Integer;
      virtual; abstract;

    {< Render dynamic text clipped to ClipWidth with alignment. Returns width used. }
    function RenderDynStrClipped(X, Y: CFloat; const Text: string;
      ClipWidth: Integer; Align: TCHXSDL3TextAlign): Integer;
      virtual; abstract;

    constructor Create(const ARenderer: cCHXSDL3Renderer;
      const AColor: TSDL_FColor); virtual;
    destructor Destroy; override;
  end;

implementation

{ caCHXSDL3Font }

function caCHXSDL3Font.GetRenderer: PSDL_Renderer;
begin
  if Assigned(FRender) then
    Result := FRender.SDLRenderer
  else
    Result := nil;
end;

constructor caCHXSDL3Font.Create(const ARenderer: cCHXSDL3Renderer;
  const AColor: TSDL_FColor);
begin
  inherited Create;
  FRender := ARenderer;
  Color := AColor;
end;

destructor caCHXSDL3Font.Destroy;
begin
  inherited Destroy;
end;

end.
