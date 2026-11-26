unit ucCHXSDL3Label;
{< Unit of cCHXSDL3Label component.

  (C) 2026 Chixpy https://github.com/Chixpy
}
{$mode ObjFPC}{$H+}{$INLINE ON}{$WARN 6058 OFF}

interface

uses
  Classes, SysUtils, CTypes,
  SDL3,
  uCHXSDL3TypeHelpers, ucCHXSDL3Renderer,
  ucaCHXSDL3Component, ucaCHXSDL3Font;

type
  { cCHXSDL3Label }

  cCHXSDL3Label = class(caCHXSDL3Component)
  public
    Font: caCHXSDL3Font;
    Caption: string;
    TextAlign: TCHXSDL3TextAlign;

    constructor Create(const AID: String; const X, Y, W, H: CFloat;
      const AFont: caCHXSDL3Font = nil; const ACaption: string = '');
    destructor Destroy; override;

    procedure Setup; override;
    procedure Finish; override;
    procedure Compute(const FrameTime: CUInt32; var ExitProg: Boolean); override;
    procedure Draw(const Render: cCHXSDL3Renderer); override;
    procedure HandleEvent(const aEvent: TSDL_Event;
      var Handled, ExitProg: Boolean); override;
  end;

implementation

{ cCHXSDL3Label }

constructor cCHXSDL3Label.Create(const AID: String; const X, Y, W, H: CFloat;
  const AFont: caCHXSDL3Font; const ACaption: string);
begin
  inherited Create(AID, X, Y, W, H);
  Font := AFont;
  Caption := ACaption;
  TextAlign := taLeft;
end;

destructor cCHXSDL3Label.Destroy;
begin
  inherited Destroy;
end;

procedure cCHXSDL3Label.Setup;
begin
  // Nothing special
end;

procedure cCHXSDL3Label.Finish;
begin
  // Nothing special
end;

procedure cCHXSDL3Label.Compute(const FrameTime: CUInt32; var ExitProg: Boolean);
begin
  // Nothing to compute
end;

procedure cCHXSDL3Label.Draw(const Render: cCHXSDL3Renderer);
var
  TY: CFloat;
begin
  if (Font = nil) or (Caption = '') then Exit;
  if (Rect.W <= 0) or (Rect.H <= 0) then Exit;

  // Vertical centering for single line
  TY := Rect.Y + (Rect.H - Font.LineHeight) / 2;
  if TY < Rect.Y then TY := Rect.Y;

  Font.RenderDynStrClipped(Rect.X, TY, Caption, Trunc(Rect.W), TextAlign);
end;

procedure cCHXSDL3Label.HandleEvent(const aEvent: TSDL_Event;
  var Handled, ExitProg: Boolean);
begin
  // Label does not handle events
end;

end.