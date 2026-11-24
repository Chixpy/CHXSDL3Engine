program TestScreenshot;
{<
  Non-interactive tests for screenshot capture, using CHXTests.

  (C) 2026 Chixpy https://github.com/Chixpy
}
{$mode ObjFPC}{$H+}
uses
  SysUtils, Classes, CTypes, SDL3,
  ucCHXSDL3Engine,
  ucCHXTestGroup, ucCHXTWConsole, ucCHXTWJSON, uCHXTestJSON;

type
  { cTestScreenshotEngine }

  cTestScreenshotEngine = class(cCHXSDL3Engine)
  protected
    procedure Setup; override;
    procedure Compute(var ExitProg: Boolean); override;
    procedure Draw; override;
    procedure Finish; override;
    procedure HandleEvent(const aEvent: TSDL_Event; var Handled,
      ExitProg: Boolean); override;
  end;

  { cCHXSDL3ScreenshotTests }

  cCHXSDL3ScreenshotTests = class(cCHXTestGroup)
  published
    procedure TestTakeScreenshotCreatesFile;
  end;

procedure cTestScreenshotEngine.Setup;
begin
end;

procedure cTestScreenshotEngine.Compute(var ExitProg: Boolean);
begin
end;

procedure cTestScreenshotEngine.Draw;
begin
  Render.Clear(0.2, 0.2, 0.3);
end;

procedure cTestScreenshotEngine.Finish;
begin
end;

procedure cTestScreenshotEngine.HandleEvent(const aEvent: TSDL_Event; var Handled,
  ExitProg: Boolean);
begin
  inherited HandleEvent(aEvent, Handled, ExitProg);
end;

procedure RemoveDirRecursive(const ADir: String);
var
  SearchRec: TSearchRec;
  Path: String;
begin
  if not DirectoryExists(ADir) then Exit;
  if FindFirst(IncludeTrailingPathDelimiter(ADir) + '*', faAnyFile, SearchRec) = 0 then
  begin
    repeat
      if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
      begin
        Path := IncludeTrailingPathDelimiter(ADir) + SearchRec.Name;
        if (SearchRec.Attr and faDirectory) <> 0 then
          RemoveDirRecursive(Path)
        else
          DeleteFile(Path);
      end;
    until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
  end;
  RemoveDir(ADir);
end;

procedure cCHXSDL3ScreenshotTests.TestTakeScreenshotCreatesFile;
var
  E: cTestScreenshotEngine;
  ShotDir: String;
  SearchRec: TSearchRec;
  Count: Integer;
begin
  ShotDir := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
    'testshots_tmp';
  RemoveDirRecursive(ShotDir);
  ForceDirectories(ShotDir);

  E := cTestScreenshotEngine.Create(False, 'TestShot', 64, 64, 1, False, 'software',
    30, SDL_LOGICAL_PRESENTATION_LETTERBOX, False, False);
  try
    E.Config.ScreenshotDir := ShotDir;
    E.Init;
    E.TakeScreenshotNow;

    Count := 0;
    if FindFirst(IncludeTrailingPathDelimiter(ShotDir) + '*.bmp', faAnyFile,
      SearchRec) = 0 then
    begin
      repeat
        Inc(Count);
      until FindNext(SearchRec) <> 0;
      FindClose(SearchRec);
    end;
    MustTrue(Count >= 1, 'screenshot file created');

    E.TakeScreenshotNow;
    Count := 0;
    if FindFirst(IncludeTrailingPathDelimiter(ShotDir) + '*.bmp', faAnyFile,
      SearchRec) = 0 then
    begin
      repeat
        Inc(Count);
      until FindNext(SearchRec) <> 0;
      FindClose(SearchRec);
    end;
    MustTrue(Count >= 2, 'second screenshot file created');
  finally
    E.Free;
    RemoveDirRecursive(ShotDir);
    SDL_Quit;
  end;
end;

var
  MainTest: cCHXSDL3ScreenshotTests;
  JSONWriter: cCHXTWJSON;

begin
  MainTest := cCHXSDL3ScreenshotTests.Create('CHXSDL3 screenshot tests');
  try
    MainTest.AddWriter(cCHXTWConsole);
    AddJSONWriter(MainTest, 'TestScreenshot', JSONWriter);
    ExitCode := MainTest.RunAllCases;
    CheckJSONSaveError(JSONWriter, ExitCode);
  finally
    MainTest.Free;
  end;
end.
