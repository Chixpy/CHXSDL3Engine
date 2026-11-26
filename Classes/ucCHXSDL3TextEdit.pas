unit ucCHXSDL3TextEdit;
{< Unit of cCHXSDL3TextEdit component (basic, single line).

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
  { cCHXSDL3TextEdit }

  cCHXSDL3TextEdit = class(caCHXSDL3Component)
  private
    FText: string;
    FCursorPos: Integer; // character (codepoint) index, 0..LengthInChars
    FScrollOffsetChars: Integer;

    procedure SetText(const AValue: string);
    procedure EnsureCursorInRange;
    procedure EnsureCursorVisible;

  public
    Font: caCHXSDL3Font;
    Window: PSDL_Window;

    property Text: string read FText write SetText;
    property CursorPos: Integer read FCursorPos write FCursorPos;

    constructor Create(const AID: String; const X, Y, W, H: CFloat;
      const AFont: caCHXSDL3Font = nil; const AWindow: PSDL_Window = nil);
    destructor Destroy; override;

    procedure SetFocus; override;
    procedure UnsetFocus; override;

    procedure Setup; override;
    procedure Finish; override;
    procedure Compute(const FrameTime: CUInt32; var ExitProg: Boolean); override;
    procedure Draw(const Render: cCHXSDL3Renderer); override;
    procedure HandleEvent(const aEvent: TSDL_Event;
      var Handled, ExitProg: Boolean); override;

    // UTF-8 helpers
    class function UTF8CharCount(const S: string): Integer;
    class function UTF8ByteIndexOfChar(const S: string; CharIdx: Integer): Integer;
    class procedure UTF8DeleteCharAt(var S: string; CharIdx: Integer);
    class procedure UTF8InsertAt(var S: string; CharIdx: Integer; const InsertStr: string);
  end;

implementation

{ cCHXSDL3TextEdit }

class function cCHXSDL3TextEdit.UTF8CharCount(const S: string): Integer;
var
  i: Integer;
begin
  Result := 0;
  i := 1;
  while i <= Length(S) do
  begin
    Inc(Result);
    Inc(i);
    while (i <= Length(S)) and ((Ord(S[i]) and $C0) = $80) do
      Inc(i);
  end;
end;

class function cCHXSDL3TextEdit.UTF8ByteIndexOfChar(const S: string; CharIdx: Integer): Integer;
var
  i, Count: Integer;
begin
  if CharIdx <= 0 then
  begin
    Result := 1;
    Exit;
  end;
  i := 1;
  Count := 0;
  while (i <= Length(S)) and (Count < CharIdx) do
  begin
    Inc(Count);
    Inc(i);
    while (i <= Length(S)) and ((Ord(S[i]) and $C0) = $80) do
      Inc(i);
  end;
  Result := i;
end;

class procedure cCHXSDL3TextEdit.UTF8DeleteCharAt(var S: string; CharIdx: Integer);
var
  StartByte, EndByte: Integer;
begin
  if (CharIdx < 0) or (CharIdx >= UTF8CharCount(S)) then Exit;
  StartByte := UTF8ByteIndexOfChar(S, CharIdx);
  EndByte := UTF8ByteIndexOfChar(S, CharIdx + 1);
  Delete(S, StartByte, EndByte - StartByte);
end;

class procedure cCHXSDL3TextEdit.UTF8InsertAt(var S: string; CharIdx: Integer; const InsertStr: string);
var
  ByteIdx: Integer;
begin
  if CharIdx < 0 then CharIdx := 0;
  if CharIdx > UTF8CharCount(S) then CharIdx := UTF8CharCount(S);
  ByteIdx := UTF8ByteIndexOfChar(S, CharIdx);
  Insert(InsertStr, S, ByteIdx);
end;

procedure cCHXSDL3TextEdit.SetText(const AValue: string);
begin
  FText := AValue;
  EnsureCursorInRange;
  EnsureCursorVisible;
end;

procedure cCHXSDL3TextEdit.EnsureCursorInRange;
var
  MaxChars: Integer;
begin
  MaxChars := UTF8CharCount(FText);
  if FCursorPos < 0 then FCursorPos := 0;
  if FCursorPos > MaxChars then FCursorPos := MaxChars;
  if FScrollOffsetChars < 0 then FScrollOffsetChars := 0;
  if FScrollOffsetChars > MaxChars then FScrollOffsetChars := MaxChars;
end;

procedure cCHXSDL3TextEdit.EnsureCursorVisible;
var
  AvailW, W: Integer;
  ByteStart, ByteEnd: Integer;
begin
  if Font = nil then Exit;
  AvailW := Trunc(Rect.W) - 4;
  if AvailW < 1 then AvailW := 1;
  if FCursorPos < FScrollOffsetChars then
    FScrollOffsetChars := FCursorPos;
  ByteStart := UTF8ByteIndexOfChar(FText, FScrollOffsetChars);
  ByteEnd := UTF8ByteIndexOfChar(FText, FCursorPos);
  W := Font.MeasureText(Copy(FText, ByteStart, ByteEnd - ByteStart));
  while (W > AvailW) and (FScrollOffsetChars < FCursorPos) do
  begin
    Inc(FScrollOffsetChars);
    ByteStart := UTF8ByteIndexOfChar(FText, FScrollOffsetChars);
    W := Font.MeasureText(Copy(FText, ByteStart, ByteEnd - ByteStart));
  end;
end;

constructor cCHXSDL3TextEdit.Create(const AID: String; const X, Y, W, H: CFloat;
  const AFont: caCHXSDL3Font; const AWindow: PSDL_Window);
begin
  inherited Create(AID, X, Y, W, H);
  Font := AFont;
  Window := AWindow;
  FText := '';
  FCursorPos := 0;
  FScrollOffsetChars := 0;
end;

destructor cCHXSDL3TextEdit.Destroy;
begin
  if Focused and Assigned(Window) then
    SDL_StopTextInput(Window);
  inherited Destroy;
end;

procedure cCHXSDL3TextEdit.SetFocus;
begin
  inherited SetFocus;
  if Assigned(Window) then
    SDL_StartTextInput(Window);
end;

procedure cCHXSDL3TextEdit.UnsetFocus;
begin
  if Assigned(Window) then
    SDL_StopTextInput(Window);
  inherited UnsetFocus;
end;

procedure cCHXSDL3TextEdit.Setup;
begin
  // nothing
end;

procedure cCHXSDL3TextEdit.Finish;
begin
  // nothing
end;

procedure cCHXSDL3TextEdit.Compute(const FrameTime: CUInt32; var ExitProg: Boolean);
begin
  // nothing
end;

procedure cCHXSDL3TextEdit.Draw(const Render: cCHXSDL3Renderer);
var
  TY, CursorX: CFloat;
  TextW: Integer;
  ByteStart, ByteEnd: Integer;
begin
  if Assigned(Render) then
  begin
    Render.PushDrawColor(BGColor);
    Render.RectFilled(Rect);
    Render.PopDrawColor;
    if Focused then
      Render.SetDrawColor(HLColor)
    else
      Render.SetDrawColor(BDColor);
    Render.RectBorder(Rect);
  end;

  if (Font = nil) then Exit;

  TY := Rect.Y + (Rect.H - Font.LineHeight) / 2;
  if TY < Rect.Y then TY := Rect.Y;

  ByteStart := UTF8ByteIndexOfChar(FText, FScrollOffsetChars);
  if FText <> '' then
    Font.RenderDynStrClipped(Rect.X + 2, TY, Copy(FText, ByteStart, MaxInt), Trunc(Rect.W) - 4, taLeft);

  if Focused then
  begin
    ByteStart := UTF8ByteIndexOfChar(FText, FScrollOffsetChars);
    ByteEnd := UTF8ByteIndexOfChar(FText, FCursorPos);
    TextW := Font.MeasureText(Copy(FText, ByteStart, ByteEnd - ByteStart));
    CursorX := Rect.X + 2 + TextW;
    if Assigned(Render) then
    begin
      Render.SetDrawColor(1, 1, 1, 1);
      Render.Line(CursorX, Rect.Y + 2, CursorX, Rect.Y + Rect.H - 2);
    end;
  end;
end;

procedure cCHXSDL3TextEdit.HandleEvent(const aEvent: TSDL_Event;
  var Handled, ExitProg: Boolean);
var
  KeyCode: TSDL_Keycode;
begin
  inherited HandleEvent(aEvent, Handled, ExitProg);
  if Handled or ExitProg then Exit;
  if not Focused then Exit;

  case aEvent.type_ of
    SDL_EVENT_KEY_DOWN:
    begin
      KeyCode := aEvent.key.key;
      case KeyCode of
        SDLK_BACKSPACE:
        begin
          if FCursorPos > 0 then
          begin
            UTF8DeleteCharAt(FText, FCursorPos - 1);
            Dec(FCursorPos);
            EnsureCursorInRange;
            EnsureCursorVisible;
          end;
          Handled := True;
        end;
        SDLK_DELETE:
        begin
          if FCursorPos < UTF8CharCount(FText) then
          begin
            UTF8DeleteCharAt(FText, FCursorPos);
            EnsureCursorInRange;
            EnsureCursorVisible;
          end;
          Handled := True;
        end;
        SDLK_LEFT:
        begin
          if FCursorPos > 0 then Dec(FCursorPos);
          EnsureCursorVisible;
          Handled := True;
        end;
        SDLK_RIGHT:
        begin
          if FCursorPos < UTF8CharCount(FText) then Inc(FCursorPos);
          EnsureCursorVisible;
          Handled := True;
        end;
        SDLK_HOME:
        begin
          FCursorPos := 0;
          EnsureCursorVisible;
          Handled := True;
        end;
        SDLK_END:
        begin
          FCursorPos := UTF8CharCount(FText);
          EnsureCursorVisible;
          Handled := True;
        end;
        SDLK_RETURN, SDLK_KP_ENTER:
        begin
          // Unfocus on Enter (simple behavior)
          UnsetFocus;
          Handled := True;
        end;
        SDLK_ESCAPE:
        begin
          // Don't consume ESC (global exit in engine)
          Handled := False;
        end;
      else
        Handled := False;
      end;
    end;
    SDL_EVENT_TEXT_INPUT:
    begin
      if aEvent.text.text <> nil then
      begin
        UTF8InsertAt(FText, FCursorPos, string(aEvent.text.text));
        Inc(FCursorPos, UTF8CharCount(string(aEvent.text.text)));
        EnsureCursorInRange;
        EnsureCursorVisible;
      end;
      Handled := True;
    end;
    SDL_EVENT_TEXT_EDITING:
    begin
      // For basic version, ignore composition preview
      Handled := True;
    end;
  end;
end;

end.