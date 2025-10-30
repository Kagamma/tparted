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

unit UI.Partitions.Unmount;

{$I configs.inc}

interface

uses
  SysUtils, Classes, FreeVision,
  UI.Commons,
  Parted.Logs,
  Parted.Commons, Locale,
  Parted.Devices,
  Parted.Partitions;

function ShowUnmountDialog(const PPart: PPartedPartition): Boolean;

implementation

function ShowUnmountDialog(const PPart: PPartedPartition): Boolean;
begin
  Result := False;
  try
    LoadingStart(Format(S_PartitionUnmounting, [PPart^.GetPartitionPath]));
    QueryPartitionUnmount(PPart^);
    LoadingStop;
    MsgBox(Format(S_PartitionUnmounted, [PPart^.GetPartitionPath]), nil, mfInformation + mfOKButton);
    Result := True;
  except
    on E: Exception do
    begin
      LoadingStop;
      WriteLog(lsError, E.Message);
      MsgBox(E.Message, nil, mfError + mfOKButton);
    end;
  end;
end;

end.