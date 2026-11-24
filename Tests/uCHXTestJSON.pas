unit uCHXTestJSON;
{< Helpers to enable the CHXTests JSON writer on demand.

  The console writer is always used. A JSON report is added only when
  `--json <file>` / `--json=<file>` is passed, or when `CHXTESTS_JSON` is
  set. Command line arguments take precedence over the environment.
}
{$mode ObjFPC}{$H+}

interface

uses
  SysUtils, ucCHXTestGroup, ucCHXTWJSON;

function AddJSONWriter(const aMainTest : cCHXTestGroup;
  const aDefaultName : String; out aWriter : cCHXTWJSON) : Boolean;
{< Attach a JSON writer if a report path was requested.

  A directory (existing, with a trailing separator or without extension)
  gets `<aDefaultName>.json` appended. Otherwise the value is used as the
  exact file name.

  @param(aMainTest Group that receives the writer.)
  @param(aDefaultName Base name used when the path is a directory.)
  @param(aWriter Created writer, or @nil when no report was requested.)
  @returns(@True when a writer was added.)
}

procedure CheckJSONSaveError(const aWriter : cCHXTWJSON;
  var aExitCode : Integer);
{< Report a failed JSON save and mark the run as errored.

  @param(aWriter Writer to check; it may be @nil.)
  @param(aExitCode Exit code of the run; set to `2` on save error when the
    tests themselves passed.)
}

implementation

function ResolveJSONFileName(const aDefaultName : String) : String;
var
  i : Integer;
  Param : String;
begin
  Result := '';
  for i := 1 to ParamCount do
  begin
    Param := ParamStr(i);

    if CompareText(Param, '--json') = 0 then
    begin
      if (i < ParamCount) and (ParamStr(i + 1) <> '') and
        (Copy(ParamStr(i + 1), 1, 2) <> '--') then
        Result := ParamStr(i + 1)
      else
        WriteLn(StdErr, 'Warning: --json needs a file name.');
      Break;
    end;

    if CompareText(Copy(Param, 1, 7), '--json=') = 0 then
    begin
      Result := Copy(Param, 8, MaxInt);
      Break;
    end;
  end;

  if Result = '' then
    Result := GetEnvironmentVariable('CHXTESTS_JSON');
  if Result = '' then Exit;

  if (Result[Length(Result)] = PathDelim) or
    (Result[Length(Result)] = '\') or (ExtractFileExt(Result) = '') then
  begin
    if not DirectoryExists(Result) then
      ForceDirectories(Result);
    Result := IncludeTrailingPathDelimiter(Result) + aDefaultName + '.json';
  end;
end;

function AddJSONWriter(const aMainTest : cCHXTestGroup;
  const aDefaultName : String; out aWriter : cCHXTWJSON) : Boolean;
var
  FileName : String;
begin
  aWriter := nil;
  Result := False;

  FileName := ResolveJSONFileName(aDefaultName);
  if FileName = '' then Exit;

  aWriter := cCHXTWJSON(aMainTest.AddWriter(cCHXTWJSON));
  aWriter.FileName := FileName;
  Result := True;
end;

procedure CheckJSONSaveError(const aWriter : cCHXTWJSON;
  var aExitCode : Integer);
begin
  if not Assigned(aWriter) then Exit;
  if aWriter.SaveError = '' then Exit;

  WriteLn(StdErr, 'Could not save JSON report: ', aWriter.SaveError);
  if aExitCode = 0 then
    aExitCode := 2;
end;

end.
