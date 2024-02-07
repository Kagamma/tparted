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

unit FileSystem.NTFS;

{$I configs.inc}

interface

uses
  Classes, SysUtils,
  FileSystem,
  Parted.Commons, Parted.Devices, Parted.Operations, Parted.Partitions, Parted.Logs;

type
  TPartedFileSystemNTFS = class(TPartedFileSystem)
  public
    procedure DoCreate(const PartAfter, PartBefore: PPartedPartition); override;
    procedure DoDelete(const PartAfter, PartBefore: PPartedPartition); override;
    procedure DoFormat(const PartAfter, PartBefore: PPartedPartition); override;
    procedure DoFlag(const PartAfter, PartBefore: PPartedPartition); override;
    procedure DoLabelName(const PartAfter, PartBefore: PPartedPartition); override;
    procedure DoResize(const PartAfter, PartBefore: PPartedPartition); override;
  end;

implementation

procedure TPartedFileSystemNTFS.DoCreate(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemNTFS.DoCreate');
  // Format the new partition
  DoExec('/bin/mkfs.ntfs', ['-f', PartAfter^.GetPartitionPath]);
  // Change label if needed
  if PartAfter^.LabelName <> '' then
    DoExec('/bin/ntfslabel', [PartAfter^.GetPartitionPath, PartAfter^.LabelName]);
end;

procedure TPartedFileSystemNTFS.DoDelete(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemNTFS.DoDelete');
end;

procedure TPartedFileSystemNTFS.DoFormat(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemNTFS.DoFormat');
  // Format the partition
  DoExec('/bin/mkfs.ntfs', ['-f', PartAfter^.GetPartitionPath]);
end;

procedure TPartedFileSystemNTFS.DoFlag(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
end;

procedure TPartedFileSystemNTFS.DoLabelName(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemNTFS.DoLabelName');
  if PartAfter^.LabelName <> PartBefore^.LabelName then
    DoExec('/bin/ntfslabel', [PartAfter^.GetPartitionPath, PartAfter^.LabelName]);
end;

procedure TPartedFileSystemNTFS.DoResize(const PartAfter, PartBefore: PPartedPartition);

  procedure Grow;
  begin
    DoExec('/bin/parted', [PartAfter^.Device^.Path, 'resizepart', IntToStr(PartAfter^.Number), IntToStr(PartAfter^.PartEnd) + 'B']);
    DoExec('/bin/ntfsresize', ['-f', PartAfter^.GetPartitionPath]);
    DoExec('/bin/ntfsfix', ['-b', '-d', PartAfter^.GetPartitionPath]);
  end;

  procedure Shrink;
  begin
    DoExec('/bin/ntfsresize', ['-f', '-s', IntToStr(PartAfter^.PartSize), PartAfter^.GetPartitionPath]);
    DoExec('/bin/ntfsfix', ['-b', '-d', PartAfter^.GetPartitionPath]);
    DoExec('/bin/sh', ['-c', Format('echo "Yes" | parted %s ---pretend-input-tty resizepart %d %dB', [PartAfter^.Device^.Path, PartAfter^.Number, PartAfter^.PartEnd])]);
  end;

begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemNTFS.DoResize');
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
  RegisterFileSystem(TPartedFileSystemNTFS, ['ntfs'], [1], True, True, True);

end.