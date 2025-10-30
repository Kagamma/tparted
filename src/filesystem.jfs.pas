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

unit FileSystem.Jfs;

{$I configs.inc}

interface

uses
  Classes, SysUtils,
  FileSystem,
  Parted.Commons, Locale, Parted.Devices, Parted.Operations, Parted.Partitions, Parted.Logs;

type
  TPartedFileSystemJfs = class(TPartedFileSystem)
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

function TPartedFileSystemJfs.GetSupport: TPartedFileSystemSupport;
begin
  Result := inherited;
  Result.CanFormat := ProgramExists('mkfs.jfs');
  Result.CanLabel := ProgramExists('jfs_tune');
  Result.CanMove := ProgramExists('sfdisk');
  Result.CanShrink := False;
  Result.CanGrow := ProgramExists('jfs_fsck');
  Result.Dependencies := 'jfsutils';
end;

procedure TPartedFileSystemJfs.DoCreate(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemJfs.DoCreate');
  // Format the new partition
  DoExec('mkfs.jfs', ['-q', PartAfter^.GetActualPartitionPath]);
  // Change label if needed
  if PartAfter^.LabelName <> '' then
    DoExec('jfs_tune', ['-L', PartAfter^.LabelName, PartAfter^.GetActualPartitionPath]);
end;

procedure TPartedFileSystemJfs.DoDelete(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemJfs.DoDelete');
end;

procedure TPartedFileSystemJfs.DoFormat(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemJfs.DoFormat');
  // Format the partition
  DoExec('mkfs.jfs', ['-q', PartAfter^.GetActualPartitionPath]);
end;

procedure TPartedFileSystemJfs.DoFlag(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
end;

procedure TPartedFileSystemJfs.DoLabelName(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemJfs.DoLabelName');
  if PartAfter^.LabelName <> '' then
    DoExec('jfs_tune', ['-L', PartAfter^.LabelName, PartAfter^.GetActualPartitionPath]);
end;

procedure TPartedFileSystemJfs.DoResize(const PartAfter, PartBefore: PPartedPartition);
var
  Path, PathMnt, S: String;

  procedure Grow;
  begin
    if PartAfter^.PartSize = PartBefore^.PartSize then
      Exit;
    DoExec('jfs_fsck', ['-f', Path]);
    DoExec('parted', [PartAfter^.Device^.Path, 'resizepart', PartAfter^.Number.ToString, PartAfter^.PartEnd.ToString + 'B']);
    ExecSystem(Format('mkdir -p "%s" > /dev/null', [PathMnt]));
    ExecSystem(Format('mount -v -t jfs "%s" "%s" > /dev/null', [Path, PathMnt]));
    ExecSystem(Format('mount -v -t jfs -o remount,resize "%s" "%s" > /dev/null', [Path, PathMnt]));
    ExecSystem(Format('umount -v "%s" > /dev/null', [Path]));
    ExecSystem(Format('rm -d "%s" > /dev/null', [PathMnt]));
  end;

begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemJfs.DoResize');
  // Shrink / Expand right
  Path := PartAfter^.GetActualPartitionPath;
  PathMnt := GetTempMountPath(Path);
  if PartAfter^.PartEnd > PartBefore^.PartEnd then
  begin
    Grow;
  end;
end;

initialization
  RegisterFileSystem(TPartedFileSystemJfs, ['jfs'], [16], [Pred(34359738368)]);

end.