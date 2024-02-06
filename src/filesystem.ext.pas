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
  Parted.Commons, Parted.Devices, Parted.Operations, Parted.Partitions, Parted.Logs;

type
  TPartedFileSystemExt = class(TPartedFileSystem)
  public
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
    DoExec('/bin/parted', [PartAfter^.Device^.Path, 'resizepart', IntToStr(PartAfter^.Number), IntToStr(PartAfter^.PartEnd) + 'B']);
    DoExec('/bin/e2fsck', ['-f', '-y', '-v', '-C', '0', PartAfter^.GetPartitionPath]);
    DoExec('/bin/resize2fs', ['-fp', PartAfter^.GetPartitionPath]);
  end;

  procedure Shrink;
  begin
    DoExec('/bin/e2fsck', ['-f', '-y', '-v', '-C', '0', PartAfter^.GetPartitionPath]);
    DoExec('/bin/resize2fs', ['-fp', PartAfter^.GetPartitionPath, IntToStr(BToKBFloor(PartAfter^.PartSize)) + 'K']);
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

end.