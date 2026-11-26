unit ucCHXSDL3Engine;
{< Unit of `cSDL3Engine` class.

  (C) 2026 Chixpy https://github.com/Chixpy
}
{$mode ObjFPC}{$H+}{$INLINE ON}{$WARN 6058 OFF}

interface

uses
  SysUtils, CTypes, IniFiles,
  SDL3,
  uCHXSDL3TypeHelpers,
  ucCHXSDL3Config, ucCHXSDL3Renderer, ucCHXSDL3Window, ucCHXSDL3FPSManager,
  ucaCHXSDL3Component, ucaCHXSDL3Font, ucCHXSDL3FontDebug;

type
  {
    `cCHXSDL3Engine`: A basic Game Engine in SDL3.

    Descendants only need to implement next methods:

    - `Setup`: Code of inicialization before enter the loop.
    - `Compute`: Code for every frame.
    - `Draw`: Code for draw on screen every frame.
    - `HandleEvent`: Code handling events. Keyboard, Mouse, 
    - `Finish`: Code after exiting the loop.

    New features are implemented as needed.

    - `cCHXSDL3Config` (property `Config`): Lets load and save configurations
      from a file, or change the configuration before initializing and running
      the engine.
    - `cCHXSDL3Window` (property `Window`): Wraps _SDL_video.h_ and handles
      some window events.
    - `cCHXSDL3Renderer` (property `Render`): Wrap _SDL_render.h_ primitives
      and adds many more.
    - `cCHXSDL3FPSManager` (property `FPSMng`): Controls frames rate,
      time lapsed between frames and frame count.

    Of course, SDL3 native functions can be used: `PSDLRenderer` and
    `PSDLWindow` are the pointers to SDL3 native structures.
  }
  cCHXSDL3Engine = class //(TPersistent)
  private // Get properties
    FShowFrameRate: Boolean;
    FWindow: cCHXSDL3Window;
    FRender: cCHXSDL3Renderer;

  protected
    FScreenshotRequested: Boolean;
    SDLRenderer: PSDL_Renderer; //< Window.PSDLRenderer shortcut.
    SDLWindow: PSDL_Window; //< Window.PSDLWindow shortcut.
    FPSMng: cCHXSDL3FPSManager; //< FPS manager
    LastComputeTime : CUInt64;
    LastIdleTime : CInt64;
    CompList: cSDL3ComponentList; //< List of components
    FocusedComp: caCHXSDL3Component; //< Focused component
    DefCompBGColor, DefCompBDColor, DefCompHLColor: TSDL_FColor;
    {<< Default colors for background and border (Inactive and Active) components. }
    FFontList: cSDL3FontList;

    procedure SetShowFrameRate(const aValue: Boolean);
    procedure SetWindow(const aValue: cCHXSDL3Window);
    procedure SetRender(const aValue: cCHXSDL3Renderer);
    procedure DoTakeScreenshot;
    function GetFontDebug: caCHXSDL3Font;

    property FontDebug: caCHXSDL3Font read GetFontDebug;
    property FontList: cSDL3FontList read FFontList;

    function AddComponent(const aComp: caCHXSDL3Component): caCHXSDL3Component;
    {< Add a component to the engine and initialize it.

      This is the only initialization point: `Run` does not call `Setup`
      again. The renderer must be initialized before adding components,
      either after `Init` or from `cCHXSDL3Engine.Setup`, so logical
      presentation can be copied to the component. The engine owns the
      component and frees it on destruction.

      @param(aComp Component to add.)
      @returns(The same component, or @nil if aComp is not assigned.)
    }

    procedure SetDefaultValues;

    // Abstract methods to implement in child classes.
    procedure Setup; virtual; abstract;
    procedure Compute(var ExitProg: Boolean);
      virtual; abstract;
    procedure Draw; virtual; abstract;
    procedure HandleEvent(const aEvent: TSDL_Event;
      var Handled, ExitProg: Boolean); virtual;
    procedure Finish; virtual; abstract;


  public
    Title: String;

    Config: cCHXSDL3Config;

    property Window: cCHXSDL3Window read FWindow write SetWindow;
    property Render: cCHXSDL3Renderer read FRender write SetRender;

    property ShowFrameRate: Boolean
      read FShowFrameRate write SetShowFrameRate;

    constructor Create(const AutoInit: Boolean = False;
      const aTitle: String = '';
      const aWidth : CInt = 0; const aHeight: CInt = 0; const Scale: CInt = 1;
      const FullScreen: Boolean = False; const RenderDrivers: String = '';
      const FPS: CUInt16 = cCHXSDL3DefaultFPS;
      const LogicalPresentation: TSDL_RendererLogicalPresentation
        = SDL_LOGICAL_PRESENTATION_LETTERBOX;
      const aShowFrameRate: Boolean = False;
      const aVSync: Boolean = False); overload;
    {< Constructor with configuration values.

      @param(AutoInit Init engine automatically. If @False, the engine is
         created with the given configuration but not initialized, so
         cCHXSDL3Engine.Config properties can be changed and then
         cCHXSDL3Engine.Init must be called.)
      @param(aTitle Title of the window. It can be changed later.)
      @param(aWidth Width for the renderer.)
      @param(aHeight Height of the renderer.)
      @param(Scale Scale of the window.)
      @param(FullScreen Create a full screen.)
      @param(RenderDrivers Comma separated renderer drivers to try.)
      @param(FPS Frames per second target.)
      @param(LogicalPresentation Logical presentation mode for the renderer.)
      @param(aShowFrameRate Show frame rate information.)
      @param(aVSync Enable vertical synchronization if supported.)

      Command line arguments are applied by Init, after any manual changes
      to cCHXSDL3Engine.Config.
    }
    constructor Create(const aTitle: String; const aIniFile: String); overload;
    {< Constructor reading an .ini file with the settings.

       The engine is initialized automatically. Use the values constructor
       with AutoInit = False if the configuration must be changed after
       loading the file.

       @param(aTitle Title of the window.)
       @param(aIniFile File with engine settings.)
    }
    constructor Create(const aTitle: String;
      const aIniFile: TCustomIniFile); overload;
    {< Constructor reading settings from an already opened .ini file.

       The caller keeps ownership of the TIniFile/TMemIniFile object.

       The engine is initialized automatically. Use the values constructor
       with AutoInit = False if the configuration must be changed after
       loading the file.

       @param(aTitle Title of the window.)
       @param(aIniFile Already opened .ini file with engine settings.)
    }
    procedure Init;
    {< Init the engine and window. }

    procedure Run;
    {< Run the engine. }

    procedure RequestScreenshot;
    {< Request a screenshot to be taken before the next present. }

    procedure TakeScreenshotNow;
    {< Take a screenshot immediately (for tests/tools). }

    destructor Destroy; override;
  end;

implementation

{ cCHXSDL3Engine }

function cCHXSDL3Engine.AddComponent(const aComp: caCHXSDL3Component)
  : caCHXSDL3Component;
begin
  Result := aComp;
  if not assigned(aComp) then Exit;

  aComp.BGColor := DefCompBGColor;
  aComp.BDColor := DefCompBDColor;
  aComp.HLColor := DefCompHLColor;

  SDL_GetRenderLogicalPresentation(SDLRenderer, @aComp.LogPresW,
    @aComp.LogPresH, @aComp.LogPresMode);

  aComp.Setup;
  aComp.UnSetFocus;

  CompList.Add(aComp);
end;

function cCHXSDL3Engine.GetFontDebug: caCHXSDL3Font;
begin
  Result := nil;
  if (FFontList <> nil) and (FFontList.Count > 0) then
    Result := FFontList[0];
end;

procedure cCHXSDL3Engine.SetDefaultValues;
begin
  FShowFrameRate := False;
  FScreenshotRequested := False;

  CompList := cSDL3ComponentList.Create(True);
  DefCompBGColor := SDLFColor(0.5); //< Background color
  DefCompBDColor := SDLFColor(0.25); //< Border color if not focused
  DefCompHLColor := SDLFColor(1, 1, 0); //< Border color if focused

  FFontList := cSDL3FontList.Create(True);
end;

procedure cCHXSDL3Engine.SetShowFrameRate(const aValue: Boolean);
begin
  if FShowFrameRate = aValue then Exit;
  FShowFrameRate := aValue;

  if Assigned(Config) then
    Config.ShowFrameRate := aValue;

  if Assigned(Window) then
    Window.Title := Self.Title;
end;

procedure cCHXSDL3Engine.SetWindow(const aValue: cCHXSDL3Window);
begin
  if FWindow = aValue then Exit;
  FWindow := aValue;

  SDLWindow := Window.PSDLWindow;
  // SDLRenderer := Window.PSDLRenderer;
  Render := Window.Renderer; // Sets SDLRender too.
end;

procedure cCHXSDL3Engine.SetRender(const aValue: cCHXSDL3Renderer);
begin
  if FRender = aValue then Exit;
  FRender := aValue;

  SDLRenderer := Render.SDLRenderer;
end;

procedure cCHXSDL3Engine.DoTakeScreenshot;
var
  aDir, aBase, aTS, aName, aPath: String;
  aSurf: PSDL_Surface;
  i: Integer;
begin
  if not Assigned(Config) then Exit;
  if not Assigned(SDLRenderer) then Exit;

  aDir := Config.ScreenshotDir;
  if aDir = '' then
    aDir := 'scrshots';

  // Create directory if needed
  if not ForceDirectories(aDir) then
  begin
    SDL_LogWarn(SDL_LOG_CATEGORY_APPLICATION,
      'Screenshot: cannot create directory "%s"', [PAnsiChar(aDir)]);
    Exit;
  end;

  aBase := ChangeFileExt(ExtractFileName(ParamStr(0)), '');
  if aBase = '' then
    aBase := 'screenshot';
  aTS := FormatDateTime('yyyymmdd-hhnnss', Now);

  i := 1;
  repeat
    aName := aBase + '-' + aTS + '_' + IntToStr(i) + '.bmp';
    aPath := IncludeTrailingPathDelimiter(aDir) + aName;
    Inc(i);
  until not FileExists(aPath);

  aSurf := SDL_RenderReadPixels(SDLRenderer, nil);
  if aSurf = nil then
  begin
    SDL_LogWarn(SDL_LOG_CATEGORY_APPLICATION,
      'Screenshot: SDL_RenderReadPixels failed: %s', [SDL_GetError]);
    Exit;
  end;
  try
    if not SDL_SaveBMP(aSurf, PAnsiChar(aPath)) then
    begin
      SDL_LogWarn(SDL_LOG_CATEGORY_APPLICATION,
        'Screenshot: SDL_SaveBMP failed for "%s": %s', [PAnsiChar(aPath), SDL_GetError]);
      Exit;
    end;
    SDL_Log('Screenshot saved: %s', [PAnsiChar(aPath)]);
  finally
    SDL_DestroySurface(aSurf);
  end;
end;

(*
procedure cCHXSDL3Engine.PutPixel(const Base: PCUInt32; const Pitch: CInt;
  const X, Y: Word; const r, g, b, a: Byte);
var
  PPoint: PCUInt32;
begin
  PPoint := Base + Y * (Pitch div 4) + X;
  // CHX: Doesn't apply transparency, only sets it.
  //   PPoint is write-only and it doesn't have previous color value.

  // Raw editing is a little faster, less than 5%.

  // TODO: Actually, Window pixel format don't have transparency...
  //   Texture pixel format must be a parameter.
  // TODO2: Test endianess for RGB888 and BGR888 is correct.
  case PWinPxFmt^.format of
    {$IF DEFINED(ENDIAN_LITTLE)}SDL_PIXELFORMAT_RGB888,{$IFEND}
    SDL_PIXELFORMAT_ARGB8888 :
      PPoint^ := (a shl 24) or (r shl 16) or (g shl 8) or b;

    {$IF DEFINED(ENDIAN_LITTLE)}SDL_PIXELFORMAT_BGR888,{$IFEND}
    SDL_PIXELFORMAT_ABGR8888 :
      PPoint^ := (a shl 24) or (b shl 16) or (g shl 8) or r;

    {$IF DEFINED(ENDIAN_BIG)}SDL_PIXELFORMAT_RGB888,{$IFEND}
    SDL_PIXELFORMAT_RGBA8888 :
      PPoint^ := (r shl 24) or (g shl 16) or (b shl 8) or a;

    {$IF DEFINED(ENDIAN_BIG)}SDL_PIXELFORMAT_BGR888,{$IFEND}
    SDL_PIXELFORMAT_BGRA8888 :
      PPoint^ := (b shl 24) or (g shl 16) or (r shl 8) or a;
    else
      // SDL_MapRGBA is the correct way, but we need texture pixel format.
      PPoint^ := SDL_MapRGBA(PWinPxFmt, r, g, b, a);
  end;
end;
*)



procedure cCHXSDL3Engine.RequestScreenshot;
begin
  FScreenshotRequested := True;
end;

procedure cCHXSDL3Engine.TakeScreenshotNow;
begin
  DoTakeScreenshot;
end;

procedure cCHXSDL3Engine.HandleEvent(const aEvent: TSDL_Event; var Handled,
  ExitProg: Boolean);
{
  - Window and general quit events are handled automatically.
  - ESC: Exits the program.
  - F10 / F11 / F12: Decreases / Toggles / Increases framerate.
  - Tab / Shift+Tab: cycle focus between components.
}
var
  i: Integer;
begin
  if Handled or ExitProg then Exit;


  case aEvent.type_ of
    // Handled in by Window in Run method
    // SDL_WINDOWEVENT: // (window: TSDL_WindowEvent)

    SDL_EVENT_KEY_DOWN: // (key: TSDL_KeyboardEvent)
    begin
      case aEvent.key.key of
        SDLK_TAB:
        begin
          if CompList.Count > 0 then
          begin
            // Find current focused index
            i := -1;
            if Assigned(FocusedComp) then
              i := CompList.IndexOf(FocusedComp);
            // Unfocus current
            if (i >= 0) and (i < CompList.Count) then
              CompList[i].Focused := False;
            // Calculate next index
            if (aEvent.key.mod_ and SDL_KMOD_SHIFT) <> 0 then
            begin
              // Shift+Tab: previous
              if i <= 0 then
                i := CompList.Count - 1
              else
                Dec(i);
            end
            else
            begin
              // Tab: next
              if (i < 0) or (i >= CompList.Count - 1) then
                i := 0
              else
                Inc(i);
            end;
            // Focus new
            if (i >= 0) and (i < CompList.Count) then
              CompList[i].Focused := True;
          end;
          Handled := True;
        end;
        SDLK_F10:
        begin
          if FPSMng.FPS > 5 then
             FPSMng.FPS := FPSMng.FPS - 5;
          Handled := True;
        end;
        SDLK_F11:
        begin
          ShowFrameRate := not ShowFrameRate;
          Handled := True;
        end;
        SDLK_F12:
        begin
          FPSMng.FPS := FPSMng.FPS + 5;
          Handled := True;
        end;
        SDLK_PRINTSCREEN :
        begin
          FScreenshotRequested := True;
          Handled := True;
        end;
        SDLK_ESCAPE :
        begin
          ExitProg := True;
          Handled := True;
        end;
      otherwise
        Handled := False;
      end;
    end;
    SDL_EVENT_QUIT: // General exit event
    begin
      ExitProg := True;
      Handled := True;
    end;
    otherwise
      Handled := False;
  end;
end;

constructor cCHXSDL3Engine.Create(const AutoInit : Boolean;
  const aTitle : String; const aWidth, aHeight, Scale : CInt;
  const FullScreen : Boolean; const RenderDrivers : String;
  const FPS : CUInt16;
  const LogicalPresentation : TSDL_RendererLogicalPresentation;
  const aShowFrameRate, aVSync : Boolean);
begin
  inherited Create;

  SetDefaultValues;

  Title := aTitle;

  Config := cCHXSDL3Config.Create;
  Config.Width := aWidth;
  Config.Height := aHeight;
  Config.Scale := Scale;
  Config.FullScreen := FullScreen;
  Config.Render := RenderDrivers;
  Config.FPS := FPS;
  Config.LogicalPresentation := LogicalPresentation;
  Config.ShowFrameRate := aShowFrameRate;
  Config.VSync := aVSync;

  if AutoInit then
    Init;
end;

constructor cCHXSDL3Engine.Create(const aTitle: String;
  const aIniFile: String);
begin
  inherited Create;

  SetDefaultValues;

  Title := aTitle;

  Config := cCHXSDL3Config.Create;
  Config.DefaultFileName := aIniFile;
  Config.LoadFromFile(aIniFile);

  Init;
end;

constructor cCHXSDL3Engine.Create(const aTitle: String;
  const aIniFile: TCustomIniFile);
begin
  inherited Create;

  SetDefaultValues;

  Title := aTitle;

  Config := cCHXSDL3Config.Create;
  if Assigned(aIniFile) then
    Config.LoadFromIni(aIniFile);

  Init;
end;

procedure cCHXSDL3Engine.Init;
var
  aWindow: cCHXSDL3Window;
begin
  // Command line arguments have the highest precedence. Applying them here
  // also covers the AutoInit = False workflow, where Config may have been
  // changed after the constructor returned.
  Config.Sanitize;
  Config.ApplyCommandLine;
  Config.Sanitize;

  ShowFrameRate := Config.ShowFrameRate;

  FreeAndNil(FWindow);

  aWindow := cCHXSDL3Window.Create(Title, Config.Width,
    Config.Height, Config.Scale, Config.FullScreen, Config.Render,
    Config.LogicalPresentation, Config.VSync);

  Window := aWindow; // Sets SDLRenderer and SDLWindow

  // Create default debug font (index 0)
  if Assigned(SDLRenderer) then
    FFontList.Add(cCHXSDL3FontDebug.Create(SDLRenderer, SDLFColor(1, 1, 1, 1)));
end;

procedure cCHXSDL3Engine.Run;
var
  ProgExit, HandledEvent: Boolean;
  aEvent, LPEvent: TSDL_Event;
  ComputeBegin: CUInt64; //< Actual Compute only time.
  i: Integer;
  aComp: caCHXSDL3Component;
begin
  ProgExit := False;
  FPSMng := cCHXSDL3FPSManager.Create(Config.FPS);

  try
    // Components are initialized by AddComponent.
    Self.Setup;

    while (not ProgExit) do
    begin
      // COMPUTE
      ComputeBegin := SDL_GetTicks;
      Self.Compute(ProgExit);

      for aComp in CompList do
      begin
        if ProgExit then Break;
        aComp.Compute(FPSMng.LastFullTime, ProgExit);
      end;

      LastComputeTime := SDL_GetTicks - ComputeBegin;

      // Wait to next frame.
      LastIdleTime := FPSMng.Delay;

      // Don't draw if minimized
      if not Window.Minimized then
      begin
        // DRAW
        Draw;

        for aComp in CompList do
        begin
          Window.PushRenderSize(aComp.LogPresW, aComp.LogPresH,
            aComp.LogPresMode);
          aComp.Draw(Render);
          Window.PopRenderSize;
        end;

        if ShowFrameRate
          // and ((FPSMng.FrameCount and 31) = 0)
          then
        begin
          Window.PushRenderSize(Window.WindowWidth, Window.WindowHeight,
            SDL_LOGICAL_PRESENTATION_DISABLED);
          if Assigned(FontDebug) then
          begin
            FontDebug.Color := SDLFColor(1, 0, 1, 1);
            FontDebug.RenderDynStr(Window.WindowWidth - 144,
              Window.WindowHeight - 8,
              Format('%4d (%4d) / %4d', [FPSMng.LastFullTime, LastIdleTime, LastComputeTime]));
          end;
          Window.PopRenderSize;

          // Window.Title := Format('%0:s: %1:d ms (%2:d ms)',
          //   [Title, FPSMng.LastFrameTime, FPSMng.LastCompTime]);
        end;


        // Screenshot requested (before present)
        if FScreenshotRequested then
        begin
          FScreenshotRequested := False;
          DoTakeScreenshot;
        end;

        // UPDATE RENDER
        SDL_RenderPresent(SDLRenderer);
      end;

      // EVENTS
      // SDL_PumpEvents;

      while SDL_PollEvent(@aEvent) do
      begin
        HandledEvent := False; // Used to see if a event is Handled

        // First: Window events
        case aEvent.type_ of
          SDL_EVENT_WINDOW_EXPOSED, SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED,
          SDL_EVENT_WINDOW_METAL_VIEW_RESIZED : HandledEvent := True;
          //< Not needed in cCHXSDL3Engine context.
        otherwise
          Window.HandleEvent(aEvent, HandledEvent);
        end;

        // Second: Pass event to current component
        if Assigned(FocusedComp) then
        begin
          Window.PushRenderSize(FocusedComp.LogPresW, FocusedComp.LogPresH,
            FocusedComp.LogPresMode);
          LPEvent := aEvent;
          SDL_ConvertEventToRenderCoordinates(SDLRenderer, @LPEvent);
          FocusedComp.HandleEvent(LPEvent, HandledEvent, ProgExit);
          Window.PopRenderSize;
        end;

        // Third: Pass to all components
        for aComp in CompList do
        begin
          if aComp = FocusedComp then Continue;
          Window.PushRenderSize(aComp.LogPresW, aComp.LogPresH,
            aComp.LogPresMode);
          LPEvent := aEvent;
          SDL_ConvertEventToRenderCoordinates(SDLRenderer, @LPEvent);
          aComp.HandleEvent(LPEvent, HandledEvent, ProgExit);
          Window.PopRenderSize;
        end;

        // Fourth: Fallback to engine
        LPEvent := aEvent;
        SDL_ConvertEventToRenderCoordinates(SDLRenderer, @LPEvent);
        HandleEvent(LPEvent, HandledEvent, ProgExit);
      end;

      // Getting current focused component
      FocusedComp := nil;
      i := 0;
      while (not assigned(FocusedComp)) and (i < CompList.Count) do
      begin
        if CompList[i].Focused then
          FocusedComp := CompList[i];
        Inc(i);
      end;

      // Restoring to initial Logical Presentation
      Window.PopRenderSize(-1);
    end;

  finally

    Finish;
    for aComp in CompList do
      aComp.Finish;
    FPSMng.Free;
  end;
end;

destructor cCHXSDL3Engine.Destroy;
begin
  CompList.Free;
  FFontList.Free;

  Config.Free;

  Window.Free; // Frees Render too

  // Little SDL error and leak test.
  if (SDL_GetError <> nil) and (SDL_GetError^ <> #0) then
    SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, '%s', [SDL_GetError]);
  if SDL_GetNumAllocations > 0 then
     SDL_LogWarn(SDL_LOG_CATEGORY_APPLICATION,
       'Mem allocations not freed: %d', [SDL_GetNumAllocations]);

  SDL_Quit;

  inherited Destroy;
end;

end.
{< This source is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License as published by the Free
  Software Foundation; either version 3 of the License, or (at your option)
  any later version.

  This code is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.

  A copy of the GNU General Public License is available on the World Wide Web
  at <http://www.gnu.org/copyleft/gpl.html>. You can also obtain it by writing
  to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
  MA 02111-1307, USA.
}
