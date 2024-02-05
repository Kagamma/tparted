unit FileSystem;

{$I configs.inc}

interface

uses
  Classes, SysUtils, Types,
  Parted.Commons, Parted.Devices, Parted.Operations, Parted.Partitions, Parted.Logs;

type
  TPartedFileSystem = class(TObject)
  public
    procedure DoExec(const Name: String; const Params: TStringDynArray; const Delay: LongWord = 1000);
    procedure DoMoveLeft(const PartAfter, PartBefore: PPartedPartition);
    procedure DoMoveRight(const PartAfter, PartBefore: PPartedPartition);
    procedure DoCreatePartitionOnly(const Part: PPartedPartition);

    procedure DoCreate(const PartAfter, PartBefore: PPartedPartition); virtual;
    procedure DoDelete(const PartAfter, PartBefore: PPartedPartition); virtual;
    procedure DoFormat(const PartAfter, PartBefore: PPartedPartition); virtual;
    procedure DoFlag(const PartAfter, PartBefore: PPartedPartition); virtual;
    procedure DoLabelName(const PartAfter, PartBefore: PPartedPartition); virtual;
    procedure DoResize(const PartAfter, PartBefore: PPartedPartition); virtual;
  end;

implementation

uses
  Math;

procedure TPartedFileSystem.DoExec(const Name: String; const Params: TStringDynArray; const Delay: LongWord = 1000);
var
  ExecResult: TExecResult;
begin
  Sleep(Delay);
  ExecResult := ExecS(Name, Params);
  if ExecResult.ExitCode <> 0 then
    WriteLogAndRaise(Format('Exit code %d: %s', [ExecResult.ExitCode, ExecResult.Message]));
end;

procedure TPartedFileSystem.DoCreatePartitionOnly(const Part: PPartedPartition);
var
  S: String;
begin
  S := Part^.FileSystem;
  if S = 'exfat' then // TODO: parted does not support exfat?
    S := 'fat32';
  // Create a new partition
  DoExec('/bin/parted', [Part^.Device^.Path, 'mkpart', Part^.Kind, S, IntToStr(Part^.PartStart) + 'B', IntToStr(Part^.PartEnd) + 'B']);
  // Loop through list of flags and set it
  for S in Part^.Flags do
  begin
    DoExec('/bin/parted', [Part^.Device^.Path, 'set', IntToStr(Part^.Number), S, 'on'], 16);
  end;
  // Set partition name
  if (Part^.Name <> '') and (Part^.Name <> 'primary') then
    DoExec('/bin/parted', [Part^.Device^.Path, 'name', IntToStr(Part^.Number), Part^.Name]);
end;

procedure TPartedFileSystem.DoMoveLeft(const PartAfter, PartBefore: PPartedPartition);
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

procedure TPartedFileSystem.DoMoveRight(const PartAfter, PartBefore: PPartedPartition);
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

procedure TPartedFileSystem.DoCreate(const PartAfter, PartBefore: PPartedPartition);
begin
  WriteLog(lsInfo, 'TPartedFileSystem.DoCreate');
  QueryDeviceExists(PartAfter^.Device^.Path);
  PartAfter^.Number := Abs(PartAfter^.Number);
  //
  DoCreatePartitionOnly(PartAfter);
end;

procedure TPartedFileSystem.DoDelete(const PartAfter, PartBefore: PPartedPartition);
begin
  WriteLog(lsInfo, 'TPartedFileSystem.DoDelete');
  QueryDeviceExists(PartBefore^.Device^.Path);
  // Make sure number is of a positive one
  if PartBefore^.Number <= 0 then
    WriteLogAndRaise(Format('Wrong number %d while trying to delete partition %s' , [PartBefore^.Number, PartBefore^.GetPartitionPath]));
  // Remove partition from partition table
  DoExec('/bin/parted', [PartBefore^.Device^.Path, 'rm', IntToStr(PartBefore^.Number)]);
end;

procedure TPartedFileSystem.DoFormat(const PartAfter, PartBefore: PPartedPartition);
begin
  WriteLog(lsInfo, 'TPartedFileSystem.DoFormat');
  QueryDeviceExists(PartAfter^.Device^.Path);
end;

procedure TPartedFileSystem.DoFlag(const PartAfter, PartBefore: PPartedPartition);
var
  S, State: String;
begin
  WriteLog(lsInfo, 'TPartedFileSystem.DoFlag');
  QueryDeviceExists(PartAfter^.Device^.Path);
  // Loop through list of flags and set it
  for S in FlagArray do
  begin
    if SToFlag(S, PartAfter^.Flags) <> 0 then
      State := 'on'
    else
      State := 'off';
    // TODO: Optimization is needed here
    DoExec('/bin/parted', [PartAfter^.Device^.Path, 'set', IntToStr(PartAfter^.Number), S, State], 16);
  end;
end;

procedure TPartedFileSystem.DoLabelName(const PartAfter, PartBefore: PPartedPartition);
begin
  WriteLog(lsInfo, 'TPartedFileSystem.DoLabelName');
  QueryDeviceExists(PartAfter^.Device^.Path);
  if (PartAfter^.Name <> PartBefore^.Name) and (PartAfter^.Name <> '') then
    DoExec('/bin/parted', [PartAfter^.Device^.Path, 'name', IntToStr(PartAfter^.Number), PartAfter^.Name]);
end;

procedure TPartedFileSystem.DoResize(const PartAfter, PartBefore: PPartedPartition);
begin
  WriteLog(lsInfo, 'TPartedFileSystem.DoResize');
  QueryDeviceExists(PartAfter^.Device^.Path);
end;

end.