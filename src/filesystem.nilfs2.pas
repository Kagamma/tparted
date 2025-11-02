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

unit FileSystem.NILFS2;

{$I configs.inc}

interface

uses
  Classes, SysUtils,
  FileSystem,
  Parted.Commons, Locale, Parted.Devices, Parted.Operations, Parted.Partitions, Parted.Logs;

type
  TPartedFileSystemNILFS2 = class(TPartedFileSystem)
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

function TPartedFileSystemNILFS2.GetSupport: TPartedFileSystemSupport;
begin
  Result := inherited;
  Result.CanFormat := ProgramExists('mkfs.nilfs2');
  Result.CanLabel := ProgramExists('nilfs-tune');
  Result.CanMove := ProgramExists('sfdisk');
  Result.CanShrink := ProgramExists('nilfs-resize');
  Result.CanGrow := ProgramExists('nilfs-resize');
  Result.Dependencies := 'nilfs-utils';
end;

procedure TPartedFileSystemNILFS2.DoCreate(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemNILFS2.DoCreate');
  // Format the new partition
  // Change label if needed
  if PartAfter^.LabelName <> '' then
    DoExec('mkfs.nilfs2', ['-L', PartAfter^.LabelName, PartAfter^.GetActualPartitionPath])
  else
    DoExec('mkfs.nilfs2', [PartAfter^.GetActualPartitionPath]);
end;

procedure TPartedFileSystemNILFS2.DoDelete(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemNILFS2.DoDelete');
end;

procedure TPartedFileSystemNILFS2.DoFormat(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemNILFS2.DoFormat');
  // Format the partition
  DoExec('mkfs.nilfs2', [PartAfter^.GetActualPartitionPath]);
end;

procedure TPartedFileSystemNILFS2.DoFlag(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
end;

procedure TPartedFileSystemNILFS2.DoLabelName(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemNILFS2.DoLabelName');
  if PartAfter^.LabelName <> PartBefore^.LabelName then
    DoExec('nilfs-tune', ['-L', PartAfter^.LabelName, PartAfter^.GetActualPartitionPath]);
end;

procedure TPartedFileSystemNILFS2.DoResize(const PartAfter, PartBefore: PPartedPartition);
var
  Path, PathMnt, S: String;

  procedure Grow;
  begin
    if PartAfter^.PartSize = PartBefore^.PartSize then
      Exit;
    DoExec('parted', [PartAfter^.Device^.Path, 'resizepart', PartAfter^.Number.ToString, PartAfter^.PartEnd.ToString + 'B']);
    Mount(Path, PathMnt);
    DoExecAsync('nilfs-resize', ['-v', '-y', Path]);
    Unmount(Path, PathMnt);
  end;

  procedure Shrink;
  begin
    if PartAfter^.PartSize = PartBefore^.PartSize then
      Exit;
    Mount(Path, PathMnt);
    DoExecAsync('nilfs-resize', ['-v', '-y', Path, BToKBFloor(PartAfter^.PartSize).ToString + 'K']);
    Unmount(Path, PathMnt);
    DoExec('sh', ['-c', Format('echo "Yes" | parted %s ---pretend-input-tty resizepart %d %dB', [PartAfter^.Device^.Path, PartAfter^.Number, PartAfter^.PartEnd])]);
  end;

begin
  WriteLog(lsInfo, 'TPartedFileSystemNILFS2.DoResize');
  // Shrink / Expand right
  Path := PartAfter^.GetActualPartitionPath;
  PathMnt := GetTempMountPath(Path);
  if PartAfter^.PartEnd > PartBefore^.PartEnd then
  begin
    inherited;
    Grow;
  end else
  if PartAfter^.PartEnd < PartBefore^.PartEnd then
  begin
    Shrink;
    inherited;
  end else
    inherited;
end;

initialization
  RegisterFileSystem(TPartedFileSystemNILFS2, ['nilfs2'], [1], [Pred(8796093022208)]);

end.