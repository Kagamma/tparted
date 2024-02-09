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

unit UI.FileSystemSupport;

{$I configs.inc}

interface

uses
  SysUtils, Classes, Types, FreeVision,
  UI.Commons,
  FileSystem,
  Parted.Commons, Locale;

procedure ShowFileSystemSupportDialog;

implementation

procedure ShowFileSystemSupportDialog;

  function FeatureExists(FS: String; FeatureArray: TStringDynArray): String;
  begin
    if SToIndex(FS, FeatureArray) >= 0 then
      Result := '   ✓    '
    else
      Result := '        ';
  end;

var
  R: TRect;
  D: PDialog;
  S: PScrollBar;
  C: PUnicodeStringPtrCollection;
  L: PUIListBox;
  Str,
  FSName: String;
  I: LongInt;
begin
  R.Assign(1, 1, 79, 22);
  D := New(PDialog, Init(R, UTF8Decode(S_FileSystemSupport)));

  // Scrollbar
  D^.GetExtent(R);
  Dec(R.B.X);
  R.A.X := R.B.X - 1;
  Inc(R.A.Y, 2);
  Dec(R.B.Y);
  S := New(PScrollBar, Init(R));
  D^.Insert(S);

  // Table
  R.A.X := 1;
  Dec(R.B.X);
  L := New(PUIListBox, Init(R, 1, S));
  D^.Insert(L);

  C := New(PUnicodeStringPtrCollection, Init(8, 8));
  for FSName in FileSystemSupportArray do
  begin
    Str := Format('%s│%s│%s│%s│%s│%s│%s', [
      PadRightLimit(FSName, 12),
      FeatureExists(FSName, FileSystemFormattableArray),
      FeatureExists(FSName, FileSystemMoveArray),
      FeatureExists(FSName, FileSystemShrinkArray),
      FeatureExists(FSName, FileSystemGrowArray),
      FeatureExists(FSName, FileSystemLabelArray),
      PadRightLimit(FileSystemDependenciesMap[FSName], 20)
    ]);
    C^.Insert(GetUnicodeStr(Str));
  end;
  L^.NewList(C);

  // Header
  Dec(R.A.Y);
  R.B.Y := R.A.Y + 1;
  Str := Format(' %s│%s│%s│%s│%s│%s│%s', [
    PadRightLimit(S_FileSystem, 12),
    PadCenterLimit(S_Create, 8),
    PadCenterLimit(S_Move, 8),
    PadCenterLimit(S_Shrink, 8),
    PadCenterLimit(S_Grow, 8),
    PadCenterLimit(S_Label, 8),
    PadRightLimit(S_Dependencies, 20)
  ]);
  D^.Insert(New(PStaticText, Init(R, UTF8Decode(Str))));

  Desktop^.ExecView(D);

  Dispose(D, Done);
  Dispose(C, Done);
end;

end.