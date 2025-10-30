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

unit FileSystem;

{$I configs.inc}

interface

uses
  Classes, SysUtils, Types, Generics.Collections,
  Parted.Commons, Locale, Parted.Devices, Parted.Operations, Parted.Partitions, Parted.Logs;

type
  TPartedFileSystemSupport = record
    CanGrow,
    CanShrink,
    CanMove,
    CanLabel,
    CanFormat: Boolean;
    Dependencies: String;
  end;

  TPartedFileSystem = class(TObject)
  public
    function GetSupport: TPartedFileSystemSupport; virtual;

    procedure DoExec(const Name: String; const Params: TStringDynArray; const Delay: LongWord = 1000);
    procedure DoExecAsync(const Name: String; const Params: TStringDynArray; const Delay: LongWord = 1000);
    procedure DoMoveLeft(const PartAfter, PartBefore: PPartedPartition);
    procedure DoMoveRight(const PartAfter, PartBefore: PPartedPartition);
    procedure DoCreatePartitionOnly(const Part: PPartedPartition);

    procedure DoCreate(const PartAfter, PartBefore: PPartedPartition); virtual;
    procedure DoDelete(const PartAfter, PartBefore: PPartedPartition); virtual;
    procedure DoFormat(const PartAfter, PartBefore: PPartedPartition); virtual;
    procedure DoFlag(const PartAfter, PartBefore: PPartedPartition); virtual;
    procedure DoLabelName(const PartAfter, PartBefore: PPartedPartition); virtual;
    procedure DoResize(const PartAfter, PartBefore: PPartedPartition); virtual;

    procedure DoFeedback(SL: Classes.TStringList); virtual;
  end;
  TPartedFileSystemClass = class of TPartedFileSystem;

  TPartedFileSystemMap = specialize TDictionary<String, TPartedFileSystemClass>;
  TPartedFileSystemSizeMap = specialize TDictionary<String, Int64>;
  TPartedFileSystemDependenciesMap = specialize TDictionary<String, String>;

procedure RegisterFileSystem(AFSClass: TPartedFileSystemClass; FileSystemTypeArray: TStringDynArray; MinSizeMap, MaxSizeMap: TInt64DynArray);
// Show a message box, and return false, if Size is invalid
function VerifyFileSystemSize(PT, FS: String; Size: Int64): Boolean;
// Return the minimal size of file system
function GetFileSystemMinSize(FS: String): Int64;
// Return the maximum size of file system
function GetFileSystemMaxSize(FS: String): Int64;

var
  FileSystemMap: TPartedFileSystemMap;
  FileSystemMinSizeMap: TPartedFileSystemSizeMap;
  FileSystemMaxSizeMap: TPartedFileSystemSizeMap;
  FileSystemDependenciesMap: TPartedFileSystemDependenciesMap;

  FileSystemSupportArray: array of string;
  FileSystemFormattableArray: array of String;
  FileSystemLabelArray: array of String;
  FileSystemMoveArray: array of String;
  FileSystemGrowArray: array of String;
  FileSystemShrinkArray: array of String;

implementation

uses
  UI.Commons,
  FreeVision,
  Math;

function VerifyFileSystemSize(PT, FS: String; Size: Int64): Boolean;
var
  MinSize,
  MaxSize: Int64;
begin
  Result := False;
  if FileSystemMinSizeMap.ContainsKey(FS) then
  begin
    MinSize := FileSystemMinSizeMap[FS];
    if MinSize > Size then
    begin
      MsgBox(Format(S_VerifyMinSize, [FS, MinSize]), nil, mfError + mfOKButton);
      Exit;
    end;
  end;
  if FileSystemMaxSizeMap.ContainsKey(FS) then
  begin
    MaxSize := FileSystemMaxSizeMap[FS];
    if MaxSize < Size then
    begin
      MsgBox(Format(S_VerifyMaxSize, [FS, MaxSize]), nil, mfError + mfOKButton);
      Exit;
    end;
  end;
  if PT = 'msdos' then
  begin
    if 2097152 < Size then
    begin
      MsgBox(Format(S_VerifyMaxSize, [FS, 2097152]), nil, mfError + mfOKButton);
      Exit;
    end;
  end;
  Result := True;
end;

function GetFileSystemMinSize(FS: String): Int64;
begin
  Result := 1;
  if FileSystemMinSizeMap.ContainsKey(FS) then
  begin
    Result := FileSystemMinSizeMap[FS];
  end;
end;

function GetFileSystemMaxSize(FS: String): Int64;
begin
  Result := 1;
  if FileSystemMaxSizeMap.ContainsKey(FS) then
  begin
    Result := FileSystemMaxSizeMap[FS];
  end;
end;

procedure RegisterFileSystem(AFSClass: TPartedFileSystemClass; FileSystemTypeArray: TStringDynArray; MinSizeMap, MaxSizeMap: TInt64DynArray);
var
  I: LongInt;
  S: String;
  L: LongInt;
  SL: Classes.TStringList; // Ugly way to sort string...
  FS: TPartedFileSystem;
  Support: TPartedFileSystemSupport;
begin
  Assert(Length(FileSystemTypeArray) = Length(MinSizeMap), 'MinLength must be the same!');
  Assert(Length(FileSystemTypeArray) = Length(MaxSizeMap), 'MaxLength must be the same!');
  SL := Classes.TStringList.Create;
  FS := AFSClass.Create;
  try
    Support := FS.GetSupport;
    SL.Sorted := True;
    // Supported list
    for S in FileSystemSupportArray do
      SL.Add(S);
    for I := 0 to Pred(Length(FileSystemTypeArray)) do
    begin
      S := FileSystemTypeArray[I];
      FileSystemDependenciesMap.Add(S, Support.Dependencies);
      SL.Add(S);
    end;
    SetLength(FileSystemSupportArray, SL.Count);
    for I := 0 to Pred(SL.Count) do
      FileSystemSupportArray[I] := SL[I];
    // Formattable
    SL.Clear;
    if Support.CanFormat then
    begin
      for S in FileSystemFormattableArray do
        SL.Add(S);
      for I := 0 to Pred(Length(FileSystemTypeArray)) do
      begin
        S := FileSystemTypeArray[I];
        FileSystemMap.Add(S, AFSClass);
        FileSystemMinSizeMap.Add(S, MinSizeMap[I]);
        FileSystemMaxSizeMap.Add(S, MaxSizeMap[I]);
        SL.Add(S);
      end;
      SetLength(FileSystemFormattableArray, SL.Count);
      for I := 0 to Pred(SL.Count) do
        FileSystemFormattableArray[I] := SL[I];
    end;
    //
    for S in FileSystemTypeArray do
    begin
      if Support.CanMove then
      begin
        L := Length(FileSystemMoveArray) + 1;
        SetLength(FileSystemMoveArray, L);
        FileSystemMoveArray[Pred(L)] := S;
      end;
      //
      if Support.CanShrink then
      begin
        L := Length(FileSystemShrinkArray) + 1;
        SetLength(FileSystemShrinkArray, L);
        FileSystemShrinkArray[Pred(L)] := S;
      end;
      //
      if Support.CanGrow then
      begin
        L := Length(FileSystemGrowArray) + 1;
        SetLength(FileSystemGrowArray, L);
        FileSystemGrowArray[Pred(L)] := S;
      end;
      //
      if Support.CanLabel then
      begin
        L := Length(FileSystemLabelArray) + 1;
        SetLength(FileSystemLabelArray, L);
        FileSystemLabelArray[Pred(L)] := S;
      end;
    end;
  finally
    FS.Free;
    SL.Free;
  end;
end;

// -------------------------------

function TPartedFileSystem.GetSupport: TPartedFileSystemSupport;
begin
  Result.CanFormat := ProgramExists('parted');
  Result.CanMove := False;
  Result.CanShrink := False;
  Result.CanGrow := False;
  Result.CanLabel := False;
  Result.Dependencies := 'parted';
end;

procedure TPartedFileSystem.DoExec(const Name: String; const Params: TStringDynArray; const Delay: LongWord = 1000);
var
  ExecResult: TExecResult;
begin
  Sleep(Delay);
  ExecResult := ExecS(Name, Params);
  if ExecResult.ExitCode <> 0 then
    WriteLogAndRaise(Format(S_ProcessExitCode, [Name, ExecResult.ExitCode, ExecResult.Message]));
end;

procedure TPartedFileSystem.DoExecAsync(const Name: String; const Params: TStringDynArray; const Delay: LongWord = 1000);
var
  ExecResult: TExecResult;
begin
  Sleep(Delay);
  ExecResult := ExecAsync(Name, Params, @Self.DoFeedback);
  if ExecResult.ExitCode <> 0 then
    WriteLogAndRaise(Format(S_ProcessExitCode, [Name, ExecResult.ExitCode, ExecResult.Message]));
end;

procedure TPartedFileSystem.DoCreatePartitionOnly(const Part: PPartedPartition);
var
  S: String;
begin
  S := Part^.FileSystem;
  if S = 'exfat' then // TODO: parted does not support exfat?
    S := 'fat32'
  else
  if (S = 'unformatted') or (S = 'bcachefs') then
    S := 'ext4';
  // Create a new partition
  DoExec('parted', [Part^.Device^.Path, 'mkpart', Part^.Kind, S, Part^.PartStart.ToString + 'B', Part^.PartEnd.ToString + 'B']);
  // Loop through list of flags and set it
  for S in Part^.Flags do
  begin
    DoExec('parted', [Part^.Device^.Path, 'set', Part^.Number.ToString, S, 'on'], 16);
  end;
  // Set partition name
  if (Part^.Name <> '') and (Part^.Name <> 'primary') then
    DoExec('parted', [Part^.Device^.Path, 'name', Part^.Number.ToString, Part^.Name]);
end;

procedure TPartedFileSystem.DoMoveLeft(const PartAfter, PartBefore: PPartedPartition);
var
  TempPart: TPartedPartition;
begin
  TempPart := PartAfter^;
  TempPart.PartEnd := PartBefore^.PartEnd;
  TempPart.PartSize := TempPart.PartEnd - TempPart.PartStart + 1;
  // Move partition, the command with
  DoExecAsync('sh', ['-c', Format('echo "-%dM," | sfdisk --move-data %s -N %d', [BToMBFloor(PartBefore^.PartStart - TempPart.PartStart + 1), PartAfter^.Device^.Path, PartAfter^.Number])]);
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
  DoExecAsync('sh', ['-c', Format('echo "+%dM," | sfdisk --move-data %s -N %d', [BToMBFloor(PartAfter^.PartStart - TempPart.PartStart + 1), PartAfter^.Device^.Path, PartAfter^.Number])]);
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
  DoExec('wipefs', ['-a', PartAfter^.GetActualPartitionPath]);
end;

procedure TPartedFileSystem.DoDelete(const PartAfter, PartBefore: PPartedPartition);
begin
  WriteLog(lsInfo, 'TPartedFileSystem.DoDelete');
  QueryDeviceExists(PartBefore^.Device^.Path);
  // Make sure number is of a positive one
  if PartBefore^.Number <= 0 then
    WriteLogAndRaise(Format('Wrong number %d while trying to delete partition %s' , [PartBefore^.Number, PartBefore^.GetPartitionPath]));
  // Make sure to unmount decrypted partition first
  if PartBefore^.IsDecrypted then
    ExecSystem('cryptsetup luksClose ' + ExtractFileName(PartBefore^.GetActualPartitionPath));
  // Remove partition from partition table
  DoExec('parted', [PartBefore^.Device^.Path, 'rm', PartBefore^.Number.ToString]);
end;

procedure TPartedFileSystem.DoFormat(const PartAfter, PartBefore: PPartedPartition);
begin
  WriteLog(lsInfo, 'TPartedFileSystem.DoFormat');
  QueryDeviceExists(PartAfter^.Device^.Path);
  DoExec('wipefs', ['-a', PartAfter^.GetActualPartitionPath]);
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
    if SToFlag(S, PartBefore^.Flags) <> 0 then
      State := 'off'
    else
      State := '';
    if State <> '' then
      DoExec('parted', [PartAfter^.Device^.Path, 'set', PartAfter^.Number.ToString, S, State], 16);
  end;
end;

procedure TPartedFileSystem.DoLabelName(const PartAfter, PartBefore: PPartedPartition);
begin
  WriteLog(lsInfo, 'TPartedFileSystem.DoLabelName');
  QueryDeviceExists(PartAfter^.Device^.Path);
  if (PartAfter^.Name <> PartBefore^.Name) and (PartAfter^.Name <> '') then
    DoExec('parted', [PartAfter^.Device^.Path, 'name', PartAfter^.Number.ToString, PartAfter^.Name]);
end;

procedure TPartedFileSystem.DoResize(const PartAfter, PartBefore: PPartedPartition);
begin
  WriteLog(lsInfo, 'TPartedFileSystem.DoResize');
  QueryDeviceExists(PartAfter^.Device^.Path);
  // Move partition to the left or right
  if PartAfter^.PartStart < PartBefore^.PartStart then
  begin
    DoMoveLeft(PartAfter, PartBefore);
  end else
  if PartAfter^.PartStart > PartBefore^.PartStart then
  begin
    DoMoveRight(PartAfter, PartBefore);
  end;
end;

procedure TPartedFileSystem.DoFeedback(SL: Classes.TStringList);
var
  S, S2: String;
  I: Integer;
begin
  S := #13;
  if SL.Count > 0 then
    for I := Max(0, SL.Count - 6) to SL.Count - 1 do
    begin
      S2 := RemoveVT100EscapeSequences(SL[I]);
      if Length(S2) > 70 then
        SetLength(S2, 70);
      if I <> SL.Count - 1 then
      begin
        S := S + S2 + #13;
      end else
      begin
        S := S + S2;
      end;
    end;
  LoadingUpdate(S);
end;

initialization
  FileSystemMap := TPartedFileSystemMap.Create;
  FileSystemMinSizeMap := TPartedFileSystemSizeMap.Create;
  FileSystemMaxSizeMap := TPartedFileSystemSizeMap.Create;
  FileSystemDependenciesMap := TPartedFileSystemDependenciesMap.Create;
  RegisterFileSystem(TPartedFileSystem, ['unformatted'], [1], [$1FFFFFFFFFFFFFFF]);

finalization
  FilesystemMap.Free;
  FileSystemMinSizeMap.Free;
  FileSystemMaxSizeMap.Free;
  FileSystemDependenciesMap.Free;

end.