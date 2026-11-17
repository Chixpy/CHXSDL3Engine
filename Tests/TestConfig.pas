program TestConfig;
{<
  Non-interactive tests for cCHXSDL3Config, using CHXTests.

  (C) 2026 Chixpy https://github.com/Chixpy
}
{$mode ObjFPC}{$H+}
uses
  SysUtils, IniFiles, SDL3,
  ucCHXSDL3Config,
  ucCHXTestGroup, ucCHXTWConsole;

type

  { cCHXSDL3ConfigTests }

  cCHXSDL3ConfigTests = class(cCHXTestGroup)
  published
    procedure TestDefaults;
    procedure TestIni;
    procedure TestCommandLineRepeated;
    procedure TestCommandLineSpaces;
    procedure TestCommandLineTerminator;
    procedure TestConfigOrder;
    procedure TestSanitize;
    procedure TestSaveRoundTrip;
    procedure TestLogicalNames;
  end;

{
  cCHXSDL3ConfigTests
}

procedure cCHXSDL3ConfigTests.TestDefaults;
var
  C: cCHXSDL3Config;
begin
  C := cCHXSDL3Config.Create;
  try
    MustEqual(Int64(C.Width), 0, 'default Width');
    MustEqual(Int64(C.Height), 0, 'default Height');
    MustEqual(Int64(C.Scale), 0, 'default Scale');
    MustFalse(C.FullScreen, 'default FullScreen');
    MustEqual(C.Render, '', 'default Render');
    MustEqual(Int64(C.FPS), cCHXSDL3DefaultFPS, 'default FPS');
    MustTrue(C.LogicalPresentation =
      SDL_LOGICAL_PRESENTATION_LETTERBOX, 'default LogicalPresentation');
    MustFalse(C.ShowFrameRate, 'default ShowFrameRate');
    MustFalse(C.VSync, 'default VSync');
  finally
    C.Free;
  end;
end;

procedure cCHXSDL3ConfigTests.TestIni;
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
      MustEqual(Int64(C.Width), 640, 'ini Width');
      MustEqual(Int64(C.Height), 480, 'ini Height');
      MustEqual(Int64(C.Scale), 2, 'ini Scale');
      MustTrue(C.FullScreen, 'ini FullScreen');
      MustEqual(C.Render, 'software', 'ini Render');
      MustEqual(Int64(C.FPS), 45, 'ini FPS');
      MustTrue(C.LogicalPresentation =
        SDL_LOGICAL_PRESENTATION_INTEGER_SCALE, 'ini LogicalPresentation');
      MustTrue(C.ShowFrameRate, 'ini ShowFrameRate');
      MustTrue(C.VSync, 'ini VSync');
    finally
      C.Free;
    end;
  finally
    Ini.Free;
  end;
end;

procedure cCHXSDL3ConfigTests.TestCommandLineRepeated;
var
  C: cCHXSDL3Config;
  Unhandled: TCHXSDL3StringArray;
begin
  C := cCHXSDL3Config.Create;
  try
    Unhandled := C.ApplyCommandLine(['--width=640', '--unknown',
      '--width=800', '--fps=60', '--logical=integer', '--fullscreen',
      '--host-arg']);
    MustEqual(Int64(C.Width), 800, 'cli repeated width');
    MustEqual(Int64(C.FPS), 60, 'cli fps');
    MustTrue(C.LogicalPresentation =
      SDL_LOGICAL_PRESENTATION_INTEGER_SCALE, 'cli logical');
    MustTrue(C.FullScreen, 'cli fullscreen');
    MustEqual(Int64(Length(Unhandled)), 2, 'cli unhandled count');
    if Length(Unhandled) = 2 then
    begin
      MustEqual(Unhandled[0], '--unknown', 'cli unhandled arg 1');
      MustEqual(Unhandled[1], '--host-arg', 'cli unhandled arg 2');
    end;
  finally
    C.Free;
  end;
end;

procedure cCHXSDL3ConfigTests.TestCommandLineSpaces;
var
  C: cCHXSDL3Config;
begin
  C := cCHXSDL3Config.Create;
  try
    C.FullScreen := True;
    C.ApplyCommandLine(['--width', '1024', '--height', '768',
      '--fps', '50', '--no-fullscreen', '--logical', 'overscan']);
    MustEqual(Int64(C.Width), 1024, 'cli space width');
    MustEqual(Int64(C.Height), 768, 'cli space height');
    MustEqual(Int64(C.FPS), 50, 'cli space fps');
    MustFalse(C.FullScreen, 'cli no-fullscreen');
    MustTrue(C.LogicalPresentation =
      SDL_LOGICAL_PRESENTATION_OVERSCAN, 'cli logical overscan');
  finally
    C.Free;
  end;
end;

procedure cCHXSDL3ConfigTests.TestCommandLineTerminator;
var
  C: cCHXSDL3Config;
  Unhandled: TCHXSDL3StringArray;
begin
  C := cCHXSDL3Config.Create;
  try
    Unhandled := C.ApplyCommandLine(['--width=100', '--', '--width=200']);
    MustEqual(Int64(C.Width), 100, 'cli before terminator');
    MustEqual(Int64(Length(Unhandled)), 1, 'cli terminator unhandled');
    if Length(Unhandled) = 1 then
      MustEqual(Unhandled[0], '--width=200', 'cli terminator arg');
  finally
    C.Free;
  end;
end;

procedure cCHXSDL3ConfigTests.TestConfigOrder;
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

      MustEqual(Int64(C.Width), 800, 'config order width');
      MustEqual(Int64(C.Height), 480, 'config order height');
      MustEqual(Int64(C.FPS), 60, 'config order fps');
      MustEqual(Int64(Length(Unhandled)), 0, 'config order unhandled');
    finally
      C.Free;
    end;
  finally
    DeleteFile(FileName);
  end;
end;

procedure cCHXSDL3ConfigTests.TestSanitize;
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
    MustEqual(Int64(C.Width), 0, 'sanitize Width');
    MustEqual(Int64(C.Height), 0, 'sanitize Height');
    MustEqual(Int64(C.Scale), 0, 'sanitize Scale');
    MustEqual(Int64(C.FPS), 1, 'sanitize FPS');
    MustTrue(C.LogicalPresentation =
      SDL_LOGICAL_PRESENTATION_LETTERBOX, 'sanitize LogicalPresentation');

    C.FPS := 5000;
    C.Sanitize;
    MustEqual(Int64(C.FPS), cCHXSDL3MaxFPS, 'sanitize max FPS');
  finally
    C.Free;
  end;
end;

procedure cCHXSDL3ConfigTests.TestSaveRoundTrip;
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
      MustEqual(Int64(D.Width), 123, 'roundtrip Width');
      MustEqual(Int64(D.Height), 456, 'roundtrip Height');
      MustEqual(Int64(D.Scale), 2, 'roundtrip Scale');
      MustTrue(D.FullScreen, 'roundtrip FullScreen');
      MustEqual(D.Render, 'software', 'roundtrip Render');
      MustEqual(Int64(D.FPS), 75, 'roundtrip FPS');
      MustTrue(D.LogicalPresentation =
        SDL_LOGICAL_PRESENTATION_INTEGER_SCALE,
        'roundtrip LogicalPresentation');
      MustTrue(D.ShowFrameRate, 'roundtrip ShowFrameRate');
      MustTrue(D.VSync, 'roundtrip VSync');
    finally
      D.Free;
    end;
  finally
    Ini.Free;
  end;
end;

procedure cCHXSDL3ConfigTests.TestLogicalNames;
var
  Mode: TSDL_RendererLogicalPresentation;
begin
  MustTrue(CHXSDL3StringToLogicalPresentation('Disabled', Mode),
    'parse logical name Disabled');
  MustEqual(Int64(Ord(Mode)),
    Int64(Ord(SDL_LOGICAL_PRESENTATION_DISABLED)), 'logical name Disabled');

  MustTrue(CHXSDL3StringToLogicalPresentation('integer-scale', Mode),
    'parse logical name integer-scale');
  MustEqual(Int64(Ord(Mode)),
    Int64(Ord(SDL_LOGICAL_PRESENTATION_INTEGER_SCALE)),
    'logical name integer-scale');

  MustTrue(CHXSDL3StringToLogicalPresentation('3', Mode),
    'parse logical name numeric');
  MustEqual(Int64(Ord(Mode)),
    Int64(Ord(SDL_LOGICAL_PRESENTATION_OVERSCAN)), 'logical name numeric');

  MustFalse(CHXSDL3StringToLogicalPresentation('nope', Mode),
    'logical name invalid');
  MustEqual(CHXSDL3LogicalPresentationToString(
    SDL_LOGICAL_PRESENTATION_INTEGER_SCALE), 'IntegerScale', 'logical string');
end;

var
  MainTest: cCHXSDL3ConfigTests;

begin
  MainTest := cCHXSDL3ConfigTests.Create;
  try
    MainTest.AddWriter(cCHXTWConsole);
    ExitCode := MainTest.RunAllCases;
  finally
    MainTest.Free;
  end;
end.
