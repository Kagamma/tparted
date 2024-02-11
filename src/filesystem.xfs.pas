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

unit FileSystem.Xfs;

{$I configs.inc}

interface

uses
  Classes, SysUtils,
  FileSystem,
  Parted.Commons, Locale, Parted.Devices, Parted.Operations, Parted.Partitions, Parted.Logs;

type
  TPartedFileSystemXfs = class(TPartedFileSystem)
  public
    function GetSupport: TPartedFileSystemSupport; override;

    procedure DoCreate(const PartAfter, PartBefore: PPartedPartition); override;
    procedure DoDelete(const PartAfter, PartBefore: PPartedPartition); override;
    procedure DoFormat(const PartAfter, PartBefore: PPartedPartition); override;
    procedure DoFlag(const PartAfter, PartBefore: PPartedPartition); override;
    procedure DoLabelName(const PartAfter, PartBefore: PPartedPartition); override;
    procedure DoResize(const PartAfter, PartBefore: PPartedPartition); override;
  end;

implementation

function TPartedFileSystemXfs.GetSupport: TPartedFileSystemSupport;
begin
  inherited;
  Result.CanFormat := FileExists('/bin/mkfs.xfs');
  Result.CanLabel := FileExists('/bin/xfs_admin');
  Result.CanMove := FileExists('/bin/sfdisk');
  Result.CanShrink := False;
  Result.CanGrow := FileExists('/bin/xfs_growfs') and FileExists('/bin/xfs_repair');
  Result.Dependencies := 'xfsprogs';
end;

procedure TPartedFileSystemXfs.DoCreate(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemXfs.DoCreate');
  // Format the new partition
  DoExec('/bin/mkfs.xfs', ['-f', PartAfter^.GetPartitionPath]);
  // Change label if needed
  if PartAfter^.LabelName <> '' then
    DoExec('/bin/xfs_admin', ['-L', PartAfter^.LabelName, PartAfter^.GetPartitionPath]);
end;

procedure TPartedFileSystemXfs.DoDelete(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemXfs.DoDelete');
end;

procedure TPartedFileSystemXfs.DoFormat(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemXfs.DoFormat');
  // Format the partition
  DoExec('/bin/mkfs.xfs', ['-f', PartAfter^.GetPartitionPath]);
end;

procedure TPartedFileSystemXfs.DoFlag(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
end;

procedure TPartedFileSystemXfs.DoLabelName(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemXfs.DoLabelName');
  if PartAfter^.LabelName <> '' then
    DoExec('/bin/xfs_admin', ['-L', PartAfter^.LabelName, PartAfter^.GetPartitionPath]);
end;

procedure TPartedFileSystemXfs.DoResize(const PartAfter, PartBefore: PPartedPartition);
var
  Path, PathMnt, S: String;

  procedure Grow;
  begin
    DoExec('/bin/xfs_repair', ['-v', PartAfter^.GetPartitionPath]);
    DoExec('/bin/parted', [PartAfter^.Device^.Path, 'resizepart', PartAfter^.Number.ToString, PartAfter^.PartEnd.ToString + 'B']);
    Mount(Path, PathMnt);
    DoExec('/bin/xfs_growfs', [PathMnt]);
    Unmount(Path, PathMnt);
  end;

begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemXfs.DoResize');
  // Shrink / Expand right
  Path := PartAfter^.GetPartitionPath;
  PathMnt := GetTempMountPath(Path);
  if PartAfter^.PartEnd > PartBefore^.PartEnd then
  begin
    Grow;
  end;
end;

initialization
  RegisterFileSystem(TPartedFileSystemXfs, ['xfs'], [300]);

end.