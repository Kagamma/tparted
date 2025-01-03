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

unit Parted.Partitions;

{$I configs.inc}

interface

uses
  Classes, SysUtils, Types, fpjson, jsonparser,
  {$ifdef Unix}Unix,{$endif}
  Parted.Commons, Locale, Parted.Devices, Parted.Logs;

const
  FlagArray: array of String = (
    'bios_grub', 'bls_boot', 'boot', 'chromeos_kernel', 'diag',
    'esp', 'hidden', 'irst', 'legacy_boot', 'linux-home',
    'lvm', 'msftdata', 'msftres', 'no_automount', 'raid', 'swap'
  );

// Parse for device info from "parted -j /dev/Xxx unit B print free" string
procedure ParseDeviceAndPartitionsFromJsonString(const JsonString: String; var ADevice: TPartedDevice);
// Parse for used and available in bytes from a single partition
// AText is the result from "df -B1 APath"
procedure ParseUsedAndAvailableBlockFromString(const AText: String; var APart: TPartedPartition);
// Parse for mount status, from "/bin/findmnt -J -n APath"
procedure ParseMountStatusFromJsonString(const JsonString: String; var APart: TPartedPartition);

// Update all partition for a single device at once
procedure QueryDeviceAll(var ADevice: TPartedDevice);
// Query all information for partition
procedure QueryPartitionAll(var APart: TPartedPartition);

// /bin/parted -j APath unit B print free
function QueryDeviceAndPartitions(const APath: String; var ADevice: TPartedDevice): TExecResult;
// /bin/findmnt -J -n APath
function QueryPartitionMountStatus(var APart: TPartedPartition): TExecResult;
// /bin/df -B1 APath
function QueryPartitionUsedAndAvail(var APart: TPartedPartition): TExecResultDA;
// /bin/tune2fs -l APath
function QueryPartitionReservedSize(var APart: TPartedPartition): TExecResultDA;
// /bin/blkid -s LABEL -o value APath
function QueryPartitionLabel(var APart: TPartedPartition): TExecResult;
// /bin/umount APath
function QueryPartitionUnmount(var APart: TPartedPartition): TExecResult;
// /bin/blkid -s TYPE -o value APath
function QueryPartitionFileSystem(var APart: TPartedPartition): TExecResult;

implementation

uses
  Math;

procedure ParseDeviceAndPartitionsFromJsonString(const JsonString: String; var ADevice: TPartedDevice);
var
  I, J: LongInt;
  Data: TJSONObject;
  DiskJson: TJSONObject;
  PartArrayJson: TJSONArray;
  PartJson: TJSONObject;
  FlagArrayJson: TJsonArray;
  PPart: PPartedPartition;
begin
  Data := GetJSON(JsonString) as TJSONObject;
  try
    DiskJson := Data.Objects['disk'];

    ADevice.Init;
    ADevice.Name := DiskJson.Strings['model'];
    ADevice.Path := DiskJson.Strings['path'];
    ADevice.Size := ExtractQWordFromSize(DiskJson.Strings['size']);
    ADevice.SizeApprox := SizeString(ADevice.Size);
    ADevice.Transport := DiskJson.Strings['transport'];
    ADevice.LogicalSectorSize := DiskJson.Integers['logical-sector-size'];
    ADevice.PhysicalSectorSize := DiskJson.Integers['physical-sector-size'];
    ADevice.Table := DiskJson.Strings['label'];
    if ADevice.Table = 'unknown' then // This device has no partition table
    begin
      // We will create a fake root partition
      New(PPart);
      PPart^.Init;
      ADevice.InsertPartition(PPart);
      PPart^.Device := @ADevice;
      PPart^.Number := 0;
      PPart^.PartStart := 0;
      PPart^.PartEnd := ADevice.Size;
      PPart^.PartSize := ADevice.Size;
      Exit;
    end else
    // Reading UUID is optional
    try
      if ADevice.Table = 'gpt' then
        ADevice.UUID := DiskJson.Strings['uuid'];
    except
      on E: Exception do;
    end;
    ADevice.MaxPartitions := DiskJson.Integers['max-partitions'];

    PartArrayJson := DiskJson.Arrays['partitions'];
    for I := 0 to Pred(PartArrayJson.Count) do
    begin
      PartJson := PartArrayJson[I] as TJSONObject;
      New(PPart);
      PPart^.Init;
      ADevice.InsertPartition(PPart);
      PPart^.Device := @ADevice;
      PPart^.Number := PartJson.Integers['number'];
      PPart^.PartStart := ExtractQWordFromSize(PartJson.Strings['start']);
      PPart^.PartEnd := ExtractQWordFromSize(PartJson.Strings['end']);
      PPart^.PartSize := ExtractQWordFromSize(PartJson.Strings['size']);
      PPart^.Kind := PartJson.Strings['type'];
      if PPart^.Number <> 0 then // Not an unallocated space
      begin
        if ADevice.Table = 'gpt' then
        begin
          PPart^.KindUUID := PartJson.Strings['type-uuid'];
          PPart^.UUID := PartJson.Strings['uuid'];
        end;
        // FileSystem is optional
        try
          PPart^.FileSystem := PartJson.Strings['filesystem'];
        except
          on E: Exception do
            QueryPartitionFileSystem(PPart^); // Use blkid to detect filesystem, in case parted failed to do so
        end;
        // We remove (v1) from linux-swap...
        if PPart^.FileSystem = 'linux-swap(v1)' then
          PPart^.FileSystem := 'linux-swap';
        // Name is optional
        try PPart^.Name := PartJson.Strings['name'] except on E: Exception do; end;
      end;
      // Flag is optional, so we ignore exception if there's none
      try
        FlagArrayJson := PartJson.Arrays['flags'];
        SetLength(PPart^.Flags, FlagArrayJson.Count);
        for J := 0 to Pred(FlagArrayJson.Count) do
        begin
          PPart^.Flags[J] := FlagArrayJson[J].AsString;
        end;
      except
        on E: Exception do;
      end;
    end;
  finally
    Data.Free;
  end;
end;

procedure ParseUsedAndAvailableBlockFromString(const AText: String; var APart: TPartedPartition);
var
  MatchResult: TStringDynArray;
  Ext4ReservedSpace: QWord;
begin
  MatchResult := Match(AText, ['([^\s]+)', '([^\s]+)', '([^\s]+)', '([^\s]+)']);
  APart.PartUsed := MatchResult[2].ToInt64;
  APart.PartFree := MatchResult[3].ToInt64;
  {if APart.FileSystem = 'ext4' then // Manually calculate the 5% reserved space for ext4 TODO: Can we get this info via tune2fs?
  begin
    Ext4ReservedSpace := APart.PartSize div 100 * 5;
    APart.PartUsed := Min(APart.PartUsed + Ext4ReservedSpace, APart.PartSize);
    APart.PartFree := Max(APart.PartFree + Ext4ReservedSpace, 0);
  end;}
  APart.CanBeResized := True;
end;

procedure ParseMountStatusFromJsonString(const JsonString: String; var APart: TPartedPartition);
var
  Data: TJSONObject;
  FSJsonArray: TJSONArray;
  FSJson: TJSONObject;
begin
  Data := GetJSON(JsonString) as TJSONObject;
  try
    FSJsonArray := Data.Arrays['filesystems'];
    FSJson := FSJsonArray[0] as TJSONObject;
    APart.MountPoint := FSJson.Strings['target'];
    APart.IsMounted := True; // Mark the partition as mounted
  finally
    Data.Free;
  end;
end;

procedure QueryDeviceAll(var ADevice: TPartedDevice);
var
  PPart: PPartedPartition;
begin
  PPart := ADevice.PartitionRoot;
  while PPart <> nil do
  begin
    QueryPartitionAll(PPart^);
    PPart := PPart^.Next;
  end;
end;

procedure QueryPartitionAll(var APart: TPartedPartition);
begin
  QueryPartitionMountStatus(APart);
  QueryPartitionUsedAndAvail(APart);
  QueryPartitionLabel(APart);
end;

function QueryDeviceAndPartitions(const APath: String; var ADevice: TPartedDevice): TExecResult;
begin
  Result.ExitCode := -1;
  {$ifndef TPARTED_TEST}
  // Performs "parted -j /dev/Xxx unit B list" for details about a device and its partitions
  Result := ExecS('parted', ['-j', APath, 'unit', 'B', 'print', 'free']);
  if Result.ExitCode <> 0 then
    WriteLogAndRaise(Format(S_ProcessExitCode, ['parted -j ' + APath + ' unit B print free', Result.ExitCode, Result.Message]));
  ParseDeviceAndPartitionsFromJsonString(Result.Message, ADevice);
  {$else}
  // TODO: For testing purpose
  ParseDeviceAndPartitionsFromJsonString(FileToS('../testdata/parted_output_json.txt'), ADevice);
  {$endif}
end;

function QueryPartitionMountStatus(var APart: TPartedPartition): TExecResult;
var
  Path: String; // Partition path
begin
  Result.ExitCode := -1;
  {$ifndef TPARTED_TEST}
  Path := APart.GetPartitionPath;
  if APart.FileSystem <> 'linux-swap' then
  begin
    Result := ExecS('findmnt', ['-J', '-n', Path]);
    if (Result.ExitCode = 0){ and (Result.Message <> '') }then
      ParseMountStatusFromJsonString(Result.Message, APart);
    // We can safely ignore abnormal exit code, since they are treated as unmount
  end else
  begin
    // For swap, we test by running "swapon -s" and look for partition path
    Result := ExecS('swapon', ['-s']);
    if Pos(Path, Result.Message) > 0 then
      APart.IsMounted := True;
  end;
  {$else}
  {$endif}
end;

function QueryPartitionUsedAndAvail(var APart: TPartedPartition): TExecResultDA;
var
  Path: String; // Partition path
  PathMnt: String; // /mnt path
  S: String;
begin
  Result.ExitCode := -1;
  {$ifndef TPARTED_TEST}
  // Immediately skip if this is either efi partition, swap, or unallocated space
  if (APart.Number <= 0) or APart.ContainsFlag('esp') or (APart.FileSystem = '') or (APart.FileSystem = 'linux-swap') then
    Exit;
  Path := APart.GetPartitionPath;
  PathMnt := GetTempMountPath(Path);
  // We will try to mount the partition, in case it is unmount
  // - TODO: For now we dont check the usage of linux-swap
  if not APart.IsMounted then
  begin
    // TODO: For some reasons ntfs filesystem makes the app freeze unless we use fpSystem()...
    Mount(Path, PathMnt);
  end;
  // For non-swap partitions
  if APart.FileSystem <> 'linux-swap' then
  begin
    Result := ExecSA('df', ['-B1', Path]);
    if Result.ExitCode <> 0 then
      WriteLogAndRaise(Format(S_ProcessExitCode, ['df -B1  ' + Path, Result.ExitCode, SAToS(Result.MessageArray)]));
    ParseUsedAndAvailableBlockFromString(Result.MessageArray[1], APart);
  end;
  QueryPartitionReservedSize(APart);
  // Try to unmount the device again after we're done
  if (not APart.IsMounted) and (APart.FileSystem <> 'linux-swap') then
  begin
    Unmount(Path, PathMnt);
  end;
  {$else}
  APart.PartUsed := 1024 * 1024 * 8;
  APart.PartFree := APart.PartSize - APart.PartUsed;
  {$endif}
end;

function QueryPartitionReservedSize(var APart: TPartedPartition): TExecResultDA;
  
  function ExtractNumberFromText(const S: String): QWord;
  var
    C: Char;
    NText: String;
  begin
    Result := 0;
    for C in S do
    begin
      if C in ['0'..'9'] then
        NText := NText + C;
    end;
    if NText <> '' then
      Result := NText.ToInt64;
  end;

var
  Path, S: String;
  BlockSize: LongInt = 0;
  BlockCount: QWord = 0;
begin
  Result.ExitCode := -1;
  if APart.Number <= 0 then
    Exit;
  if (APart.FileSystem <> 'ext2') and (APart.FileSystem <> 'ext3') and (APart.FileSystem <> 'ext4') then
    Exit;
  if not ProgramExists('tune2fs') then
    Exit;
  Path := APart.GetPartitionPath;
  Result := ExecSA('tune2fs', ['-l', Path]);
  if Result.ExitCode <> 0 then
  begin
    WriteLog(lsError, Format(S_ProcessExitCode, ['tune2fs -l ' + Path, Result.ExitCode, SAToS(Result.MessageArray)]));
    Exit;
  end;
  for S in Result.MessageArray do
  begin
    if S.IndexOf('Block size:') >= 0 then
      BlockSize := ExtractNumberFromText(S)
    else
    if S.IndexOf('Reserved block count:') >= 0 then
      BlockCount := ExtractNumberFromText(S);
    if (BlockSize > 0) and (BlockCount > 0) then
    begin
      APart.PartUsed := Min(APart.PartSize, APart.PartUsed + BlockSize * BlockCount);
      APart.PartFree := APart.PartSize - APart.PartUsed;
      break;
    end;
  end;
end;

function QueryPartitionLabel(var APart: TPartedPartition): TExecResult;
var
  Path: String; // Partition path
begin
  Result.ExitCode := -1;
  {$ifndef TPARTED_TEST}
  // Immediately skip if this is a swap, or unallocated space
  if (APart.Number <= 0) or (APart.FileSystem =  'linux-swap') then
    Exit;
  Path := APart.GetPartitionPath;
  Result := ExecS('blkid', ['-s', 'LABEL', '-o', 'value', Path]);
  if Result.ExitCode <> 0 then
    WriteLogAndRaise(Format(S_ProcessExitCode, ['blkid -s LABEL -o value ' + Path, Result.ExitCode, Result.Message]));
  APart.LabelName := Trim(Result.Message);
  {$else}
  APart.LabelName := 'test_label'
  {$endif}
end;

function QueryPartitionFileSystem(var APart: TPartedPartition): TExecResult;
var
  Path: String; // Partition path
begin
  Result.ExitCode := -1;
  {$ifndef TPARTED_TEST}
  // Immediately skip if this is unallocated space
  if APart.Number <= 0 then
    Exit;
  Path := APart.GetPartitionPath;
  Result := ExecS('blkid', ['-s', 'TYPE', '-o', 'value', Path]);
  if Result.ExitCode <> 0 then
    WriteLogAndRaise(Format(S_ProcessExitCode, ['blkid -s TYPE -o value ' + Path, Result.ExitCode, Result.Message]));
  APart.FileSystem := Trim(Result.Message);
  {$else}
  APart.LabelName := 'ext4'
  {$endif}
end;

// /bin/umount APath
function QueryPartitionUnmount(var APart: TPartedPartition): TExecResult;
var
  Path: String; // Partition path
begin
  Result.ExitCode := -1;
  {$ifndef TPARTED_TEST}
  // Immediately skip if this is unallocated space, or already unmounted
  if (APart.Number <= 0) or (not APart.IsMounted) then
    Exit;
  Path := APart.GetPartitionPath;
  Result := ExecS('umount', [Path]);
  if Result.ExitCode <> 0 then
    WriteLogAndRaise(Format(S_ProcessExitCode, ['umount ' + Path, Result.ExitCode, Result.Message]));
  // Update mount status
  APart.IsMounted := False;
  APart.MountPoint := '';
  {$else}
  {$endif}
end;

end.

