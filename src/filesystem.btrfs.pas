unit FileSystem.BTRFS;

{$I configs.inc}

interface

uses
  Classes, SysUtils, Unix,
  FileSystem,
  Parted.Commons, Parted.Devices, Parted.Operations, Parted.Partitions, Parted.Logs;

type
  TPartedFileSystemBTRFS = class(TPartedFileSystem)
  public
    procedure DoCreate(const PartAfter, PartBefore: PPartedPartition); override;
    procedure DoDelete(const PartAfter, PartBefore: PPartedPartition); override;
    procedure DoFormat(const PartAfter, PartBefore: PPartedPartition); override;
    procedure DoFlag(const PartAfter, PartBefore: PPartedPartition); override;
    procedure DoLabelName(const PartAfter, PartBefore: PPartedPartition); override;
    procedure DoResize(const PartAfter, PartBefore: PPartedPartition); override;
  end;

implementation

procedure TPartedFileSystemBTRFS.DoCreate(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemBTRFS.DoCreate');
  // Format the new partition
  DoExec('/bin/mkfs.btrfs', ['-f', PartAfter^.GetPartitionPath]);
  // Change label if needed
  if PartAfter^.LabelName <> '' then
    DoExec('/bin/btrfs', ['filesystem', 'label', PartAfter^.GetPartitionPath, PartAfter^.LabelName]);
end;

procedure TPartedFileSystemBTRFS.DoDelete(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemBTRFS.DoDelete');
end;

procedure TPartedFileSystemBTRFS.DoFormat(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemBTRFS.DoFormat');
  // Format the partition
  DoExec('/bin/mkfs.btrfs', ['-f', PartAfter^.GetPartitionPath]);
end;

procedure TPartedFileSystemBTRFS.DoFlag(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
end;

procedure TPartedFileSystemBTRFS.DoLabelName(const PartAfter, PartBefore: PPartedPartition);
begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemBTRFS.DoLabelName');
  if PartAfter^.LabelName <> '' then
    DoExec('/bin/btrfs', ['filesystem', 'label', PartAfter^.GetPartitionPath, PartAfter^.LabelName]);
end;

procedure TPartedFileSystemBTRFS.DoResize(const PartAfter, PartBefore: PPartedPartition);
var
  Path, PathMnt, S: String;

  procedure Grow;
  begin
    DoExec('/bin/parted', [PartAfter^.Device^.Path, 'resizepart', IntToStr(PartAfter^.Number), IntToStr(PartAfter^.PartEnd) + 'B']);
    ExecSystem(Format('/bin/mkdir -p "%s" > /dev/null', [PathMnt]));
    ExecSystem(Format('/bin/mount "%s" "%s" > /dev/null', [Path, PathMnt]));
    DoExec('/bin/btrfs', ['filesystem', 'resize', '1:max', PathMnt]);
    ExecSystem(Format('/bin/umount "%s" > /dev/null', [Path]));
    ExecSystem(Format('/bin/rm -d "%s" > /dev/null', [PathMnt]));
  end;

  procedure Shrink;
  begin
    ExecSystem(Format('/bin/mkdir -p "%s" > /dev/null', [PathMnt]));
    ExecSystem(Format('/bin/mount "%s" "%s" > /dev/null', [Path, PathMnt]));
    DoExec('/bin/btrfs', ['filesystem', 'resize', '1:' + IntToStr(BToKBFloor(PartAfter^.PartSize)) + 'K', PathMnt]);
    ExecSystem(Format('/bin/umount "%s" > /dev/null', [Path]));
    ExecSystem(Format('/bin/rm -d "%s" > /dev/null', [PathMnt]));
    DoExec('/bin/sh', ['-c', Format('echo "Yes" | parted %s ---pretend-input-tty resizepart %d %dB', [PartAfter^.Device^.Path, PartAfter^.Number, PartAfter^.PartEnd])]);
  end;

begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemBTRFS.DoResize');
  // Move partition to the left
  if PartAfter^.PartStart < PartBefore^.PartStart then
  begin
    DoMoveLeft(PartAfter, PartBefore);
  end else
  if PartAfter^.PartStart > PartBefore^.PartStart then
  begin
    DoMoveRight(PartAfter, PartBefore);
  end;
  // Shrink / Expand right
  Path := PartAfter^.GetPartitionPath;
  PathMnt := '/tmp/tparted_' + StringReplace(Path, '/', '_', [rfReplaceAll]);
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