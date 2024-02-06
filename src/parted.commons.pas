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

unit Parted.Commons;

{$I configs.inc}

interface

uses
  {$ifdef Unix}Unix,{$endif}
  SysUtils, Classes, Process, Types, StrUtils, RegExpr;

resourcestring
  S_OkButton = 'O~K~';
  S_CancelButton = '~C~ancel';
  S_CloseButton = '~C~lose';
  S_YesButton = '~Y~es';
  S_NoButton = '~N~o';
  S_WarningTitle = 'Warning';
  S_ErrorTitle = 'Error';
  S_InformationTitle = 'Information';
  S_ConfirmationTitle = 'Confirm';
  S_PartitionIsMounted = '"%s" is being mounted!'#13'Please unmount it first.';
  S_PartitionIsUnallocated = 'This space is unallocated!'#13'Please create a partition first.';
  S_PartitionAskDelete = '%s'#13'Do you want to delete?';
  S_PartitionWindowTitle = 'Device: %s (%s) %s';
  S_DeviceAlreadyOpened = 'Device "%s" is already opened!';
  S_MaxDeviceWindow = 'You can only open %d device windows at once.';
  S_DeviceInfo = 'P.Table: %s, Transport: %s';
  S_PendingOperations = 'Pending operation(s): %d';
  S_InfoButton = '~I~nfo';
  S_CreateButton = '~C~reate';
  S_DeleteButton = '~D~elete';
  S_FormatButton = '~F~ormat';
  S_ResizeButton = '~R~esize';
  S_UnmountButton = 'Un~m~ount';
  S_LabelButton = '~L~abel/Name';
  S_FlagButton = 'Fla~g~s';
  S_UndoButton = '~U~ndo';
  S_EmptyButton = '~E~mpty';
  S_ApplyOperationButton = '~A~pply Operations';
  S_CloseMessage = #3'%s'#13#3'You have pending operations.'#13#3'Are you sure you want to close?';
  S_Help = '~H~elp';
  S_About = '~A~bout';
  S_Devices = '~D~evices';
  S_Quit = '~Q~uit';
  S_Log = 'Display ~L~ogs';
  S_RefreshDevices = '~R~efresh Devices';
  S_QuitMessage = #3'You have pending operations.'#13#3'Quit TParted?';
  S_AboutMessage = #3'TParted (%s) by kagamma'#13#3'Built with Free Pascal %s'#13#3'This software is in beta state,'#13#3'Use it at your own risk!';
  S_LoadingPartitions = 'Loading partitions...';
  S_PartitionFileSystem = 'File System: %s';
  S_PartitionLabel = 'Label: %s';
  S_PartitionName = 'Name: %s';
  S_PartitionUUID = 'UUID: %s';
  S_PartitionType = 'Type: %s';
  S_PartitionSize = 'Size: %s (%s)';
  S_PartitionUsed = 'Used: %s (%s)';
  S_PartitionFree = 'Free: %s (%s)';
  S_PartitionStart = 'Start: %s (%s)';
  S_PartitionEnd = 'End: %s (%s)';
  S_PartitionFlags = 'Flags: %s';
  S_PartitionMount = 'Mount: %s';
  S_InputLabelTitle = 'Change %s label';
  S_InputLabel = 'New label:';
  S_Partition = 'Partition';
  S_FileSystem = 'File System';
  S_FreeSpacePreceding = 'Preceding (MB)';
  S_NewSize = 'New size (MB)';
  S_FreeSpaceFollowing = 'Following (MB)';
  S_Size = 'Size';
  S_Used = 'Used';
  S_Flags = 'Flags';
  S_Label = 'Label';
  S_Name = 'Name';
  S_Logs = 'In-memory logs';
  S_PartitionUnmounted = #3'"%s" unmounted!';
  S_PartitionUnmounting = 'Unmounting %s...';
  S_CreatePartitionTableAsk = 'Device %s has no partition table.'#13'Do you want to create a GUID Partition Table?';
  S_ProcessExitCode = '"%s" exited with exit code %d: %s';
  S_FormatsDialogTitle = 'Format %s';
  S_FlagsDialogTitle = 'Edit %s flags';
  S_CreateDialogTitle = 'Create new partition';
  S_ResizeDialogTitle = 'Resize %s';
  S_MinPossibleSpace = 'Min.Possible (MB)'#13'%d';
  S_MaxPossibleSpace = 'Max.Possible (MB)'#13'%d';
  S_CreatingGPT = 'Creating GUID Partition Table...';
  S_MaximumPartitionReached = 'Maximum number of partitions reached!';
  S_OperationAdvise = 'Are you sure you want to apply the pending operations to %s? Editing partitions has the potential to cause LOSS of DATA.';
  S_Executing = 'Performing %d/%d operations...';

type
  TExecResult = record
    ExitCode: LongInt;
    Message: String;
  end;

  TExecResultDA = record
    ExitCode: LongInt;
    MessageArray: TStringDynArray;
  end;

  ExceptionAbnormalExitCode = class(Exception);

function GetTempMountPath(Path: String): String;
procedure DumpCallStack(var Report: String);
function Match(S: String; RegexPattermArray: TStringDynArray): TStringDynArray;
procedure ExecSystem(const S: String);
function ExecS(const Prog: String; const Params: TStringDynArray): TExecResult;
function ExecSA(const Prog: String; const Params: TStringDynArray): TExecResultDA;

// Converts TStringList to TStringDynArray
function SLToSA(const SL: Classes.TStringList): TStringDynArray;
// Converts TStringDynArray to string
function SAToS(const SA: TStringDynArray): String; overload;
// Converts TStringDynArray to string, separated by ADelimiter
function SAToS(const SA: TStringDynArray; const ADelimiter: Char): String; overload;
// Load a file to TStringDynArray
function FileToSA(const AName: String): TStringDynArray;
// Load a file to String
function FileToS(const AName: String): String;

// Converts bytes to TB
function BToTB(const V: QWord): Double;
// Converts bytes to GB
function BToGB(const V: QWord): Double;
// Converts bytes to MB
function BToMB(const V: QWord): Double;
// Converts bytes to KB
function BToKB(const V: QWord): Double;
// Returns size (KB, MB, GB) depending on how large V is.
function SizeString(const V: Int64): String;
// Returns size in bytes.
function SizeByteString(const V: Int64): String;
// Extract number from a text like this: "34135123B"
function ExtractQWordFromSize(S: String): QWord;
// Converts bytes to floor(MB)
function BToMBFloor(const V: QWord): QWord;
// Converts bytes to ceil(MB)
function BToMBCeil(const V: QWord): QWord;
// Converts bytes to floor(KB)
function BToKBFloor(const V: QWord): QWord;

// Allocate new PUnicodeString from given string
function GetUnicodeStr(const S: String): PUnicodeString;

// Set text attribute
function TextAttr(const FG, BG, Blink: Byte): Char; inline;

// Convert a flag to an actual value
function FlagToS(const F: LongWord; const FlagNames: TStringDynArray): String;
// Convet a flag to multiple values
function FlagToSA(const F: LongWord; const FlagNames: TStringDynArray): TStringDynArray;
// Convert a value to flag
function SToFlag(const V: String; const FlagNames: TStringDynArray): LongWord;
// Convert multiple values to flag
function SAToFlag(const Values: TStringDynArray; const FlagNames: TStringDynArray): LongWord;
// Convert a value to index
function SToIndex(const V: String; const FlagNames: TStringDynArray): LongInt;

implementation

uses
  Math, FreeVision, UI.Commons, Parted.Logs;

function GetTempMountPath(Path: String): String;
begin
  Result := GetTempMountPath(Path);
end;

procedure DumpCallStack(var Report: String);
var
  I: Longint;
  prevbp: Pointer;
  CallerFrame,
  CallerAddress,
  bp: Pointer;
const
  MaxDepth = 20;
begin
  Report := '';
  bp := get_frame;
  // This trick skip SendCallstack item
  // bp:= get_caller_frame(get_frame);
  try
    prevbp := bp - 1;
    I := 0;
    while bp > prevbp do
    begin
       CallerAddress := get_caller_addr(bp);
       CallerFrame := get_caller_frame(bp);
       if (CallerAddress = nil) then
         Break;
       Report := Report + BackTraceStrFunc(CallerAddress) + LineEnding;
       Inc(I);
       if (I >= MaxDepth) or (CallerFrame = nil) then
         Break;
       prevbp := bp;
       bp := CallerFrame;
     end;
   except
     { prevent endless dump if an exception occured }
   end;
  MsgBox(Report, nil, mfError + mfOKButton);
end;

function Match(S: String; RegexPattermArray: TStringDynArray): TStringDynArray;
var
  I: LongInt = 0;
  RE: TRegExpr;
  RP: String;
begin
  SetLength(Result, 0);
  for RP in RegexPattermArray do
  begin
    RE := TRegExpr.Create(RP);
    try
      if RE.Exec(S) then
      begin
        SetLength(Result, I + 1);
        Result[I] := RE.Match[1];
        S := StringReplace(S, Result[I], '', []);
      end;
    finally
      RE.Free;
    end;
    Inc(I);
  end;
end;

function SLToSA(const SL: Classes.TStringList): TStringDynArray;
var
  I: LongInt;
begin
  SetLength(Result, SL.Count);
  for I := 0 to Pred(SL.Count) do
  begin
    Result[I] := SL[I];
  end;
end;

function SAToS(const SA: TStringDynArray): String;
var
  I: LongInt;
begin
  Result := '';
  for I := 0 to High(SA) do
    Result := Result + SA[I];
end;

function SAToS(const SA: TStringDynArray; const ADelimiter: Char): String;
var
  I: LongInt;
begin
  Result := '';
  for I := 0 to High(SA) do
  begin
    Result := Result + SA[I];
    if I < High(SA) then
      Result := Result + ADelimiter;
  end;
end;

function FileToSA(const AName: String): TStringDynArray;
var
  SL: Classes.TStringList;
begin
  SL := Classes.TStringList.Create;
  try
    SL.LoadFromFile(AName);
    Result := SLToSA(SL);
  finally
    SL.Free;
  end;
end;

function FileToS(const AName: String): String;
var
  SL: Classes.TStringList;
begin
  SL := Classes.TStringList.Create;
  try
    SL.LoadFromFile(AName);
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

procedure ExecSystem(const S: String);
begin
  WriteLog(lsInfo, '+ ' + S);
  fpSystem(S);
  Sleep(100);
end;

function ExecS(const Prog: String; const Params: TStringDynArray): TExecResult;
var
  I: LongInt;
  P: TProcess;
  S: String;
  SL: Classes.TStringList;
begin
  WriteLog(Prog, Params);
  Result.ExitCode := -1;
  P := TProcess.Create(nil);
  SL := Classes.TStringList.Create;
  try
    P.Executable := Prog;
    for S in Params do
      P.Parameters.Add(S);
    P.Options := P.Options + [poWaitOnExit, poUsePipes];
    P.Execute;
    Result.ExitCode := P.ExitStatus;
    if Result.ExitCode = 0 then
    begin
      SL.LoadFromStream(P.Output);
    end else
    begin
      SL.LoadFromStream(P.stderr);
    end;
    Result.Message := SL.Text;
  finally
    SL.Free;
    P.Free;
  end;
end;

function ExecSA(const Prog: String; const Params: TStringDynArray): TExecResultDA;
var
  I: LongInt;
  P: TProcess;
  S: String;
  SL: Classes.TStringList;
begin
  WriteLog(Prog, Params);
  Result.ExitCode := -1;
  P := TProcess.Create(nil);
  SL := Classes.TStringList.Create;
  try
    P.Executable := Prog;
    for S in Params do
      P.Parameters.Add(S);
    P.Options := P.Options + [poWaitOnExit, poUsePipes];
    P.Execute;
    Result.ExitCode := P.ExitStatus;
    if Result.ExitCode = 0 then
    begin
      SL.LoadFromStream(P.Output);
    end else
    begin
      SL.LoadFromStream(P.stderr);
    end;
    Result.MessageArray := SLToSA(SL);
  finally
    SL.Free;
    P.Free;
  end;
end;

function BToTB(const V: QWord): Double;
begin
  Result := V / 1024 / 1024 / 1024 / 1024;
end;

function BToGB(const V: QWord): Double;
begin
  Result := V / 1024 / 1024 / 1024;
end;

function BToMB(const V: QWord): Double;
begin
  Result := V / 1024 / 1024;
end;

function BToMBFloor(const V: QWord): QWord;
begin
  Result := Floor(V / 1024 / 1024);
end;

function BToMBCeil(const V: QWord): QWord;
begin
  Result := Ceil(V / 1024 / 1024);
end;

function BToKBFloor(const V: QWord): QWord;
begin
  Result := Floor(V / 1024);
end;

function BToKB(const V: QWord): Double;
begin
  Result := V / 1024;
end;

function SizeString(const V: Int64): String;
begin
  if V < 0 then
  begin
    Result := '---';
  end else
  if V >= 1024 * 1024 * 1024 * 1024 then
  begin
    Result := Format('%.1fT', [BToTB(V)]);
  end else
  if V >= 1024 * 1024 * 1024 then
  begin
    Result := Format('%.1fG', [BToGB(V)]);
  end else
  if V >= 1024 * 1024 then
  begin
    Result := Format('%.1fM', [BToMB(V)]);
  end else
  begin
    Result := Format('%.1fK', [BToKB(V)]);
  end;
end;

function SizeByteString(const V: Int64): String;
var
  S: String;
  I, J: LongInt;
begin
  if V < 0 then
  begin
    Result := '---';
  end else
  begin
    S := IntToStr(V);
    J := 1;
    for I := Pred(Length(S)) downto 1 do
    begin
      Inc(J);
      if (J mod 3 = 0) and (I > 1) then
        Insert(',', S, I);
    end;
    Result := Format('%s bytes', [S]);
  end;
end;

function ExtractQWordFromSize(S: String): QWord;
begin
  Delete(S, Length(S), 1);
  Result := StrToQWord(S);
end;

function GetUnicodeStr(const S: String): PUnicodeString;
begin
  New(Result);
  Result^ := UTF8Decode(S);
end;

function TextAttr(const FG, BG, Blink: Byte): Char; inline;
begin
  Result := Char((Blink shl 7) or ((FG and %00000111) shl 4) or (BG and %00001111));
end;

function FlagToS(const F: LongWord; const FlagNames: TStringDynArray): String;
var
  I: LongInt;
begin
  Result := '';
  for I := 0 to 31 do
  begin
    if I > High(FlagNames) then
      Exit;
    if (F shr I) and 1 = 1 then
    begin
      Result := FlagNames[I];
      Exit;
    end;
  end;
end;

function FlagToSA(const F: LongWord; const FlagNames: TStringDynArray): TStringDynArray;
var
  I: LongInt;
  L: LongInt = 0;
begin
  for I := 0 to 31 do
  begin
    if I > High(FlagNames) then
      Exit;
    if (F shr I) and 1 = 1 then
    begin
      Inc(L);
      SetLength(Result, L);
      Result[L - 1] := FlagNames[I];
    end;
  end;
end;

function SToFlag(const V: String; const FlagNames: TStringDynArray): LongWord;
var
  I: LongInt;
begin
  Result := 0;
  for I := 0 to High(FlagNames) do
  begin
    if V = FlagNames[I] then
    begin
      Result := 1 shl I;
      Exit;
    end;
  end;
end;

function SAToFlag(const Values: TStringDynArray; const FlagNames: TStringDynArray): LongWord;
var
  I, J: LongInt;
  V: String;
begin
  Result := 0;
  for J := 0 to High(Values) do
  begin
    V := Values[J];
    for I := 0 to High(FlagNames) do
    begin
      if V = FlagNames[I] then
      begin
        Result := Result or (1 shl I);
      end;
    end;
  end;
end;

function SToIndex(const V: String; const FlagNames: TStringDynArray): LongInt;
var
  I: LongInt;
begin
  Result := -1;
  if V = '' then
    Exit;
  for I := 0 to High(FlagNames) do
  begin
    if V = FlagNames[I] then
    begin
      Result := I;
      Exit;
    end;
  end;
end;

initialization
  DefaultFormatSettings.DecimalSeparator := '.';

end.

