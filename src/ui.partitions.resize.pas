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

unit UI.Partitions.Resize;

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

function ShowResizeDialog(const PPart: PPartedPartition; const AData: PPartedOpDataResize): Boolean;

implementation

function ShowResizeDialog(const PPart: PPartedPartition; const AData: PPartedOpDataResize): Boolean;
const
  HW = 22;
var
  MX, MY: LongInt;
  R: TRect;
  D: PDialog;
  CItemRoot,
  CItem: PSItem;
  I: LongInt;
  DataOld: TPartedOpDataResize;
  V: PView;
  Preceding: PUIInputNumber;
  Size: PUIInputNumber = nil;

  // Real-time correction for preceding
  function PrecedingMin(V: Int64): Int64;
  var
    Flooring: Int64;
  begin
    if (PPart^.Prev <> nil) and (PPart^.Prev^.Prev = nil) and (V < 1) then // A minimum of 1MB is need at the start of the disk
      Result := 1
    else
      Result := V;
    if ((Result <> DataOld.Preceding) and (SToIndex(PPart^.FileSystem, FileSystemMoveArray) < 0)) then
      Result := DataOld.Preceding;
  end;

  function PrecedingMax(V: Int64): Int64;
  var
    Ceiling: Int64;
  begin
    if Size <> nil then
      Ceiling := BToMBFloor(PPart^.GetPossibleExpandSize) - Size^.GetValue
    else
      Ceiling := BToMBFloor(PPart^.GetPossibleExpandSize) - BToMBFloor(PPart^.PartSizeZero);
    if V > Ceiling then
      Result := Ceiling
    else
      Result := V;
    if ((Result <> DataOld.Preceding) and (SToIndex(PPart^.FileSystem, FileSystemMoveArray) < 0)) then
      Result := DataOld.Preceding;
  end;

  // Real-time correction for size
  function SizeMin(V: Int64): Int64;
  var
    M: Int64;
  begin
    M := BToMBCeil(PPart^.PartUsed);
    if V < M then
      Result := M
    else
      Result := V;
    //Result := Min(Max(Result, GetFileSystemMinSize(PPart^.FileSystem)), GetFileSystemMaxSize(PPart^.FileSystem));
    if ((Result > DataOld.Size) and (SToIndex(PPart^.FileSystem, FileSystemGrowArray) < 0)) or
       ((Result < DataOld.Size) and (SToIndex(PPart^.FileSystem, FileSystemShrinkArray) < 0)) then
      Result := DataOld.Size;
  end;

  function SizeMax(V: Int64): Int64;
  var
    Ceiling: Int64;
  begin
    Ceiling := BToMBFloor(PPart^.GetPossibleExpandSize) - Preceding^.GetValue;
    if V > Ceiling then
      Result := Ceiling
    else
      Result := V;
    if ((Result > DataOld.Size) and (SToIndex(PPart^.FileSystem, FileSystemGrowArray) < 0)) or
       ((Result < DataOld.Size) and (SToIndex(PPart^.FileSystem, FileSystemShrinkArray) < 0)) then
      Result := DataOld.Size;
  end;

begin
  Result := False;
  if PPart^.Number = 0 then
  begin
    Exit;
  end;
  Desktop^.GetExtent(R);
  MX := R.B.X div 2;
  MY := R.B.Y div 2;
  R.Assign(MX - HW, MY - 8, MX + HW, MY + 7);
  D := New(PDialog, Init(R, Format(S_ResizeDialogTitle, [PPart^.GetPartitionPath]).ToUnicode));
  try
    D^.GetExtent(R);

    // Free space preceding
    if SToIndex(PPart^.FileSystem, FileSystemMoveArray) >= 0 then
    begin
      R.Assign(5, 3, 30, 4);
      Preceding := New(PUIInputNumber, Init(R, 16));
      Preceding^.PostfixValues := 'MGT';
      Preceding^.OnMin := @PrecedingMin;
      Preceding^.OnMax := @PrecedingMax;
      D^.Insert(Preceding);
      R.Assign(5, 2, 30, 3);
      D^.Insert(New(PLabel, Init(R, S_FreeSpacePreceding.ToUnicode, Preceding)));
    end;

    // New size
    if (SToIndex(PPart^.FileSystem, FileSystemGrowArray) >= 0) or
       (SToIndex(PPart^.FileSystem, FileSystemShrinkArray) >= 0) then
    begin
      R.Assign(5, 5, 30, 6);
      Size := New(PUIInputNumber, Init(R, 16));
      Size^.PostfixValues := 'MGT';
      Size^.OnMin := @SizeMin;
      Size^.OnMax := @SizeMax;
      D^.Insert(Size);
      R.Assign(5, 4, 30, 5);
      D^.Insert(New(PLabel, Init(R, S_NewSize.ToUnicode, Size)));

      // Total size
      R.Assign(6, 6, 30, 8);
      D^.Insert(New(PStaticText, Init(R, Format(S_MaxPossibleSpace, [BToMBFloor(PPart^.GetPossibleExpandSize)]).ToUnicode)));

      // Min possible size
      R.Assign(6, 8, 30, 10);
      D^.Insert(New(PStaticText, Init(R, Format(S_MinPossibleSpace, [BToMBFloor(PPart^.PartUsed)]).ToUnicode)));
    end;

    // Ok-Button
    R.Assign(11, 12, 23, 14);
    D^.Insert(New(PUIButton, Init(R, S_OkButton.ToUnicode, cmOK, bfDefault)));

    // Cancel-Button
    R.Assign(25, 12, 37, 14);
    D^.Insert(New(PUIButton, Init(R, S_CancelButton.ToUnicode, cmCancel, bfDefault)));

    D^.FocusNext(False);

    DataOld := AData^;
    D^.SetData(AData^);
    if Desktop^.ExecView(D) = cmOk then
    begin
      D^.GetData(AData^);
      Result := ((DataOld.Preceding <> AData^.Preceding) or (DataOld.Size <> AData^.Size)) and
                 VerifyFileSystemSize(PPart^.Device^.Table, PPart^.FileSystem, AData^.Size);
    end;
  finally
    Dispose(D, Done);
  end;
end;

end.

