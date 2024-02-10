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

unit FileSystem.Ext;

{$I configs.inc}

interface

uses
  Classes, SysUtils,
  FileSystem,
  Parted.Commons, Locale, Parted.Devices, Parted.Operations, Parted.Partitions, Parted.Logs;

type
  TPartedFileSystemExt = class(TPartedFileSystem)
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

uses
  UI.Commons;

function TPartedFileSystemExt.GetSupport: TPartedFileSystemSupport;
begin
  inherited;
  Result.CanFormat := FileExists('/bin/mkfs.ext2') and FileExists('/bin/mkfs.ext3') and FileExists('/bin/mkfs.ext4');
  Result.CanLabel := FileExists('/bin/e2label');
  Result.CanMove := FileExists('/bin/sfdisk');
  Result.CanShrink := FileExists('/bin/resize2fs') and FileExists('/bin/e2fsck');
  Result.CanGrow := FileExists('/bin/resize2fs') and FileExists('/bin/e2fsck');
  Result.Dependencies := 'e2fsprogs';
end;

procedure TPartedFileSystemExt.DoCreate(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemExt.DoCreate');
  // Format the new partition
  DoExec('/bin/mkfs.' + PartAfter^.FileSystem, [PartAfter^.GetPartitionPath]);
  // Change label if needed
  if PartAfter^.LabelName <> '' then
    DoExec('/bin/e2label', [PartAfter^.GetPartitionPath, PartAfter^.LabelName]);
end;

procedure TPartedFileSystemExt.DoDelete(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemExt.DoDelete');
end;

procedure TPartedFileSystemExt.DoFormat(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemExt.DoFormat');
  // Format the partition
  DoExec('/bin/mkfs.' + PartAfter^.FileSystem, [PartAfter^.GetPartitionPath]);
end;

procedure TPartedFileSystemExt.DoFlag(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
end;

procedure TPartedFileSystemExt.DoLabelName(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemExt.DoLabelName');
  if PartAfter^.LabelName <> PartBefore^.LabelName then
    DoExec('/bin/e2label', [PartAfter^.GetPartitionPath, PartAfter^.LabelName]);
end;

procedure TPartedFileSystemExt.DoResize(const PartAfter, PartBefore: PPartedPartition);

  procedure Grow;
  begin
    DoExec('/bin/parted', [PartAfter^.Device^.Path, 'resizepart', PartAfter^.Number.ToString, PartAfter^.PartEnd.ToString + 'B']);
    DoExec('/bin/e2fsck', ['-f', '-y', '-v', '-C', '0', PartAfter^.GetPartitionPath]);
    DoExec('/bin/resize2fs', ['-fp', PartAfter^.GetPartitionPath]);
  end;

  procedure Shrink;
  begin
    DoExec('/bin/e2fsck', ['-f', '-y', '-v', '-C', '0', PartAfter^.GetPartitionPath]);
    DoExec('/bin/resize2fs', ['-fp', PartAfter^.GetPartitionPath, BToKBFloor(PartAfter^.PartSize).ToString + 'K']);
    DoExec('/bin/sh', ['-c', Format('echo "Yes" | parted %s ---pretend-input-tty resizepart %d %dB', [PartAfter^.Device^.Path, PartAfter^.Number, PartAfter^.PartEnd])]);
  end;

begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemExt.DoResize');
  // Shrink / Expand right
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
  RegisterFileSystem(TPartedFileSystemExt, ['ext2', 'ext3', 'ext4'], [1, 1, 1]);

end.