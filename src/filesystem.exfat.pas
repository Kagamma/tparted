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

unit FileSystem.ExFat;

{$I configs.inc}

interface

uses
  Classes, SysUtils,
  FileSystem,
  Parted.Commons, Parted.Devices, Parted.Operations, Parted.Partitions, Parted.Logs;

type
  TPartedFileSystemExFat = class(TPartedFileSystem)
  public
    procedure DoCreate(const PartAfter, PartBefore: PPartedPartition); override;
    procedure DoDelete(const PartAfter, PartBefore: PPartedPartition); override;
    procedure DoFormat(const PartAfter, PartBefore: PPartedPartition); override;
    procedure DoFlag(const PartAfter, PartBefore: PPartedPartition); override;
    procedure DoLabelName(const PartAfter, PartBefore: PPartedPartition); override;
    procedure DoResize(const PartAfter, PartBefore: PPartedPartition); override;
  end;

implementation

procedure TPartedFileSystemExFat.DoCreate(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemExFat.DoCreate');
  // Format the new partition
  DoExec('/bin/mkfs.exfat', [PartAfter^.GetPartitionPath]);
  // Change label if needed
  if PartAfter^.LabelName <> '' then
    DoExec('/bin/exfatlabel', [PartAfter^.GetPartitionPath, PartAfter^.LabelName]);
end;

procedure TPartedFileSystemExFat.DoDelete(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemExFat.DoDelete');
end;

procedure TPartedFileSystemExFat.DoFormat(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemExFat.DoFormat');
  // Format the partition
  DoExec('/bin/mkfs.exfat', [PartAfter^.GetPartitionPath]);
end;

procedure TPartedFileSystemExFat.DoFlag(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
end;

procedure TPartedFileSystemExFat.DoLabelName(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemExFat.DoLabelName');
  if PartAfter^.LabelName <> PartBefore^.LabelName then
    DoExec('/bin/exfatlabel', [PartAfter^.GetPartitionPath, PartAfter^.LabelName]);
end;

procedure TPartedFileSystemExFat.DoResize(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemExFat.DoResize');
end;

initialization
  RegisterFileSystem(TPartedFileSystemExFat, ['exfat'], [1], True, False, False);

end.