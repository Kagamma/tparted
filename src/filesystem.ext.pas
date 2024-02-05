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

  procedure MoveLeft;
  var
    TempPart: TPartedPartition;
  begin
    TempPart := PartAfter^;
    TempPart.PartEnd := PartBefore^.PartEnd;
    TempPart.PartSize := TempPart.PartEnd - TempPart.PartStart + 1;
    // Move partition, the command with
    DoExec('/bin/sh', ['-c', Format('echo "-%dM," | sfdisk --move-data %s -N %d', [BToMBFloor(PartBefore^.PartStart - TempPart.PartStart + 1), PartAfter^.Device^.Path, PartAfter^.Number])]);
    // Calculate the shift part to determine if we need to shrink or grow later
    PartBefore^.PartEnd := PartBefore^.PartEnd - (PartBefore^.PartStart - TempPart.PartStart);
  end;

  procedure MoveRight;
  var
    TempPart: TPartedPartition;
  begin
    TempPart := PartAfter^;
    TempPart.PartStart := PartBefore^.PartStart;
    TempPart.PartSize := TempPart.PartEnd - TempPart.PartStart + 1;
    // Move partition, the command with
    DoExec('/bin/sh', ['-c', Format('echo "+%dM," | sfdisk --move-data %s -N %d', [BToMBFloor(PartAfter^.PartStart - TempPart.PartStart + 1), PartAfter^.Device^.Path, PartAfter^.Number])]);
    // Calculate the shift part to determine if we need to shrink or grow later
    PartBefore^.PartEnd := PartBefore^.PartEnd + (PartAfter^.PartStart - TempPart.PartStart);
  end;

begin
  inherited;
  WriteLog(lsInfo, 'TPartedFileSystemExt.DoResize');
  // Move partition to the left
  if PartAfter^.PartStart < PartBefore^.PartStart then
  begin
    MoveLeft;
  end else
  if PartAfter^.PartStart > PartBefore^.PartStart then
  begin
    MoveRight;
  end;
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