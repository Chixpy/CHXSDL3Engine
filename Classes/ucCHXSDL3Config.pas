unit ucCHXSDL3Config;
{< Unit of cCHXSDL3Config class.

  (C) 2026 Chixpy https://github.com/Chixpy
}
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, CTypes, IniFiles; // FPC

const
  krsIniSectionSDL3Engine = 'SDL3Engine';
  krsIniKeyWidth = 'Width';
  krsIniKeyHeight = 'Height';
  krsIniKeyScale = 'Scale';
  krsIniKeyFullScreen = 'FullScreen';
  krsIniKeyRender = 'Render';

type

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

    procedure LoadFromIni(aIniFile : TMemIniFile); virtual;
    {< Loads data from an already opened .ini file. }

    procedure SaveToIni(aIniFile : TMemIniFile); virtual;
    {< Saves data to an already opened .ini file. }

    constructor Create;
    destructor Destroy; override;
  end;

implementation

{ cCHXSDL3Config }

procedure cCHXSDL3Config.LoadFromIni(aIniFile : TMemIniFile);
begin
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
end;

procedure cCHXSDL3Config.ResetDefaultConfig;
begin
  Width := 0; // 0 = Renderer use max window size
  Height := 0;
  Scale := 0; // 0 = Maximize the window
  FullScreen := False;
  Render := '';
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

procedure cCHXSDL3Config.SaveToIni(aIniFile : TMemIniFile);
begin
  aIniFile.WriteInteger(krsIniSectionSDL3Engine, krsIniKeyWidth, Width);
  aIniFile.WriteInteger(krsIniSectionSDL3Engine, krsIniKeyHeight, Height);
  aIniFile.WriteInteger(krsIniSectionSDL3Engine, krsIniKeyScale, Scale);
  aIniFile.WriteBool(krsIniSectionSDL3Engine, krsIniKeyFullScreen, FullScreen);
  aIniFile.WriteString(krsIniSectionSDL3Engine, krsIniKeyRender, Render);
end;

end.
{
  This source is free software; you can redistribute it and/or modify it under
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
