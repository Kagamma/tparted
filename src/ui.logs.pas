{
tparted
Copyright (C) 2024-2024 kagamma

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
  Parted.Commons,
  Parted.Logs;

procedure ShowLogDialog;

implementation

procedure ShowLogDialog;
var
  R: TRect;
  D: PDialog;
  S: PScrollBar;
  C: PUnicodeStringPtrCollection;
  L: PUIListBox;
  Str: String;
begin
  Desktop^.GetExtent(R);
  R.Grow(-1, -1);

  D := New(PDialog, Init(R, UTF8Decode(S_Logs)));

  // Scrollbar
  D^.GetExtent(R);
  Dec(R.B.X);
  R.A.X := R.B.X - 1;
  Inc(R.A.Y);
  Dec(R.B.Y);
  S := New(PScrollBar, Init(R));
  D^.Insert(S);

  R.A.X := 1;
  Dec(R.B.X);
  L := New(PUIListBox, Init(R, 1, S));
  D^.Insert(L);

  C := New(PUnicodeStringPtrCollection, Init(8, 8));
  for Str in Log do
  begin
    C^.Insert(GetUnicodeStr(Str));
  end;
  L^.NewList(C);
  L^.FocusItem(Pred(Log.Count));

  Desktop^.ExecView(D);

  Dispose(D, Done);
  Dispose(C, Done);
end;

end.