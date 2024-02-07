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

unit FileSystem.F2FS;

{$I configs.inc}

interface

uses
  Classes, SysUtils,
  FileSystem,
  Parted.Commons, Parted.Devices, Parted.Operations, Parted.Partitions, Parted.Logs;

type
  TPartedFileSystemF2FS = class(TPartedFileSystem)
  public
    procedure DoCreate(const PartAfter, PartBefore: PPartedPartition); override;
    procedure DoDelete(const PartAfter, PartBefore: PPartedPartition); override;
    procedure DoFormat(const PartAfter, PartBefore: PPartedPartition); override;
    procedure DoFlag(const PartAfter, PartBefore: PPartedPartition); override;
    procedure DoLabelName(const PartAfter, PartBefore: PPartedPartition); override;
    procedure DoResize(const PartAfter, PartBefore: PPartedPartition); override;
  end;

implementation

procedure TPartedFileSystemF2FS.DoCreate(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemF2FS.DoCreate');
  // Format the new partition
  if PartAfter^.LabelName <> '' then
    DoExec('/bin/mkfs.f2fs', ['-f', '-l', PartAfter^.LabelName, PartAfter^.GetPartitionPath])
  else
    DoExec('/bin/mkfs.f2fs', ['-f', PartAfter^.GetPartitionPath]);
end;

procedure TPartedFileSystemF2FS.DoDelete(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemF2FS.DoDelete');
end;

procedure TPartedFileSystemF2FS.DoFormat(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemF2FS.DoFormat');
  // Format the partition
  DoExec('/bin/mkfs.f2fs', ['-f', PartAfter^.GetPartitionPath]);
end;

procedure TPartedFileSystemF2FS.DoFlag(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
end;

procedure TPartedFileSystemF2FS.DoLabelName(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemF2FS.DoLabelName');
end;

procedure TPartedFileSystemF2FS.DoResize(const PartAfter, PartBefore: PPartedPartition);
var
  Path: String;

  procedure Grow;
  begin
    DoExec('/bin/fsck.f2fs', ['-f', '-a', Path]);
    DoExec('/bin/parted', [PartAfter^.Device^.Path, 'resizepart', IntToStr(PartAfter^.Number), IntToStr(PartAfter^.PartEnd) + 'B']);
    DoExec('/bin/resize.f2fs', [Path]);
  end;

begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemF2FS.DoResize');
  // Shrink / Expand right
  Path := PartAfter^.GetPartitionPath;
  if PartAfter^.PartEnd > PartBefore^.PartEnd then
  begin
    Grow;
  end;
end;

initialization
  RegisterFileSystem(TPartedFileSystemF2FS, ['f2fs'], [1], True, False, True);

end.