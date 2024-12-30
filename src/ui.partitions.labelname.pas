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

unit UI.Partitions.LabelName;

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

function ShowLabelNameDialog(const PPart: PPartedPartition; const AData: PPartedOpDataLabel): Boolean;

implementation

function ShowLabelNameDialog(const PPart: PPartedPartition; const AData: PPartedOpDataLabel): Boolean;
const
  HW = 22;
var
  MX, MY: LongInt;
  R: TRect;
  D: PDialog;
  I: LongInt;
  V: PView;
  DataOld: TPartedOpDataLabel;
begin
  Result := False;

  // The following code should not run because the label button should be disabled for this case
  if PPart^.Number = 0 then
  begin
    MsgBox(Format(S_PartitionIsUnallocated, []), nil, mfInformation + mfOKButton);
    Exit;
  end;

  Desktop^.GetExtent(R);
  MX := R.B.X div 2;
  MY := R.B.Y div 2;
  R.Assign(MX - HW, MY - 5, MX + HW, MY + 4);
  D := New(PDialog, Init(R, Format(S_InputLabelTitle, [PPart^.GetPartitionPath]).ToUnicode));
  try
    D^.GetExtent(R);

    // Label
    if SToIndex(PPart^.FileSystem, FileSystemLabelArray) >= 0 then
    begin
      R.Assign(3, 2, 40, 3);
      V := New(PUIInputLine, Init(R, 30));
      D^.Insert(V);
      R.Assign(3, 1, 20, 2);
      D^.Insert(New(PLabel, Init(R, S_Label.ToUnicode, V)));
    end;

    // Name
    R.Assign(3, 4, 40, 5);
    V := New(PUIInputLine, Init(R, 30));
    D^.Insert(V);
    R.Assign(3, 3, 20, 4);
    D^.Insert(New(PLabel, Init(R, S_Name.ToUnicode, V)));

    // Ok-Button
    R.Assign(15, 6, 27, 8);
    D^.Insert(New(PUIButton, Init(R, S_OkButton.ToUnicode, cmOK, bfDefault)));

    // Cancel-Button
    R.Assign(28, 6, 40, 8);
    D^.Insert(New(PUIButton, Init(R, S_CancelButton.ToUnicode, cmCancel, bfDefault)));

    D^.FocusNext(False);

    DataOld := AData^;
    D^.SetData(AData^);
    if Desktop^.ExecView(D) = cmOk then
    begin
      D^.GetData(AData^);
      Result := (DataOld.LabelName <> AData^.LabelName) or (DataOld.Name <> AData^.Name);
    end;
  finally
    Dispose(D, Done);
  end;
end;

end.
