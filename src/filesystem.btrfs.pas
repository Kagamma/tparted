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

unit FileSystem.BTRFS;

{$I configs.inc}

interface

uses
  Classes, SysUtils, Unix,
  FileSystem,
  Parted.Commons, Locale, Parted.Devices, Parted.Operations, Parted.Partitions, Parted.Logs;

type
  TPartedFileSystemBTRFS = class(TPartedFileSystem)
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

function TPartedFileSystemBTRFS.GetSupport: TPartedFileSystemSupport;
begin
  inherited;
  Result.CanFormat := FileExists('/bin/mkfs.btrfs');
  Result.CanLabel := FileExists('/bin/btrfs');
  Result.CanMove := FileExists('/bin/sfdisk');
  Result.CanShrink := FileExists('/bin/btrfs');
  Result.CanGrow := FileExists('/bin/btrfs');
  Result.Dependencies := 'btrfs-progs';
end;

procedure TPartedFileSystemBTRFS.DoCreate(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemBTRFS.DoCreate');
  // Format the new partition
  DoExec('/bin/mkfs.btrfs', ['-f', PartAfter^.GetPartitionPath]);
  // Change label if needed
  if PartAfter^.LabelName <> '' then
    DoExec('/bin/btrfs', ['filesystem', 'label', PartAfter^.GetPartitionPath, PartAfter^.LabelName]);
end;

procedure TPartedFileSystemBTRFS.DoDelete(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemBTRFS.DoDelete');
end;

procedure TPartedFileSystemBTRFS.DoFormat(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemBTRFS.DoFormat');
  // Format the partition
  DoExec('/bin/mkfs.btrfs', ['-f', PartAfter^.GetPartitionPath]);
end;

procedure TPartedFileSystemBTRFS.DoFlag(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
end;

procedure TPartedFileSystemBTRFS.DoLabelName(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemBTRFS.DoLabelName');
  if PartAfter^.LabelName <> '' then
    DoExec('/bin/btrfs', ['filesystem', 'label', PartAfter^.GetPartitionPath, PartAfter^.LabelName]);
end;

procedure TPartedFileSystemBTRFS.DoResize(const PartAfter, PartBefore: PPartedPartition);
var
  Path, PathMnt, S: String;

  procedure Grow;
  begin
    DoExec('/bin/btrfs', ['check', PartAfter^.GetPartitionPath]);
    DoExec('/bin/parted', [PartAfter^.Device^.Path, 'resizepart', PartAfter^.Number.ToString, PartAfter^.PartEnd.ToString + 'B']);
    Mount(Path, PathMnt);
    DoExec('/bin/btrfs', ['filesystem', 'resize', 'max', PathMnt]);
    Unmount(Path, PathMnt);
  end;

  procedure Shrink;
  begin
    DoExec('/bin/btrfs', ['check', PartAfter^.GetPartitionPath]);
    Mount(Path, PathMnt);
    DoExec('/bin/btrfs', ['filesystem', 'resize', BToKBFloor(PartAfter^.PartSize).ToString + 'K', PathMnt]);
    Unmount(Path, PathMnt);
    DoExec('/bin/sh', ['-c', Format('echo "Yes" | parted %s ---pretend-input-tty resizepart %d %dB', [PartAfter^.Device^.Path, PartAfter^.Number, PartAfter^.PartEnd])]);
  end;

begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemBTRFS.DoResize');
  // Shrink / Expand right
  Path := PartAfter^.GetPartitionPath;
  PathMnt := GetTempMountPath(Path);
  if PartAfter^.PartEnd > PartBefore^.PartEnd then
  begin
    Grow;
  end else
  if PartAfter^.PartEnd < PartBefore^.PartEnd then
  begin
    Shrink;
  end;
end;

initialization
  RegisterFileSystem(TPartedFileSystemBTRFS, ['btrfs'], [256]);

end.