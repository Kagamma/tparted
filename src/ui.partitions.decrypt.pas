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

unit UI.Partitions.Decrypt;

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

function ShowDecryptDialog(const PPart: PPartedPartition): Boolean;

implementation

type
  TDecryptData = record
    Passphrase: UnicodeString;
  end;

function ShowDecryptDialog(const PPart: PPartedPartition): Boolean;
const
  HW = 22;
var
  MX, MY: LongInt;
  R: TRect;
  D: PDialog;
  V: PUIInputLine;
  Data: TDecryptData;
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
  D := New(PDialog, Init(R, Format(S_DecryptPartition, [PPart^.GetPartitionPath]).ToUnicode));
  try
    D^.GetExtent(R);

    // Label
    R.Assign(3, 3, 40, 4);
    V := New(PUIInputLine, Init(R, 30));
    V^.IsPassword := True;
    D^.Insert(V);
    R.Assign(3, 2, 20, 3);
    D^.Insert(New(PLabel, Init(R, S_EnterPassphrase.ToUnicode, V)));

    // Ok-Button
    R.Assign(15, 6, 27, 8);
    D^.Insert(New(PUIButton, Init(R, S_OkButton.ToUnicode, cmOK, bfDefault)));

    // Cancel-Button
    R.Assign(28, 6, 40, 8);
    D^.Insert(New(PUIButton, Init(R, S_CancelButton.ToUnicode, cmCancel, bfDefault)));

    D^.FocusNext(False);

    if Desktop^.ExecView(D) = cmOk then
    begin
      D^.GetData(Data);
      if not PPart^.Decrypt(Data.Passphrase) then
        MsgBox('Decrypt ' + PPart^.GetPartitionPath + ' failed!', nil, mfError + mfOKButton)
      else
        Result := True;
    end;
  finally
    Dispose(D, Done);
  end;
end;

end.
