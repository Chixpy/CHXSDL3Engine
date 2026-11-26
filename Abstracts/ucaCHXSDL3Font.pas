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
  uCHXSDL3TypeHelpers;

type
  TCHXSDL3TextAlign = (
    taLeft,
    taCenter,
    taRight
  );

  { caCHXSDL3Font }

  caCHXSDL3Font = class(TPersistent)
  protected
    FRenderer: PSDL_Renderer;
    function GetLineHeight: Integer; virtual; abstract;

  public
    Color: TSDL_FColor;
    property LineHeight: Integer read GetLineHeight;
    property Renderer: PSDL_Renderer read FRenderer;

    {< Measure text width for a single line (UTF-8). }
    function MeasureText(const Text: string): Integer; virtual; abstract;

    {< Render dynamic text at logical coordinates. Returns width used. }
    function RenderDynStr(X, Y: CFloat; const Text: string): Integer;
      virtual; abstract;

    {< Render dynamic text clipped to ClipWidth with alignment. Returns width used. }
    function RenderDynStrClipped(X, Y: CFloat; const Text: string;
      ClipWidth: Integer; Align: TCHXSDL3TextAlign): Integer;
      virtual; abstract;

    constructor Create(const ARenderer: PSDL_Renderer;
      const AColor: TSDL_FColor); virtual;
    destructor Destroy; override;
  end;

implementation

{ caCHXSDL3Font }

constructor caCHXSDL3Font.Create(const ARenderer: PSDL_Renderer;
  const AColor: TSDL_FColor);
begin
  inherited Create;
  FRenderer := ARenderer;
  Color := AColor;
end;

destructor caCHXSDL3Font.Destroy;
begin
  inherited Destroy;
end;

end.
