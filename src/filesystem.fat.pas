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

unit FileSystem.Fat;

{$I configs.inc}

interface

uses
  Classes, SysUtils,
  FileSystem,
  Parted.Commons, Parted.Devices, Parted.Operations, Parted.Partitions, Parted.Logs;

type
  TPartedFileSystemFat = class(TPartedFileSystem)
  public
    function GetFatSize(const Part: PPartedPartition): String;
    procedure DoCreate(const PartAfter, PartBefore: PPartedPartition); override;
    procedure DoDelete(const PartAfter, PartBefore: PPartedPartition); override;
    procedure DoFormat(const PartAfter, PartBefore: PPartedPartition); override;
    procedure DoFlag(const PartAfter, PartBefore: PPartedPartition); override;
    procedure DoLabelName(const PartAfter, PartBefore: PPartedPartition); override;
    procedure DoResize(const PartAfter, PartBefore: PPartedPartition); override;
  end;

implementation

function TPartedFileSystemFat.GetFatSize(const Part: PPartedPartition): String;
begin
  if Part^.FileSystem = 'fat32' then
    Result := '32'
  else
    Result := '16';
end;

procedure TPartedFileSystemFat.DoCreate(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemFat.DoCreate');
  // Format the new partition
  DoExec('/bin/mkfs.fat', ['-F', Self.GetFatSize(PartAfter), PartAfter^.GetPartitionPath]);
  // Change label if needed
  if PartAfter^.LabelName <> '' then
    DoExec('/bin/fatlabel', [PartAfter^.GetPartitionPath, PartAfter^.LabelName]);
end;

procedure TPartedFileSystemFat.DoDelete(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemFat.DoDelete');
end;

procedure TPartedFileSystemFat.DoFormat(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemFat.DoFormat');
  // Format the partition
  DoExec('/bin/mkfs.fat', ['-F', Self.GetFatSize(PartAfter), PartAfter^.GetPartitionPath]);
end;

procedure TPartedFileSystemFat.DoFlag(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
end;

procedure TPartedFileSystemFat.DoLabelName(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemFat.DoLabelName');
  if PartAfter^.LabelName <> PartBefore^.LabelName then
    DoExec('/bin/fatlabel', [PartAfter^.GetPartitionPath, PartAfter^.LabelName]);
end;

procedure TPartedFileSystemFat.DoResize(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemFat.DoResize');
end;

initialization
  RegisterFileSystem(TPartedFileSystemFat, ['fat16', 'fat32'], [1, 1], True, False, False);

end.