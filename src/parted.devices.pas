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

unit Parted.Devices;

{$I configs.inc}

interface

uses
  Classes, SysUtils, Types, Parted.Commons, StrUtils, Parted.Logs{$ifdef UNIX}, Unix{$endif};

type
  PPartedDevice = ^TPartedDevice;
  PPartedPartition = ^TPartedPartition;
  TPartedPartition = record
    Device: PPartedDevice;
    Number: LongInt;
    PartStart: Int64; // Start of partition in bytes
    PartEnd: Int64; // End of partition in bytes
    PartSize: Int64;
    PartUsed: Int64;
    PartFree: Int64;
    Kind: String;
    KindUUID: String;
    UUID: String;
    FileSystem: String;
    Flags: TStringDynArray;
    LabelName: String;
    Name: String;
    IsMounted: Boolean;
    MountPoint: String;
    CanBeResized: Boolean;
    OpID: QWord; // The ID used by operations
    Next, Prev: PPartedPartition;
    procedure Init;
    // Get part start, but set to 0 for the first space
    function PartStartZero: Int64;
    // Get part size, but set to 0 for the first space
    function PartSizeZero: Int64;
    // Get part path for display (unallocated space included)
    function GetPartitionPathForDisplay: String;
    // Get part path
    function GetPartitionPath: String;
    // Check to see if AFlag exists in this partition
    function ContainsFlag(AFlag: String): Boolean;
    // Unmount this partition. Returns true if succeed.
    function Unmount: Boolean;
    // Possible expand size
    function GetPossibleExpandSize: QWord;
    // Split current partition into multiple partitions, aligned in MB
    procedure SplitPartitionInMB(const Preceding, Size: Int64);
    // Resize current partition, aligned in MB
    procedure ResizePartitionInMB(const Preceding, Size: Int64);
    // Guess and assign a number for this partition
    procedure AutoAssignNumber;
    // Tell the kernel about the changes in this partition
    procedure Probe;
  end;
  TPartedPartitionDynArray = array of TPartedPartition;

  TPartedDevice = record
    Name: String;
    Path: String;
    Size: QWord;
    SizeApprox: String;
    Transport: String;
    LogicalSectorSize: LongInt;
    PhysicalSectorSize: LongInt;
    MaxPartitions: LongInt;
    Table: String;
    UUID: String;
    PartitionRoot: PPartedPartition;
    procedure Init;
    procedure Done;
    procedure ClearAllPartitions;
    procedure UpdatePartitionOwner;
    procedure InsertPartition(const PPart: PPartedPartition);
    function GetPartitionAt(const Index: LongInt): PPartedPartition;
    function GetPartitionCount: LongInt;
    function GetPrimaryPartitionCount: LongInt;
    // Merge all possible unallocated space that is closed together into big one
    procedure MergeUnallocatedSpace;
    function Clone: PPartedDevice;
  end;
  TPartedDeviceArray = array of TPartedDevice;

// Parse for device info from "parted -l -m" string
function ParseDevicesFromStringArray(const SA: TStringDynArray): TPartedDeviceArray;
function QueryDeviceArray: TPartedDeviceArray;
function QueryDeviceExists(const APath: String): TExecResult;
function QueryCreateGPT(const APath: String): TExecResult;

implementation

uses
  Parted.Partitions;

var
  OpIDCounter: QWord = 0;

procedure TPartedPartition.Init;
begin
  FillChar(Self, SizeOf(Self), 0);
  Self.PartStart := -1;
  Self.PartEnd := -1;
  Self.PartSize := -1;
  Self.PartUsed := -1;
  Self.PartFree := -1;
  Inc(OpIDCounter);
  Self.OpID := OpIDCounter;
end;

function TPartedPartition.PartStartZero: Int64;
begin
  if (Self.Number = 0) and (Self.Prev = nil) then
    Result := 0
  else
    Result := Self.PartStart;
end;

function TPartedPartition.PartSizeZero: Int64;
begin
  if (Self.Number = 0) and (Self.Prev = nil) then
    Result := Self.PartEnd + 1
  else
    Result := Self.PartSize;
end;

function TPartedPartition.GetPartitionPathForDisplay: String;
var
  IsMountedSymbol: Char;
begin
  if Self.IsMounted then
    IsMountedSymbol := 'M'
  else
    IsMountedSymbol := ' ';
  if Self.Number <> 0 then
    Result := IsMountedSymbol + Self.GetPartitionPath
  else
  if Self.Number = 0 then
    Result := ' unallocated';
end;

function TPartedPartition.GetPartitionPath: String;
begin
  if Pos('nvme', Self.Device^.Path) > 0 then
    Result := Self.Device^.Path + 'p' // NVME
  else
    Result := Self.Device^.Path; // SATA
  //
  if Self.Number > 0 then
    Result := Result + IntToStr(Self.Number)
  else
  if Self.Number < 0 then
    Result := '?' + IntToStr(-Self.Number)
end;

function TPartedPartition.ContainsFlag(AFlag: String): Boolean;
var
  I: LongInt;
begin
  for I := 0 to High(Self.Flags) do
    if AFlag = Self.Flags[I] then
      Exit(True);
  Exit(False);
end;

function TPartedPartition.Unmount: Boolean;
var
  ExecResult: TExecResult;
begin
  Result := False;
  // Do no try to unmount if this is a swap partition
  if Self.FileSystem = 'linux-swap' then
  begin
    ExecResult := ExecS('bin/umount', [Self.GetPartitionPath]);
    if ExecResult.ExitCode = 0 then
    begin
      Self.IsMounted := False;
      Result := True;
    end;
  end;
end;

function TPartedPartition.GetPossibleExpandSize: QWord;
begin
  Result := Self.PartSizeZero;
  if (Self.Prev <> nil) and (Self.Prev^.Number = 0) then
  begin
    Result := Result + Self.Prev^.PartSizeZero;
  end;
  if (Self.Next <> nil) and (Self.Next^.Number = 0) then
  begin
    Result := Result + Next^.PartSizeZero;
  end;
end;

procedure TPartedPartition.SplitPartitionInMB(const Preceding, Size: Int64);
var
  StartAligned,
  EndAligned: Int64; // Start and End of expected new partition, in bytes
  NewPrevPart: PPartedPartition = nil;
  NewNextPart: PPartedPartition = nil;
begin
  StartAligned := (BToMBCeil(Self.PartStartZero) + Preceding) * (1024 * 1024);
  EndAligned := (BToMBFloor(Self.PartStartZero) + Preceding + Size) * (1024 * 1024) - 1;
  if StartAligned > Self.PartStart then // Equal or lower value mean we dont need to create a new prev part
  begin
    New(NewPrevPart);
    NewPrevPart^.Init;
    NewPrevPart^.Device := Self.Device;
    NewPrevPart^.PartStart := Self.PartStart;
    NewPrevPart^.PartEnd := StartAligned - 1;
    NewPrevPart^.PartSize := NewPrevPart^.PartEnd - NewPrevPart^.PartStart + 1;
    NewPrevPart^.Next := @Self;
    NewPrevPart^.Prev := Self.Prev;
    if Self.Prev <> nil then
      Self.Prev^.Next := NewPrevPart;
    Self.Prev := NewPrevPart;
    Self.PartStart := StartAligned;
    if Self.Device^.PartitionRoot = @Self then // This new prev partition is the new root?
      Self.Device^.PartitionRoot := NewPrevPart;
  end;
  if EndAligned < Self.PartEnd then // Equal or higher value mean we dont need to create a new next part
  begin
    New(NewNextPart);
    NewNextPart^.Init;
    NewNextPart^.Device := Self.Device;
    NewNextPart^.PartStart := EndAligned + 1;
    NewNextPart^.PartEnd := Self.PartEnd;
    NewNextPart^.PartSize := NewNextPart^.PartEnd - NewNextPart^.PartStart + 1;
    NewNextPart^.Prev := @Self;
    NewNextPart^.Next := Self.Next;
    if Self.Next <> nil then
      Self.Next^.Prev := NewNextPart;
    Self.Next := NewNextPart;
    Self.PartEnd := EndAligned;
  end;
  Self.PartSize := Self.PartEnd - Self.PartStart + 1;
end;

procedure TPartedPartition.ResizePartitionInMB(const Preceding, Size: Int64);
var
  StartAligned,
  EndAligned: Int64; // Start and End of partition, in bytes
  NewPrevPart: PPartedPartition = nil;
  NewNextPart: PPartedPartition = nil;
  Tmp: PPartedPartition;
begin
  // Create a new unallocated space at the left in case there's none, and preceding is > 0
  if (Preceding > 0) and (Self.Prev <> nil) and (Self.Prev^.Number <> 0) then
  begin
    New(Tmp);
    Tmp^.Init;
    Tmp^.Device := Self.Device;
    Tmp^.PartStart := Self.PartStart;
    Tmp^.PartEnd := Self.PartStart;
    Tmp^.PartSize := 0;
    Tmp^.Next := @Self;
    Tmp^.Prev := Self.Prev;
    if Self.Prev <> nil then
      Self.Prev^.Next := Tmp;
    Self.Prev := Tmp;
  end;
  // Create a new temporary unallocated space on the right side in case there's none
  if ((Self.Next <> nil) and (Self.Next^.Number <> 0)) or (Self.Next = nil) then
  begin
    New(Tmp);
    Tmp^.Init;
    Tmp^.Device := Self.Device;
    Tmp^.PartStart := Self.PartEnd + 1;
    Tmp^.PartEnd := Self.PartEnd + 1;
    Tmp^.PartSize := 0;
    Tmp^.Prev := @Self;
    Tmp^.Next := Self.Next;
    if Self.Next <> nil then
      Self.Next^.Prev := Tmp;
    Self.Next := Tmp;
  end;
  //
  if (Self.Prev <> nil) and (Self.Prev^.Number = 0) then
    StartAligned := Self.Prev^.PartStartZero
  else
    StartAligned := Self.PartStartZero;
  StartAligned := (BToMBCeil(StartAligned) + Preceding) * (1024 * 1024);
  EndAligned := (BToMBCeil(StartAligned) + Size) * (1024 * 1024) - 1;
  Self.PartStart := StartAligned;
  Self.PartEnd := EndAligned;
  // Adjust size of the left unallocated space
  if (Self.Prev <> nil) and (Self.Prev^.Number = 0) then
  begin
    Self.Prev^.PartEnd := StartAligned - 1;
    Self.Prev^.PartSize := Self.Prev^.PartEnd - Self.Prev^.PartStart + 1;
    if Self.Prev^.PartSize <= 0 then
    begin
      Tmp := Self.Prev;
      Self.Prev := Tmp^.Prev;
      Tmp^.Prev^.Next := @Self;
      Dispose(Tmp);
    end;
  end;
  // Adjust size of the right unallocated space
  if (Self.Next <> nil) and (Self.Next^.Number = 0) then
  begin
    Self.Next^.PartStart := EndAligned + 1;
    Self.Next^.PartSize := Self.Next^.PartEnd - Self.Next^.PartStart + 1;
    if Self.Next^.PartSize <= 0 then
    begin
      Tmp := Self.Next;
      Self.Next := Tmp^.Next;
      Tmp^.Next^.Prev := @Self;
      Dispose(Tmp);
    end;
  end;
  Self.PartSize := Self.PartEnd - Self.PartStart + 1;
end;

// --------------------------

procedure TPartedDevice.Init;
begin
  ClearAllPartitions;
end;

procedure TPartedDevice.Done;
begin
  ClearAllPartitions;
end;

procedure TPartedDevice.ClearAllPartitions;
var
  P, PPart: PPartedPartition;
begin
  PPart := Self.PartitionRoot;
  while PPart <> nil do
  begin
    P := PPart^.Next;
    Dispose(PPart);
    PPart := P;
  end;
  Self.PartitionRoot := nil;
end;

procedure TPartedDevice.UpdatePartitionOwner;
var
  PPart: PPartedPartition;
begin
  PPart := Self.PartitionRoot;
  while PPart <> nil do
  begin
    PPart^.Device := @Self;
    PPart := PPart^.Next;
  end;
end;

procedure TPartedDevice.InsertPartition(const PPart: PPartedPartition);
var
  P: PPartedPartition;
begin
  PPart^.Prev := nil;
  PPart^.Next := nil;
  if Self.PartitionRoot = nil then
    Self.PartitionRoot := PPart
  else
  begin
    P := Self.PartitionRoot;
    while P^.Next <> nil do
      P := P^.Next;
    P^.Next := PPart;
    PPart^.Prev := P;
  end;
  PPart^.Device := @Self;
end;

function TPartedDevice.GetPartitionAt(const Index: LongInt): PPartedPartition;
var
  I: LongInt = 0;
begin
  Result := Self.PartitionRoot;
  while (Result^.Next <> nil) and (I < Index) do
  begin
    Result := Result^.Next;
    Inc(I);
  end;
end;

function TPartedDevice.GetPartitionCount: LongInt;
var
  P: PPartedPartition;
begin
  Result := 0;
  P := Self.PartitionRoot;
  while P <> nil do
  begin
    P := P^.Next;
    Inc(Result);
  end;
end;

function TPartedDevice.GetPrimaryPartitionCount: LongInt;
var
  P: PPartedPartition;
begin
  Result := 0;
  P := Self.PartitionRoot;
  while P <> nil do
  begin
    if P^.Kind = 'primary' then
      Inc(Result);
    P := P^.Next;
  end;
end;

function TPartedDevice.Clone: PPartedDevice;
var
  PPart, P: PPartedPartition;
begin
  New(Result);
  Result^ := Self;
  Result^.PartitionRoot := nil;
  P := Self.PartitionRoot;
  while P <> nil do
  begin
    New(PPart);
    PPart^ := P^;
    Result^.InsertPartition(PPart);
    P := P^.Next;
  end;
end;

procedure TPartedDevice.MergeUnallocatedSpace;
var
  P, Temp: PPartedPartition;
begin
  P := Self.PartitionRoot;
  while P <> nil do
  begin
    // P and the next partition are both unallocated
    if (P^.Next <> nil) and (P^.Number = 0) and (P^.Next^.Number = 0) then
    begin
      Temp := P^.Next;
      P^.PartEnd := Temp^.PartEnd;
      P^.PartSize := P^.PartSize + Temp^.PartSize;
      P^.Next := Temp^.Next;
      if P^.Next <> nil then
        P^.Next^.Prev := P;
      Dispose(Temp);
    end else
    if P^.PartSize = 0 then
    begin
      Temp := P;
      if P^.Next^.Prev <> nil then
        P^.Next^.Prev := P^.Prev;
      if P^.Prev^.Next <> nil then
        P^.Prev^.Next := P^.Next;
      P := P^.Next;
      Dispose(Temp);
    end else
      P := P^.Next;
  end;
end;

procedure TPartedPartition.AutoAssignNumber;
var
  Assigned: array of Boolean;
  P: PPartedPartition;
  N: LongInt;
  I: LongInt;
begin
  SetLength(Assigned, Self.Device^.MaxPartitions);
  FillChar(Assigned[0], Length(Assigned), 0);
  P := Self.Device^.PartitionRoot;
  while P <> nil do
  begin
    N := Abs(P^.Number);
    if N > 0 then
      Assigned[Pred(N)] := True;
    P := P^.Next;
  end;
  N := -1;
  for I := High(Assigned) downto Low(Assigned) do
  begin
    if not Assigned[I] then
      N := I + 1;
  end;
  if N = -1 then
    WriteLogAndRaise(S_MaximumPartitionReached);
  Self.Number := N;
end;

procedure TPartedPartition.Probe;
begin
  fpSystem('partprobe ' + Self.GetPartitionPath);
end;

// --------------------------

function ParseDevicesFromStringArray(const SA: TStringDynArray): TPartedDeviceArray;
var
  S: String;
  NextIsDeviceInfo: Boolean = False;
  LSA: TStringDynArray;
  DeviceCount: LongInt = 0;
begin
  SetLength(Result, 0);
  for S in SA do
  begin
    if NextIsDeviceInfo then
    begin
      SetLength(Result, DeviceCount + 1);
      LSA := SplitString(S, ':');
      // The first and second result is device and it's approx size
      Result[DeviceCount].Init;
      Result[DeviceCount].Path := LSA[0];
      Result[DeviceCount].SizeApprox := LSA[1];
      // The 6th one is device's name
      Result[DeviceCount].Name := LSA[6];
      NextIsDeviceInfo := False;
      Inc(DeviceCount);
      Continue;
    end;
    if S = 'BYT;' then
    begin
      NextIsDeviceInfo := True;
    end;
  end;
end;

function QueryDeviceArray: TPartedDeviceArray;
var
  ExecResult: TExecResultDA;
  Parts: TStringDynArray;
  I: LongInt;
begin
  {$ifndef TPARTED_TEST}
  ExecResult.ExitCode := -1;
  // Performs "parted -l -m" for general info about devices
  ExecResult := ExecSA('/bin/parted', ['-l', '-m']);
  Result := ParseDevicesFromStringArray(ExecResult.MessageArray);
  if ExecResult.ExitCode <> 0 then
    WriteLogAndRaise(Format(S_ProcessExitCode, ['parted -l -m', ExecResult.ExitCode, SAToS(ExecResult.MessageArray)]));
  {$else}
  // For testing purpose
  Result := ParseDevicesFromStringArray(FileToSA('../testdata/parted_output_machine.txt'));
  {$endif}
end;

function QueryDeviceExists(const APath: String): TExecResult;
begin
  {$ifndef TPARTED_TEST}
  Result.ExitCode := -1;
  Result := ExecS('/bin/blkid', [APath]);
  {$else}
  Result.ExitCode := 0;
  {$endif}
  if Result.ExitCode <> 0 then
    WriteLogAndRaise(Format(S_ProcessExitCode, ['blkid ' + APath, Result.ExitCode, Result.Message]));
end;

function QueryCreateGPT(const APath: String): TExecResult;
begin
  Result.ExitCode := -1;
  {$ifndef TPARTED_TEST}
  Result := ExecS('/bin/parted', [APath, 'mklabel', 'GPT']);
  if Result.ExitCode <> 0 then
    WriteLogAndRaise(Format(S_ProcessExitCode, ['parted ' + APath + ' mklabel GPT', Result.ExitCode, Result.Message]));
  {$endif}
end;

end.

