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

unit UI.Partitions.Info;

{$I configs.inc}

interface

uses
  SysUtils, Classes, FreeVision,
  UI.Commons,
  Parted.Commons,
  Parted.Devices,
  Parted.Partitions;

// Shows a dialog display various additional info for a partition
function ShowPartitionInfoDialog(const PPart: PPartedPartition): Boolean;

implementation

function ShowPartitionInfoDialog(const PPart: PPartedPartition): Boolean;
const
  HW = 28;
var
  R: TRect;
  D: PDialog;
  S: String;
  MX, MY: LongInt;
begin
  Result := True;
  if PPart = nil then
    Exit;
  Desktop^.GetExtent(R);
  MX := R.B.X div 2;
  MY := R.B.Y div 2;
  R.Assign(MX - HW, MY - 10, MX + HW, MY + 9);
  D := New(PDialog, Init(R, UTF8Decode(PPart^.GetPartitionPathForDisplay)));
  try
    D^.GetExtent(R);

    S := Format(S_PartitionFileSystem, [PPart^.FileSystem]) + #13 +
      Format(S_PartitionLabel, [PPart^.LabelName]) + #13 +
      Format(S_PartitionName, [PPart^.Name]) + #13 +
      Format(S_PartitionUUID, [PPart^.UUID]) + #13 +
      Format(S_PartitionType, [PPart^.Kind]) + #13 +
      Format(S_PartitionSize, [SizeByteString(PPart^.PartSize), SizeString(PPart^.PartSize)]) + #13 +
      Format(S_PartitionUsed, [SizeByteString(PPart^.PartUsed), SizeString(PPart^.PartUsed)]) + #13 +
      Format(S_PartitionFree, [SizeByteString(PPart^.PartFree), SizeString(PPart^.PartFree)]) + #13 +
      Format(S_PartitionStart, [SizeByteString(PPart^.PartStart), SizeString(PPart^.PartStart)]) + #13 +
      Format(S_PartitionEnd, [SizeByteString(PPart^.PartEnd), SizeString(PPart^.PartEnd)]) + #13 +
      Format(S_PartitionFlags, [SAToS(PPart^.Flags, ',')]) + #13 +
      Format(S_PartitionMount, [PPart^.MountPoint]);
    R.Assign(3, 2, R.B.X - 1, 14);
    D^.Insert(New(PStaticText, Init(R, UTF8Decode(S))));

    R.Assign(HW - 7, R.A.Y + 14, HW + 7, R.A.Y + 16);
    D^.Insert(New(PButton, Init(R, UTF8Decode(S_CloseButton), cmCancel, bfDefault)));
    Desktop^.ExecView(D);
  finally
    Dispose(D, Done);
  end;
end;

end.
