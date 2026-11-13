{ Auxiliar methods.

  This file is part of ucCHXSDL3Renderer.

  (C) 2026 Chixpy https://github.com/Chixpy
}
function CHXSDL3IsFinite(const Value : CFloat) : Boolean; inline;
{< Check that a float is neither NaN nor infinite. }
begin
  Result := not (IsNan(Value) or IsInfinite(Value));
end;

function cCHXSDL3Renderer.GetRenderBounds(
  out MinX, MinY, MaxX, MaxY : CFloat) : Boolean;
var
  W, H : CInt;
  Mode : TSDL_RendererLogicalPresentation;
begin
  MinX := 0; MinY := 0; MaxX := 0; MaxY := 0;

  // Logical coordinates are the natural drawing space.
  W := 0; H := 0;
  if SDL_GetRenderLogicalPresentation(SDLRenderer, @W, @H, @Mode)
    and (W > 0) and (H > 0) then
  begin
    MaxX := W; MaxY := H;
    Exit(True);
  end;

  // When logical presentation is disabled SDL reports 0x0. Fall back to the
  // real output size, which is the coordinate space in that case.
  W := 0; H := 0;
  if SDL_GetRenderOutputSize(SDLRenderer, @W, @H)
    and (W > 0) and (H > 0) then
  begin
    MaxX := W; MaxY := H;
    Exit(True);
  end;

  Result := False;
end;

function cCHXSDL3Renderer.IsValidArrayRange(
  const ArrLength, idxFirst : CInt; var Count : CInt;
  const LineNumber, FuncName : String) : Boolean;
var
  MaxCount : CInt;
begin
  if ArrLength <= 0 then
  begin
    if Count = 0 then
      Exit(True) // Empty array but Count is 0 too
    else
    begin
      SDL_SetError('%s(%s) %s: Empty array and Count <> 0',
        [PAnsiChar({$I %FILE%}), PAnsiChar(LineNumber), PAnsiChar(FuncName)]);
      Count := -1;
      Exit(False);
    end;
  end;

  if (idxFirst < 0) or (idxFirst >= ArrLength) or (Count < 0) then
  begin
    SDL_SetError('%s(%s) %s: (Index(%d) not in [0..%d]) or (Count(%d) < 0)',
      [PAnsiChar({$I %FILE%}), PAnsiChar(LineNumber), PAnsiChar(FuncName),
      idxFirst, ArrLength - 1, Count]);
    Count := -1;
    Exit(False);
  end;

  MaxCount := ArrLength - idxFirst; // It's at least 1

  if Count = 0 then
    Count := MaxCount
  else if Count > MaxCount then
  begin
    SDL_SetError('%s(%s) %s: (Index(%d) + Count(%d)) > Array Length(%d)',
      [PAnsiChar({$I %FILE%}), PAnsiChar(LineNumber), PAnsiChar(FuncName),
      idxFirst, Count, ArrLength]);
    Count := MaxCount;
    Exit(False);
  end;

  Result := True;
end;
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

