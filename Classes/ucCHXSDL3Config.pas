unit ucCHXSDL3Config;
{< Unit of cCHXSDL3Config class.

  (C) 2026 Chixpy https://github.com/Chixpy
}
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, CTypes, IniFiles, // FPC
  SDL3;

const
  krsIniSectionSDL3Engine = 'SDL3Engine';
  krsIniKeyWidth = 'Width';
  krsIniKeyHeight = 'Height';
  krsIniKeyScale = 'Scale';
  krsIniKeyFullScreen = 'FullScreen';
  krsIniKeyRender = 'Render';
  krsIniKeyFPS = 'FPS';
  krsIniKeyLogicalPresentation = 'LogicalPresentation';
  krsIniKeyShowFrameRate = 'ShowFrameRate';
  krsIniKeyVSync = 'VSync';

  cCHXSDL3DefaultFPS = 30;
  cCHXSDL3MaxFPS = 1000;

type
  TCHXSDL3StringArray = array of String;

  { cCHXSDL3Config }

  cCHXSDL3Config = class(TPersistent)
  public
    DefaultFileName : String;
    {< Default filename used when LoadFromFile or SaveToFile is called with
         an empty filename. }

    Width : CInt;
    Height : CInt;
    Scale : CInt;
    FullScreen : Boolean;
    Render : String;
    FPS : CUInt16;
    LogicalPresentation : TSDL_RendererLogicalPresentation;
    ShowFrameRate : Boolean;
    VSync : Boolean;

    procedure ResetDefaultConfig; virtual;
    {< Sets config properties to default values. }

    procedure LoadFromFile(const aFilename : String); virtual;
    {< Loads data from an .ini file.

      @param(aFilename Filename of the .ini file to read from. If empty,
        DefaultFileName is used.)
    }

    procedure SaveToFile(const aFilename : String;
      const ClearFile : Boolean); virtual;
    {< Saves data to an .ini file.

      @param(aFilename Filename of the .ini file to write to. If empty,
        DefaultFileName is used.)
      @param(ClearFile Clear file content before saving.)
    }

    procedure LoadFromIni(aIniFile : TCustomIniFile); virtual;
    {< Loads data from an already opened .ini file.

      The caller keeps ownership of the TIniFile/TMemIniFile object.
    }

    procedure SaveToIni(aIniFile : TCustomIniFile); virtual;
    {< Saves data to an already opened .ini file.

      The caller keeps ownership of the TIniFile/TMemIniFile object.
    }

    procedure ApplyCommandLine; overload;
    {< Applies the program command line arguments.

      Arguments are processed in order, so repeated options and configuration
      files are applied sequentially. Later values override earlier ones.
    }

    function ApplyCommandLine(const Args : array of String)
      : TCHXSDL3StringArray; overload;
    {< Applies an explicit list of command line arguments.

      @param(Args Arguments to process, without the program name.)
      @returns(The arguments that were not recognized by the engine.)
    }

    procedure Sanitize; virtual;
    {< Clamps values to their valid ranges and fixes invalid enum values. }

    constructor Create;
    destructor Destroy; override;
  end;

function CHXSDL3LogicalPresentationToString(
  const aMode : TSDL_RendererLogicalPresentation) : String;
{< Returns the configuration file name of a logical presentation mode. }

function CHXSDL3StringToLogicalPresentation(const aValue : String;
  out aMode : TSDL_RendererLogicalPresentation) : Boolean;
{< Parses a logical presentation mode name or number.

  Accepted names are case-insensitive and ignore '-', '_' and spaces:
  Disabled, Stretch, Letterbox, Overscan, IntegerScale. Numeric values
  0..4 are also accepted.
}

implementation

const
  cCHXSDL3LogicalNames : array[0..4] of String = (
    'Disabled', 'Stretch', 'Letterbox', 'Overscan', 'IntegerScale');

function CHXSDL3LogicalPresentationToString(
  const aMode : TSDL_RendererLogicalPresentation) : String;
begin
  if (aMode >= SDL_LOGICAL_PRESENTATION_DISABLED)
    and (aMode <= SDL_LOGICAL_PRESENTATION_INTEGER_SCALE) then
    Result := cCHXSDL3LogicalNames[aMode]
  else
    Result := cCHXSDL3LogicalNames[SDL_LOGICAL_PRESENTATION_LETTERBOX];
end;

function CHXSDL3StringToLogicalPresentation(const aValue : String;
  out aMode : TSDL_RendererLogicalPresentation) : Boolean;
var
  aName : String;
begin
  aMode := SDL_LOGICAL_PRESENTATION_LETTERBOX;
  Result := False;

  aName := LowerCase(Trim(aValue));
  aName := StringReplace(aName, '-', '', [rfReplaceAll]);
  aName := StringReplace(aName, '_', '', [rfReplaceAll]);
  aName := StringReplace(aName, ' ', '', [rfReplaceAll]);

  case aName of
    'disabled', '0' :
      aMode := SDL_LOGICAL_PRESENTATION_DISABLED;
    'stretch', '1' :
      aMode := SDL_LOGICAL_PRESENTATION_STRETCH;
    'letterbox', '2' :
      aMode := SDL_LOGICAL_PRESENTATION_LETTERBOX;
    'overscan', '3' :
      aMode := SDL_LOGICAL_PRESENTATION_OVERSCAN;
    'integer', 'integerscale', '4' :
      aMode := SDL_LOGICAL_PRESENTATION_INTEGER_SCALE;
    otherwise
      Exit;
  end;

  Result := True;
end;

procedure AddUnhandled(var aArgs : TCHXSDL3StringArray; const aValue : String);
begin
  SetLength(aArgs, Length(aArgs) + 1);
  aArgs[High(aArgs)] := aValue;
end;

function SplitOption(const aArg : String; out aName, aValue : String;
  out aHasValue : Boolean) : Boolean;
var
  aBody : String;
  aPos : SizeInt;
begin
  aName := '';
  aValue := '';
  aHasValue := False;
  Result := False;

  if Length(aArg) <= 2 then Exit;
  if Copy(aArg, 1, 2) <> '--' then Exit;

  aBody := Copy(aArg, 3, MaxInt);
  aPos := Pos('=', aBody);
  if aPos > 0 then
  begin
    aName := LowerCase(Copy(aBody, 1, aPos - 1));
    aValue := Copy(aBody, aPos + 1, MaxInt);
    aHasValue := True;
  end
  else
    aName := LowerCase(aBody);

  Result := aName <> '';
end;

function IsKnownOption(const aName : String) : Boolean;
begin
  Result := (aName = 'config') or (aName = 'width') or (aName = 'height')
    or (aName = 'scale') or (aName = 'fullscreen') or (aName = 'render')
    or (aName = 'fps') or (aName = 'logical') or (aName = 'show-fps')
    or (aName = 'vsync');
end;

procedure cCHXSDL3Config.ApplyCommandLine;
var
  Args : TCHXSDL3StringArray;
  i : CInt;
begin
  SetLength(Args, ParamCount);
  for i := 1 to ParamCount do
    Args[i - 1] := ParamStr(i);

  ApplyCommandLine(Args);
end;

function cCHXSDL3Config.ApplyCommandLine(const Args : array of String)
  : TCHXSDL3StringArray;
var
  i, j, aInt : CInt;
  aArg, aName, aValue, aBase : String;
  aHasValue, aBool : Boolean;
  aMode : TSDL_RendererLogicalPresentation;
begin
  Result := nil;
  SetLength(Result, 0);
  i := Low(Args);

  while i <= High(Args) do
  begin
    aArg := Args[i];

    // Everything after "--" belongs to the host program.
    if aArg = '--' then
    begin
      for j := i + 1 to High(Args) do
        AddUnhandled(Result, Args[j]);
      Break;
    end;

    if not SplitOption(aArg, aName, aValue, aHasValue) then
    begin
      AddUnhandled(Result, aArg);
      Inc(i);
      Continue;
    end;

    // Boolean options support the --no-<option> form.
    if (not aHasValue) and (Copy(aName, 1, 3) = 'no-') then
    begin
      aBase := Copy(aName, 4, MaxInt);
      if (aBase = 'fullscreen') or (aBase = 'show-fps')
        or (aBase = 'vsync') then
      begin
        aName := aBase;
        aValue := 'false';
        aHasValue := True;
      end;
    end;

    // Ignore unknown options without consuming their following argument.
    if not IsKnownOption(aName) then
    begin
      AddUnhandled(Result, aArg);
      Inc(i);
      Continue;
    end;

    // Boolean options without an explicit value mean true.
    if (not aHasValue) and ((aName = 'fullscreen') or (aName = 'show-fps')
      or (aName = 'vsync')) then
    begin
      aValue := 'true';
      aHasValue := True;
    end;

    // Options that require a value can use "--name value" too.
    if (not aHasValue) and (aName <> 'fullscreen') and (aName <> 'show-fps')
      and (aName <> 'vsync') then
    begin
      if (i < High(Args)) and (Copy(Args[i + 1], 1, 2) <> '--') then
      begin
        Inc(i);
        aValue := Args[i];
        aHasValue := True;
      end;
    end;

    if not aHasValue then
    begin
      AddUnhandled(Result, aArg);
      Inc(i);
      Continue;
    end;

    case aName of
      'config' :
        if aValue <> '' then
          LoadFromFile(aValue);
      'width' :
        if TryStrToInt(aValue, aInt) then
        begin
          if aInt < 0 then aInt := 0;
          Width := aInt;
        end;
      'height' :
        if TryStrToInt(aValue, aInt) then
        begin
          if aInt < 0 then aInt := 0;
          Height := aInt;
        end;
      'scale' :
        if TryStrToInt(aValue, aInt) then
        begin
          if aInt < 0 then aInt := 0;
          Scale := aInt;
        end;
      'fullscreen' :
        if TryStrToBool(aValue, aBool) then
          FullScreen := aBool;
      'render' :
        Render := aValue;
      'fps' :
        if TryStrToInt(aValue, aInt) then
        begin
          if aInt < 1 then aInt := 1;
          if aInt > cCHXSDL3MaxFPS then aInt := cCHXSDL3MaxFPS;
          FPS := CUInt16(aInt);
        end;
      'logical' :
        if CHXSDL3StringToLogicalPresentation(aValue, aMode) then
          LogicalPresentation := aMode;
      'show-fps' :
        if TryStrToBool(aValue, aBool) then
          ShowFrameRate := aBool;
      'vsync' :
        if TryStrToBool(aValue, aBool) then
          VSync := aBool;
      otherwise
        AddUnhandled(Result, aArg);
    end;

    Inc(i);
  end;
end;

procedure cCHXSDL3Config.LoadFromIni(aIniFile : TCustomIniFile);
var
  aInt : CInt;
  aStr : String;
  aMode : TSDL_RendererLogicalPresentation;
begin
  if not Assigned(aIniFile) then Exit;

  Width := aIniFile.ReadInteger(krsIniSectionSDL3Engine,
    krsIniKeyWidth, Width);
  Height := aIniFile.ReadInteger(krsIniSectionSDL3Engine,
    krsIniKeyHeight, Height);
  Scale := aIniFile.ReadInteger(krsIniSectionSDL3Engine,
    krsIniKeyScale, Scale);
  FullScreen := aIniFile.ReadBool(krsIniSectionSDL3Engine,
    krsIniKeyFullScreen, FullScreen);
  Render := aIniFile.ReadString(krsIniSectionSDL3Engine,
    krsIniKeyRender, Render);

  aInt := aIniFile.ReadInteger(krsIniSectionSDL3Engine,
    krsIniKeyFPS, FPS);
  if aInt < 0 then aInt := 0;
  if aInt > High(CUInt16) then aInt := High(CUInt16);
  FPS := CUInt16(aInt);

  aStr := aIniFile.ReadString(krsIniSectionSDL3Engine,
    krsIniKeyLogicalPresentation,
    CHXSDL3LogicalPresentationToString(LogicalPresentation));
  if CHXSDL3StringToLogicalPresentation(aStr, aMode) then
    LogicalPresentation := aMode;

  ShowFrameRate := aIniFile.ReadBool(krsIniSectionSDL3Engine,
    krsIniKeyShowFrameRate, ShowFrameRate);
  VSync := aIniFile.ReadBool(krsIniSectionSDL3Engine,
    krsIniKeyVSync, VSync);
end;

procedure cCHXSDL3Config.ResetDefaultConfig;
begin
  Width := 0; // 0 = Renderer use max window size
  Height := 0;
  Scale := 0; // 0 = Maximize the window
  FullScreen := False;
  Render := '';
  FPS := cCHXSDL3DefaultFPS;
  LogicalPresentation := SDL_LOGICAL_PRESENTATION_LETTERBOX;
  ShowFrameRate := False;
  VSync := False;
end;

procedure cCHXSDL3Config.Sanitize;
begin
  if Width < 0 then Width := 0;
  if Height < 0 then Height := 0;
  if Scale < 0 then Scale := 0;

  if FPS < 1 then FPS := 1;
  if FPS > cCHXSDL3MaxFPS then FPS := cCHXSDL3MaxFPS;

  if (LogicalPresentation < SDL_LOGICAL_PRESENTATION_DISABLED)
    or (LogicalPresentation > SDL_LOGICAL_PRESENTATION_INTEGER_SCALE) then
    LogicalPresentation := SDL_LOGICAL_PRESENTATION_LETTERBOX;
end;

constructor cCHXSDL3Config.Create;
begin
  inherited Create;
  ResetDefaultConfig;
end;

destructor cCHXSDL3Config.Destroy;
begin
  inherited Destroy;
end;

procedure cCHXSDL3Config.LoadFromFile(const aFilename : String);
var
  aName : String;
  aIniFile : TMemIniFile;
  IniFileOps : TIniFileOptions;
begin
  aName := aFilename;
  if aName = EmptyStr then
  begin
    aName := DefaultFileName;

    if aName = EmptyStr then
      Exit;
  end;

  if not FileExists(aName) then
    Exit;

  aIniFile := TMemIniFile.Create(aName);
  try
    IniFileOps := aIniFile.Options;
    Exclude(IniFileOps, ifoCaseSensitive); // Case insensitive
    Exclude(IniFileOps, ifoFormatSettingsActive); // Ignore FormatSettings
    aIniFile.Options := IniFileOps;

    LoadFromIni(aIniFile);
  finally
    aIniFile.Free;
  end;
end;

procedure cCHXSDL3Config.SaveToFile(const aFilename : String;
  const ClearFile : Boolean);
var
  aName : String;
  aIniFile : TMemIniFile;
  IniFileOps : TIniFileOptions;
begin
  aName := aFilename;
  if aName = EmptyStr then
  begin
    aName := DefaultFileName;

    if aName = EmptyStr then
      Exit;
  end;

  // Ini files are autoloaded on creation, so removing the file may be faster
  // than loading and clearing it.
  if ClearFile then
    DeleteFile(aName);

  aIniFile := TMemIniFile.Create(aName);
  try
    IniFileOps := aIniFile.Options;
    Exclude(IniFileOps, ifoCaseSensitive); // Case insensitive
    Exclude(IniFileOps, ifoFormatSettingsActive); // Ignore FormatSettings
    aIniFile.Options := IniFileOps;

    SaveToIni(aIniFile);
    aIniFile.UpdateFile;
  finally
    aIniFile.Free;
  end;
end;

procedure cCHXSDL3Config.SaveToIni(aIniFile : TCustomIniFile);
begin
  if not Assigned(aIniFile) then Exit;

  aIniFile.WriteInteger(krsIniSectionSDL3Engine, krsIniKeyWidth, Width);
  aIniFile.WriteInteger(krsIniSectionSDL3Engine, krsIniKeyHeight, Height);
  aIniFile.WriteInteger(krsIniSectionSDL3Engine, krsIniKeyScale, Scale);
  aIniFile.WriteBool(krsIniSectionSDL3Engine, krsIniKeyFullScreen, FullScreen);
  aIniFile.WriteString(krsIniSectionSDL3Engine, krsIniKeyRender, Render);
  aIniFile.WriteInteger(krsIniSectionSDL3Engine, krsIniKeyFPS, FPS);
  aIniFile.WriteString(krsIniSectionSDL3Engine, krsIniKeyLogicalPresentation,
    CHXSDL3LogicalPresentationToString(LogicalPresentation));
  aIniFile.WriteBool(krsIniSectionSDL3Engine, krsIniKeyShowFrameRate,
    ShowFrameRate);
  aIniFile.WriteBool(krsIniSectionSDL3Engine, krsIniKeyVSync, VSync);
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
