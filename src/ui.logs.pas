{
tparted
Copyright (C) 2024-2025 kagamma

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
}

unit UI.Logs;

{$I configs.inc}

interface

uses
  SysUtils, Classes, FreeVision,
  UI.Commons,
  Parted.Commons, Locale,
  Parted.Logs;

procedure ShowLogDialog;

implementation

procedure ShowLogDialog;
var
  R: TRect;
  W: PEditWindow;
  Str: String;
begin
  Desktop^.GetExtent(R);
  R.Grow(-1, -1);

  W := New(PEditWindow, Init(R, LOG_PATH.ToUnicode, wnNoNumber));
  W^.Editor^.ScrollTo(0, $1FFFFFFF);

  Desktop^.Insert(W);
end;

end.