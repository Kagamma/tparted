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
  Parted.Commons, Locale, Parted.Devices, Parted.Operations, Parted.Partitions, Parted.Logs;

type
  TPartedFileSystemNTFS = class(TPartedFileSystem)
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

function TPartedFileSystemNTFS.GetSupport: TPartedFileSystemSupport;
begin
  Result := inherited;
  Result.CanFormat := ProgramExists('mkfs.ntfs');
  Result.CanLabel := ProgramExists('ntfslabel');
  Result.CanMove := ProgramExists('sfdisk');
  Result.CanShrink := ProgramExists('ntfsresize') and ProgramExists('ntfsfix');
  Result.CanGrow := ProgramExists('ntfsresize') and ProgramExists('ntfsfix');
  Result.Dependencies := 'ntfs-3g';
end;

procedure TPartedFileSystemNTFS.DoCreate(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemNTFS.DoCreate');
  // Format the new partition
  DoExec('mkfs.ntfs', ['-f', PartAfter^.GetPartitionPath]);
  // Change label if needed
  if PartAfter^.LabelName <> '' then
    DoExec('ntfslabel', [PartAfter^.GetPartitionPath, PartAfter^.LabelName]);
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
  DoExec('mkfs.ntfs', ['-f', PartAfter^.GetPartitionPath]);
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
    DoExec('ntfslabel', [PartAfter^.GetPartitionPath, PartAfter^.LabelName]);
end;

procedure TPartedFileSystemNTFS.DoResize(const PartAfter, PartBefore: PPartedPartition);

  procedure Grow;
  begin
    DoExec('ntfsresize', ['-f', PartAfter^.GetPartitionPath]);
    DoExec('parted', [PartAfter^.Device^.Path, 'resizepart', PartAfter^.Number.ToString, PartAfter^.PartEnd.ToString + 'B']);
    DoExec('ntfsfix', ['-b', '-d', PartAfter^.GetPartitionPath]);
  end;

  procedure Shrink;
  begin
    DoExec('ntfsresize', ['-f', '-s', PartAfter^.PartSize.ToString, PartAfter^.GetPartitionPath]);
    DoExec('ntfsfix', ['-b', '-d', PartAfter^.GetPartitionPath]);
    DoExec('sh', ['-c', Format('echo "Yes" | parted %s ---pretend-input-tty resizepart %d %dB', [PartAfter^.Device^.Path, PartAfter^.Number, PartAfter^.PartEnd])]);
  end;

begin
  WriteLog(lsInfo, 'TPartedFileSystemNTFS.DoResize');
  // Shrink / Expand right
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
  RegisterFileSystem(TPartedFileSystemNTFS, ['ntfs'], [2], [Pred(17592186044416)]);

end.