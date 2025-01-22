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

  TPartedFileSystemExt2 = class(TPartedFileSystemExt)
  public
    function GetSupport: TPartedFileSystemSupport; override;
  end;

  TPartedFileSystemExt3 = class(TPartedFileSystemExt)
  public
    function GetSupport: TPartedFileSystemSupport; override;
  end;

  TPartedFileSystemExt4 = class(TPartedFileSystemExt)
  public
    function GetSupport: TPartedFileSystemSupport; override;
  end;

implementation

uses
  UI.Commons;

function TPartedFileSystemExt.GetSupport: TPartedFileSystemSupport;
begin
  inherited;
  Result.CanFormat := False;
  Result.CanLabel := ProgramExists('e2label');
  Result.CanMove := ProgramExists('sfdisk');
  Result.CanShrink := ProgramExists('resize2fs') and ProgramExists('e2fsck');
  Result.CanGrow := ProgramExists('resize2fs') and ProgramExists('e2fsck');
  Result.Dependencies := 'e2fsprogs';
end;

procedure TPartedFileSystemExt.DoCreate(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemExt.DoCreate');
  // Format the new partition
  DoExec('mkfs.' + PartAfter^.FileSystem, [PartAfter^.GetPartitionPath]);
  // Change label if needed
  if PartAfter^.LabelName <> '' then
    DoExec('e2label', [PartAfter^.GetPartitionPath, PartAfter^.LabelName]);
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
  DoExec('mkfs.' + PartAfter^.FileSystem, [PartAfter^.GetPartitionPath]);
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
    DoExec('e2label', [PartAfter^.GetPartitionPath, PartAfter^.LabelName]);
end;

procedure TPartedFileSystemExt.DoResize(const PartAfter, PartBefore: PPartedPartition);

  procedure Grow;
  begin
    DoExec('e2fsck', ['-f', '-y', '-v', '-C', '0', PartAfter^.GetPartitionPath]);
    DoExec('parted', [PartAfter^.Device^.Path, 'resizepart', PartAfter^.Number.ToString, PartAfter^.PartEnd.ToString + 'B']);
    DoExec('resize2fs', ['-fp', PartAfter^.GetPartitionPath]);
  end;

  procedure Shrink;
  begin
    DoExec('e2fsck', ['-f', '-y', '-v', '-C', '0', PartAfter^.GetPartitionPath]);
    DoExec('resize2fs', ['-fp', PartAfter^.GetPartitionPath, BToKBFloor(PartAfter^.PartSize).ToString + 'K']);
    DoExec('sh', ['-c', Format('echo "Yes" | parted %s ---pretend-input-tty resizepart %d %dB', [PartAfter^.Device^.Path, PartAfter^.Number, PartAfter^.PartEnd])]);
  end;

begin
  WriteLog(lsInfo, 'TPartedFileSystemExt.DoResize');
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

function TPartedFileSystemExt2.GetSupport: TPartedFileSystemSupport;
begin
  Result := inherited;
  Result.CanFormat := ProgramExists('mkfs.ext2');
end;

function TPartedFileSystemExt3.GetSupport: TPartedFileSystemSupport;
begin
  Result := inherited;
  Result.CanFormat := ProgramExists('mkfs.ext3');
end;

function TPartedFileSystemExt4.GetSupport: TPartedFileSystemSupport;
begin
  Result := inherited;
  Result.CanFormat := ProgramExists('mkfs.ext4');
end;

initialization
  RegisterFileSystem(TPartedFileSystemExt2, ['ext2'], [1], [Pred(33554432)]);
  RegisterFileSystem(TPartedFileSystemExt3, ['ext3'], [1], [Pred(33554432)]);
  RegisterFileSystem(TPartedFileSystemExt4, ['ext4'], [1], [Pred(1099511627776)]);

end.