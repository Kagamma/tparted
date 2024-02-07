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

unit FileSystem.Swap;

{$I configs.inc}

interface

uses
  Classes, SysUtils,
  FileSystem,
  Parted.Commons, Parted.Devices, Parted.Operations, Parted.Partitions, Parted.Logs;

type
  TPartedFileSystemSwap = class(TPartedFileSystem)
  public
    procedure DoCreate(const PartAfter, PartBefore: PPartedPartition); override;
    procedure DoDelete(const PartAfter, PartBefore: PPartedPartition); override;
    procedure DoFormat(const PartAfter, PartBefore: PPartedPartition); override;
    procedure DoFlag(const PartAfter, PartBefore: PPartedPartition); override;
    procedure DoLabelName(const PartAfter, PartBefore: PPartedPartition); override;
    procedure DoResize(const PartAfter, PartBefore: PPartedPartition); override;
  end;

implementation

procedure TPartedFileSystemSwap.DoCreate(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemSwap.DoCreate');
  // Format the new partition
  DoExec('/bin/mkswap', [PartAfter^.GetPartitionPath]);
end;

procedure TPartedFileSystemSwap.DoDelete(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemSwap.DoDelete');
end;

procedure TPartedFileSystemSwap.DoFormat(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemSwap.DoFormat');
  // Format the partition
  DoExec('/bin/mkswap', [PartAfter^.GetPartitionPath]);
end;

procedure TPartedFileSystemSwap.DoFlag(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
end;

procedure TPartedFileSystemSwap.DoLabelName(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemSwap.DoLabelName');
end;

procedure TPartedFileSystemSwap.DoResize(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemSwap.DoResize');
end;

initialization
  RegisterFileSystem(TPartedFileSystemSwap, ['linux-swap'], [1], True, False, False);

end.