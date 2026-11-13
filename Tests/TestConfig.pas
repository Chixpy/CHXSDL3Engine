program TestConfig;
{<
  Non-interactive tests for cCHXSDL3Config.

  (C) 2026 Chixpy https://github.com/Chixpy
}
{$mode ObjFPC}{$H+}
uses
  SysUtils, IniFiles, SDL3,
  ucCHXSDL3Config;

var
  Failures: Integer = 0;

procedure Check(const aName: String; const aGot, aExpected: Boolean);
begin
  if aGot <> aExpected then
  begin
    Inc(Failures);
    WriteLn('FAIL: ', aName, ' (got ', aGot, ', expected ', aExpected, ')');
  end;
end;

procedure CheckInt(const aName: String; const aGot, aExpected: Int64);
begin
  if aGot <> aExpected then
  begin
    Inc(Failures);
    WriteLn('FAIL: ', aName, ' (got ', aGot, ', expected ', aExpected, ')');
  end;
end;

procedure CheckStr(const aName, aGot, aExpected: String);
begin
  if aGot <> aExpected then
  begin
    Inc(Failures);
    WriteLn('FAIL: ', aName, ' (got "', aGot, '", expected "', aExpected, '")');
  end;
end;

procedure TestDefaults;
var
  C: cCHXSDL3Config;
begin
  C := cCHXSDL3Config.Create;
  try
    CheckInt('default Width', C.Width, 0);
    CheckInt('default Height', C.Height, 0);
    CheckInt('default Scale', C.Scale, 0);
    Check('default FullScreen', C.FullScreen, False);
    CheckStr('default Render', C.Render, '');
    CheckInt('default FPS', C.FPS, cCHXSDL3DefaultFPS);
    Check('default LogicalPresentation',
      C.LogicalPresentation = SDL_LOGICAL_PRESENTATION_LETTERBOX, True);
    Check('default ShowFrameRate', C.ShowFrameRate, False);
    Check('default VSync', C.VSync, False);
  finally
    C.Free;
  end;
end;

procedure TestIni;
var
  C: cCHXSDL3Config;
  Ini: TMemIniFile;
begin
  Ini := TMemIniFile.Create('');
  try
    Ini.WriteInteger(krsIniSectionSDL3Engine, krsIniKeyWidth, 640);
    Ini.WriteInteger(krsIniSectionSDL3Engine, krsIniKeyHeight, 480);
    Ini.WriteInteger(krsIniSectionSDL3Engine, krsIniKeyScale, 2);
    Ini.WriteBool(krsIniSectionSDL3Engine, krsIniKeyFullScreen, True);
    Ini.WriteString(krsIniSectionSDL3Engine, krsIniKeyRender, 'software');
    Ini.WriteInteger(krsIniSectionSDL3Engine, krsIniKeyFPS, 45);
    Ini.WriteString(krsIniSectionSDL3Engine, krsIniKeyLogicalPresentation,
      'IntegerScale');
    Ini.WriteBool(krsIniSectionSDL3Engine, krsIniKeyShowFrameRate, True);
    Ini.WriteBool(krsIniSectionSDL3Engine, krsIniKeyVSync, True);

    C := cCHXSDL3Config.Create;
    try
      C.LoadFromIni(Ini);
      CheckInt('ini Width', C.Width, 640);
      CheckInt('ini Height', C.Height, 480);
      CheckInt('ini Scale', C.Scale, 2);
      Check('ini FullScreen', C.FullScreen, True);
      CheckStr('ini Render', C.Render, 'software');
      CheckInt('ini FPS', C.FPS, 45);
      Check('ini LogicalPresentation',
        C.LogicalPresentation = SDL_LOGICAL_PRESENTATION_INTEGER_SCALE, True);
      Check('ini ShowFrameRate', C.ShowFrameRate, True);
      Check('ini VSync', C.VSync, True);
    finally
      C.Free;
    end;
  finally
    Ini.Free;
  end;
end;

procedure TestCommandLineRepeated;
var
  C: cCHXSDL3Config;
  Unhandled: TCHXSDL3StringArray;
begin
  C := cCHXSDL3Config.Create;
  try
    Unhandled := C.ApplyCommandLine(['--width=640', '--unknown',
      '--width=800', '--fps=60', '--logical=integer', '--fullscreen',
      '--host-arg']);
    CheckInt('cli repeated width', C.Width, 800);
    CheckInt('cli fps', C.FPS, 60);
    Check('cli logical',
      C.LogicalPresentation = SDL_LOGICAL_PRESENTATION_INTEGER_SCALE, True);
    Check('cli fullscreen', C.FullScreen, True);
    CheckInt('cli unhandled count', Length(Unhandled), 2);
    if Length(Unhandled) = 2 then
    begin
      CheckStr('cli unhandled arg 1', Unhandled[0], '--unknown');
      CheckStr('cli unhandled arg 2', Unhandled[1], '--host-arg');
    end;
  finally
    C.Free;
  end;
end;

procedure TestCommandLineSpaces;
var
  C: cCHXSDL3Config;
begin
  C := cCHXSDL3Config.Create;
  try
    C.FullScreen := True;
    C.ApplyCommandLine(['--width', '1024', '--height', '768',
      '--fps', '50', '--no-fullscreen', '--logical', 'overscan']);
    CheckInt('cli space width', C.Width, 1024);
    CheckInt('cli space height', C.Height, 768);
    CheckInt('cli space fps', C.FPS, 50);
    Check('cli no-fullscreen', C.FullScreen, False);
    Check('cli logical overscan',
      C.LogicalPresentation = SDL_LOGICAL_PRESENTATION_OVERSCAN, True);
  finally
    C.Free;
  end;
end;

procedure TestCommandLineTerminator;
var
  C: cCHXSDL3Config;
  Unhandled: TCHXSDL3StringArray;
begin
  C := cCHXSDL3Config.Create;
  try
    Unhandled := C.ApplyCommandLine(['--width=100', '--', '--width=200']);
    CheckInt('cli before terminator', C.Width, 100);
    CheckInt('cli terminator unhandled', Length(Unhandled), 1);
    if Length(Unhandled) = 1 then
      CheckStr('cli terminator arg', Unhandled[0], '--width=200');
  finally
    C.Free;
  end;
end;

procedure TestConfigOrder;
var
  C: cCHXSDL3Config;
  Ini: TMemIniFile;
  FileName: String;
  Unhandled: TCHXSDL3StringArray;
begin
  FileName := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
    'chxsdl3_test_config.ini';

  Ini := TMemIniFile.Create(FileName);
  try
    Ini.WriteInteger(krsIniSectionSDL3Engine, krsIniKeyWidth, 800);
    Ini.WriteInteger(krsIniSectionSDL3Engine, krsIniKeyHeight, 480);
    Ini.WriteInteger(krsIniSectionSDL3Engine, krsIniKeyFPS, 45);
    Ini.UpdateFile;
  finally
    Ini.Free;
  end;

  try
    C := cCHXSDL3Config.Create;
    try
      C.Width := 320;
      C.Height := 240;
      C.FPS := 30;

      // Order: width=1024, then the file (width=800, height=480, fps=45),
      // then fps=60. The file overrides width because it is loaded later.
      Unhandled := C.ApplyCommandLine(['--width=1024', '--config', FileName,
        '--fps=60']);

      CheckInt('config order width', C.Width, 800);
      CheckInt('config order height', C.Height, 480);
      CheckInt('config order fps', C.FPS, 60);
      CheckInt('config order unhandled', Length(Unhandled), 0);
    finally
      C.Free;
    end;
  finally
    DeleteFile(FileName);
  end;
end;

procedure TestSanitize;
var
  C: cCHXSDL3Config;
begin
  C := cCHXSDL3Config.Create;
  try
    C.Width := -10;
    C.Height := -20;
    C.Scale := -1;
    C.FPS := 0;
    C.LogicalPresentation := 99;
    C.Sanitize;
    CheckInt('sanitize Width', C.Width, 0);
    CheckInt('sanitize Height', C.Height, 0);
    CheckInt('sanitize Scale', C.Scale, 0);
    CheckInt('sanitize FPS', C.FPS, 1);
    Check('sanitize LogicalPresentation',
      C.LogicalPresentation = SDL_LOGICAL_PRESENTATION_LETTERBOX, True);

    C.FPS := 5000;
    C.Sanitize;
    CheckInt('sanitize max FPS', C.FPS, cCHXSDL3MaxFPS);
  finally
    C.Free;
  end;
end;

procedure TestSaveRoundTrip;
var
  C, D: cCHXSDL3Config;
  Ini: TMemIniFile;
begin
  Ini := TMemIniFile.Create('');
  try
    C := cCHXSDL3Config.Create;
    try
      C.Width := 123;
      C.Height := 456;
      C.Scale := 2;
      C.FullScreen := True;
      C.Render := 'software';
      C.FPS := 75;
      C.LogicalPresentation := SDL_LOGICAL_PRESENTATION_INTEGER_SCALE;
      C.ShowFrameRate := True;
      C.VSync := True;
      C.SaveToIni(Ini);
    finally
      C.Free;
    end;

    D := cCHXSDL3Config.Create;
    try
      D.LoadFromIni(Ini);
      CheckInt('roundtrip Width', D.Width, 123);
      CheckInt('roundtrip Height', D.Height, 456);
      CheckInt('roundtrip Scale', D.Scale, 2);
      Check('roundtrip FullScreen', D.FullScreen, True);
      CheckStr('roundtrip Render', D.Render, 'software');
      CheckInt('roundtrip FPS', D.FPS, 75);
      Check('roundtrip LogicalPresentation',
        D.LogicalPresentation = SDL_LOGICAL_PRESENTATION_INTEGER_SCALE, True);
      Check('roundtrip ShowFrameRate', D.ShowFrameRate, True);
      Check('roundtrip VSync', D.VSync, True);
    finally
      D.Free;
    end;
  finally
    Ini.Free;
  end;
end;

procedure TestLogicalNames;
var
  Mode: TSDL_RendererLogicalPresentation;
begin
  Check('logical name disabled',
    CHXSDL3StringToLogicalPresentation('Disabled', Mode)
      and (Mode = SDL_LOGICAL_PRESENTATION_DISABLED), True);
  Check('logical name integer-scale',
    CHXSDL3StringToLogicalPresentation('integer-scale', Mode)
      and (Mode = SDL_LOGICAL_PRESENTATION_INTEGER_SCALE), True);
  Check('logical name numeric',
    CHXSDL3StringToLogicalPresentation('3', Mode)
      and (Mode = SDL_LOGICAL_PRESENTATION_OVERSCAN), True);
  Check('logical name invalid',
    CHXSDL3StringToLogicalPresentation('nope', Mode), False);
  CheckStr('logical string',
    CHXSDL3LogicalPresentationToString(SDL_LOGICAL_PRESENTATION_INTEGER_SCALE),
    'IntegerScale');
end;

begin
  TestDefaults;
  TestIni;
  TestCommandLineRepeated;
  TestCommandLineSpaces;
  TestCommandLineTerminator;
  TestConfigOrder;
  TestSanitize;
  TestSaveRoundTrip;
  TestLogicalNames;

  if Failures = 0 then
    WriteLn('All config tests passed.')
  else
  begin
    WriteLn(Failures, ' config test(s) failed.');
    Halt(1);
  end;
end.
