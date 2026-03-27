{
tparted
Copyright (C) 2024-2026 kagamma

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
  Parted.Commons, Locale,
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
  MX, MY: LongInt;
  FS: String;
  I: Byte;
begin
  Result := True;
  if PPart = nil then
    Exit;
  Desktop^.GetExtent(R);
  MX := R.B.X div 2;
  MY := R.B.Y div 2;
  R.Assign(MX - HW, MY - 10, MX + HW, MY + 9);
  D := New(PDialog, Init(R, PPart^.GetPartitionPathForDisplay.ToUnicode));
  try
    D^.GetExtent(R);
    if PPart^.IsEncrypted and PPart^.IsDecrypted then
      FS := PPart^.FileSystem + '[E]'
    else
      FS := PPart^.FileSystem;

    I := 2;
    R.Assign(3, I, R.B.X - 1, I + 1); Inc(I);
    D^.Insert(New(PStaticText, Init(R, Format(S_PartitionFileSystem, [FS]).ToUnicode)));
    R.Assign(3, I, R.B.X - 1, I + 1); Inc(I);
    D^.Insert(New(PStaticText, Init(R, Format(S_PartitionLabel, [PPart^.LabelName]).ToUnicode)));
    R.Assign(3, I, R.B.X - 1, I + 1); Inc(I);
    D^.Insert(New(PStaticText, Init(R, Format(S_PartitionName, [PPart^.Name]).ToUnicode)));
    R.Assign(3, I, R.B.X - 1, I + 1); Inc(I);
    D^.Insert(New(PStaticText, Init(R, Format(S_PartitionUUID, [PPart^.UUID]).ToUnicode)));
    R.Assign(3, I, R.B.X - 1, I + 1); Inc(I);
    D^.Insert(New(PStaticText, Init(R, Format(S_PartitionPARTUUID, [PPart^.PARTUUID]).ToUnicode)));
    R.Assign(3, I, R.B.X - 1, I + 1); Inc(I);
    D^.Insert(New(PStaticText, Init(R, Format(S_PartitionType, [PPart^.Kind]).ToUnicode)));
    R.Assign(3, I, R.B.X - 1, I + 1); Inc(I);
    D^.Insert(New(PStaticText, Init(R, Format(S_PartitionSize, [SizeByteString(PPart^.PartSize), SizeString(PPart^.PartSize)]).ToUnicode)));
    R.Assign(3, I, R.B.X - 1, I + 1); Inc(I);
    D^.Insert(New(PStaticText, Init(R, Format(S_PartitionUsed, [SizeByteString(PPart^.PartUsed), SizeString(PPart^.PartUsed)]).ToUnicode)));
    R.Assign(3, I, R.B.X - 1, I + 1); Inc(I);
    D^.Insert(New(PStaticText, Init(R, Format(S_PartitionFree, [SizeByteString(PPart^.PartFree), SizeString(PPart^.PartFree)]).ToUnicode)));
    R.Assign(3, I, R.B.X - 1, I + 1); Inc(I);
    D^.Insert(New(PStaticText, Init(R, Format(S_PartitionStart, [SizeByteString(PPart^.PartStart), SizeString(PPart^.PartStart)]).ToUnicode)));
    R.Assign(3, I, R.B.X - 1, I + 1); Inc(I);
    D^.Insert(New(PStaticText, Init(R, Format(S_PartitionEnd, [SizeByteString(PPart^.PartEnd), SizeString(PPart^.PartEnd)]).ToUnicode)));
    R.Assign(3, I, R.B.X - 1, I + 1); Inc(I);
    D^.Insert(New(PStaticText, Init(R, Format(S_PartitionFlags, [SAToS(PPart^.Flags, ',')]).ToUnicode)));
    R.Assign(3, I, R.B.X - 1, I);
    D^.Insert(New(PStaticText, Init(R, Format(S_PartitionMount, [PPart^.MountPoint]).ToUnicode)));

    R.Assign(HW - 7, R.A.Y + 14, HW + 7, R.A.Y + 16);
    D^.Insert(New(PButton, Init(R, S_CloseButton.ToUnicode, cmCancel, bfDefault)));
    Desktop^.ExecView(D);
  finally
    Dispose(D, Done);
  end;
end;

end.
