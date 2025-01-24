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

unit UI.Devices.PTable;

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

function ShowPTableDialog(var ASelected: String): Boolean;

implementation

function ShowPTableDialog(var ASelected: String): Boolean;
const
  HW = 21;
var
  MX, MY: LongInt;
  R: TRect;
  D: PDialog;
  CItemRoot,
  CItem: PSItem;
  RD: PRadioButtons;
begin
  Result := False;

  Desktop^.GetExtent(R);
  MX := R.B.X div 2;
  MY := R.B.Y div 2;
  R.Assign(MX - HW, MY - 4, MX + HW, MY + 4);
  D := New(PDialog, Init(R, S_SelectPartitionTable.ToUnicode));
  try
    D^.GetExtent(R);

    // File System
    Assert(Length(PTableNames) = 2, 'PTableNames''s length must equal to 2');
    CItemRoot := NewSItem(PTableNames[0], NewSItem(PTableNames[1], nil));

    R.Assign(HW - HW + 3, 2, HW + 3, 6);
    RD := New(PRadioButtons, Init(R, CItemRoot));
    D^.Insert(RD);

    // Ok-Button
    R.Assign(HW + HW - 14, 3, HW + HW - 2, 5);
    D^.Insert(New(PUIButton, Init(R, S_OkButton.ToUnicode, cmOK, bfDefault)));

    // Cancel-Button
    R.Assign(HW + HW - 14, 5, HW + HW - 2, 7);
    D^.Insert(New(PUIButton, Init(R, S_CancelButton.ToUnicode, cmCancel, bfDefault)));

    D^.FocusNext(False);

    Result := Desktop^.ExecView(D) = cmOk;

    ASelected := PTableNames[RD^.Value];
  finally
    Dispose(D, Done);
  end;
end;

end.

end.