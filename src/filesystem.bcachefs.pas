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

unit FileSystem.Bcachefs;

{$I configs.inc}

interface

uses
  Classes, SysUtils, Unix,
  FileSystem,
  Parted.Commons, Locale, Parted.Devices, Parted.Operations, Parted.Partitions, Parted.Logs;

type
  TPartedFileSystemBcachefs = class(TPartedFileSystem)
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

function TPartedFileSystemBcachefs.GetSupport: TPartedFileSystemSupport;
begin
  Result := inherited;
  Result.CanFormat := ProgramExists('bcachefs');
  Result.CanLabel := False;
  Result.CanMove := ProgramExists('sfdisk');
  Result.CanShrink := False;
  Result.CanGrow := ProgramExists('bcachefs');
  Result.Dependencies := 'bcachefs-tools';
end;

procedure TPartedFileSystemBcachefs.DoCreate(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemBcachefs.DoCreate');
  // Format the new partition
  if PartAfter^.LabelName <> '' then
    DoExec('bcachefs', ['format', '-L', PartAfter^.LabelName, PartAfter^.GetPartitionPath])
  else
    DoExec('bcachefs', ['format', PartAfter^.GetPartitionPath]);
end;

procedure TPartedFileSystemBcachefs.DoDelete(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemBcachefs.DoDelete');
end;

procedure TPartedFileSystemBcachefs.DoFormat(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemBcachefs.DoFormat');
  // Format the partition
  DoExec('bcachefs', ['format', PartAfter^.GetPartitionPath]);
end;

procedure TPartedFileSystemBcachefs.DoFlag(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
end;

procedure TPartedFileSystemBcachefs.DoLabelName(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemBcachefs.DoLabelName');
  if PartAfter^.LabelName <> '' then
    ExecSystem(Format('bcachefs attr -m label="%s" %s', [PartAfter^.LabelName, PartAfter^.GetPartitionPath]));
end;

procedure TPartedFileSystemBcachefs.DoResize(const PartAfter, PartBefore: PPartedPartition);
var
  Path, S: String;

  procedure Grow;
  begin
    DoExec('bcachefs', ['fsck', '-f', '-y', '-v', PartAfter^.GetPartitionPath]);
    DoExec('parted', [PartAfter^.Device^.Path, 'resizepart', PartAfter^.Number.ToString, PartAfter^.PartEnd.ToString + 'B']);
    DoExec('bcachefs', ['device', 'resize', PartAfter^.GetPartitionPath]);
  end;

begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemBcachefs.DoResize');
  // Shrink / Expand right
  Path := PartAfter^.GetPartitionPath;
  if PartAfter^.PartEnd > PartBefore^.PartEnd then
  begin
    Grow;
  end;
end;

initialization
  RegisterFileSystem(TPartedFileSystemBcachefs, ['bcachefs'], [32], [Pred(18446744073710)]);

end.