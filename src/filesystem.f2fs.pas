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
  Parted.Commons, Locale, Parted.Devices, Parted.Operations, Parted.Partitions, Parted.Logs;

type
  TPartedFileSystemF2FS = class(TPartedFileSystem)
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

function TPartedFileSystemF2FS.GetSupport: TPartedFileSystemSupport;
begin
  inherited;
  Result.CanFormat := ProgramExists('mkfs.f2fs');
  Result.CanLabel := ProgramExists('f2fslabel');
  Result.CanMove := ProgramExists('sfdisk');
  Result.CanShrink := False;
  Result.CanGrow := ProgramExists('resize.f2fs') and ProgramExists('fsck.f2fs');
  Result.Dependencies := 'f2fs-tools';
end;

procedure TPartedFileSystemF2FS.DoCreate(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemF2FS.DoCreate');
  // Format the new partition
  if PartAfter^.LabelName <> '' then
    DoExec('mkfs.f2fs', ['-f', '-l', PartAfter^.LabelName, PartAfter^.GetPartitionPath])
  else
    DoExec('mkfs.f2fs', ['-f', PartAfter^.GetPartitionPath]);
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
  DoExec('mkfs.f2fs', ['-f', PartAfter^.GetPartitionPath]);
end;

procedure TPartedFileSystemF2FS.DoFlag(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
end;

procedure TPartedFileSystemF2FS.DoLabelName(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemF2FS.DoLabelName');
  if PartAfter^.LabelName <> '' then
    DoExec('f2fslabel', [PartAfter^.GetPartitionPath, PartAfter^.LabelName]);
end;

procedure TPartedFileSystemF2FS.DoResize(const PartAfter, PartBefore: PPartedPartition);
var
  Path: String;

  procedure Grow;
  begin
    DoExec('fsck.f2fs', ['-f', '-a', Path]);
    DoExec('parted', [PartAfter^.Device^.Path, 'resizepart', PartAfter^.Number.ToString, PartAfter^.PartEnd.ToString + 'B']);
    DoExec('resize.f2fs', [Path]);
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
  RegisterFileSystem(TPartedFileSystemF2FS, ['f2fs'], [1]);

end.