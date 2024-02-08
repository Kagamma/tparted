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

unit UI.Partitions.Format;

{$I configs.inc}

interface

uses
  SysUtils, Classes, FreeVision,
  UI.Commons,
  FileSystem,
  Parted.Operations,
  Parted.Commons, Locale,
  Parted.Devices,
  Parted.Partitions;

function ShowFormatDialog(const PPart: PPartedPartition; const AData: PPartedOpDataFormat): Boolean;

implementation

function ShowFormatDialog(const PPart: PPartedPartition; const AData: PPartedOpDataFormat): Boolean;
const
  HW = 19;
var
  MX, MY: LongInt;
  R: TRect;
  D: PDialog;
  CItemRoot,
  CItem: PSItem;
  I: LongInt;
  DataOld: TPartedOpDataFormat;
begin
  Result := False;
  if PPart^.IsMounted then // Prevent user to perform format operation on a mounted partition
  begin
    MsgBox(Format(S_PartitionIsMounted, [PPart^.GetPartitionPath]), nil, mfInformation + mfOKButton);
    Exit;
  end;
  if PPart^.Number = 0 then // Prevent user to perform format operation on an unallocated space
  begin
    MsgBox(Format(S_PartitionIsUnallocated, []), nil, mfInformation + mfOKButton);
    Exit;
  end;

  Desktop^.GetExtent(R);
  MX := R.B.X div 2;
  MY := R.B.Y div 2;
  R.Assign(MX - HW, MY - 9, MX + HW, MY + 7);
  D := New(PDialog, Init(R, UTF8Decode(Format(S_FormatsDialogTitle, [PPart^.GetPartitionPath]))));
  try
    D^.GetExtent(R);

    // File System
    CItemRoot := NewSItem(FileSystemFormattableArray[0], nil);
    CItem := CItemRoot;
    for I := 1 to High(FileSystemFormattableArray) do
    begin
      CItem^.Next := NewSItem(FileSystemFormattableArray[I], nil);
      CItem := CItem^.Next;
    end;
    R.Assign(HW - HW + 3, 2, HW + 3, 14);
    D^.Insert(New(PRadioButtons, Init(R, CItemRoot)));

    // Ok-Button
    R.Assign(HW + HW - 14, 11, HW + HW - 2, 13);
    D^.Insert(New(PUIButton, Init(R, UTF8Decode(S_OkButton), cmOK, bfDefault)));

    // Cancel-Button
    R.Assign(HW + HW - 14, 13, HW + HW - 2, 15);
    D^.Insert(New(PUIButton, Init(R, UTF8Decode(S_CancelButton), cmCancel, bfDefault)));

    D^.FocusNext(False);

    DataOld := AData^;
    D^.SetData(AData^);
    if Desktop^.ExecView(D) = cmOk then
    begin
      D^.GetData(AData^);
      Result := VerifyFileSystemMinSize(FileSystemFormattableArray[AData^.FileSystem], BToMBFloor(PPart^.PartSize));
    end;
  finally
    Dispose(D, Done);
  end;
end;

end.