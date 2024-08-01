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
  SysUtils, Classes, Generics.Collections, Process, Types, StrUtils, RegExpr, Locale;

type
  TPartedPathDict = specialize TDictionary<String, String>;

  TExecResult = record
    ExitCode: LongInt;
    Message: String;
  end;

  TExecResultDA = record
    ExitCode: LongInt;
    MessageArray: TStringDynArray;
  end;

  ExceptionAbnormalExitCode = class(Exception);

  TSignalMethod = procedure(SL: TStringList) of object;

  TPartedStringHelper = type helper(TStringHelper) for String
    function ToUnicode: UnicodeString;
  end;

  TPartedUnicodeStringHelper = type helper for UnicodeString
    function ToUTF8: String;
  end;

function GetTempMountPath(Path: String): String;
// Mount a partition to path
procedure Mount(Path, PathMnt: String);
// Unmount partition
procedure Unmount(Path, PathMnt: String);
procedure DumpCallStack(var Report: String);
function Match(S: String; RegexPattermArray: TStringDynArray): TStringDynArray;
function ProgramExists(const Prog: String): Boolean;
procedure ExecSystem(const S: String);
function ExecS(Prog: String; const Params: TStringDynArray): TExecResult;
function ExecSA(Prog: String; const Params: TStringDynArray): TExecResultDA;
function ExecAsync(Prog: String; const Params: TStringDynArray; const ASignal: TSignalMethod): TExecResult;

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

// Pad a string and limit the length
function PadRightLimit(S: String; Limit: LongInt): String;
function PadLeftLimit(S: String; Limit: LongInt): String;
function PadCenterLimit(S: String; Limit: LongInt): String;

implementation

uses
  Math, FreeVision, UI.Commons, Parted.Logs, Lazarus.UTF8;

var
  TempRandom: String;
  PathDict: TPartedPathDict; // Stores file paths in dictionary

function TPartedStringHelper.ToUnicode: UnicodeString;
begin
  Result := UTF8Decode(Self);
end;

function TPartedUnicodeStringHelper.ToUTF8: String;
begin
  Result := UTF8Encode(Self);
end;

function GetTempMountPath(Path: String): String;
begin
  Result := '/tmp/tparted_' + StringReplace(Path, '/', '_', [rfReplaceAll]) + TempRandom;
end;

procedure Mount(Path, PathMnt: String);
begin
  ExecSystem(Format('mkdir -p "%s" > /dev/null', [PathMnt]));
  ExecSystem(Format('mount "%s" "%s" > /dev/null', [Path, PathMnt]));
end;

procedure Unmount(Path, PathMnt: String);
begin
  ExecSystem(Format('umount "%s" > /dev/null', [Path]));
  ExecSystem(Format('rm -d "%s" > /dev/null', [PathMnt]));
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

function FindProgramViaEnv(const Prog: String): String;
var
  Paths: TStringArray;
  S, Path: String;
begin
  if PathDict.ContainsKey(Prog) then
  begin
    Exit(PathDict[Prog]);
  end;
  Paths := SplitString(GetEnvironmentVariable('PATH'), ':');
  // Try to perform a search for it by look through paths...
  for S in Paths do
  begin
    Path := S + '/' + Prog;
    if FileExists(Path) then
    begin
      PathDict.Add(Prog, Path);
      Exit(Path);
    end;
  end;
  Result := '';
end;

function FindProgram(const Prog: String): String;
begin
  Result := FindProgramViaEnv(Prog);
  if Result = '' then
  begin
    // Still not found? Raise exception!
    raise Exception.Create('Cannot find executable file: ' + Prog);
  end;
end;

function ProgramExists(const Prog: String): Boolean;
begin
  if FindProgramViaEnv(Prog) = '' then
  begin
    Result := False;
  end else
  begin
    Result := True;
  end;
end;

function ExecS(Prog: String; const Params: TStringDynArray): TExecResult;
var
  I: LongInt;
  P: TProcess;
  S: String;
  SL: Classes.TStringList;
begin
  WriteLog(Prog, Params);
  Prog := FindProgram(Prog);
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
      SL.LoadFromStream(P.Output)
    else
      SL.LoadFromStream(P.StdErr);
    Result.Message := SL.Text;
    WriteLog(lsInfo, SL.Text);
  finally
    SL.Free;
    P.Free;
  end;
end;

function ExecSA(Prog: String; const Params: TStringDynArray): TExecResultDA;
var
  I: LongInt;
  P: TProcess;
  S: String;
  SL: Classes.TStringList;
begin
  WriteLog(Prog, Params);
  Prog := FindProgram(Prog);
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
      SL.LoadFromStream(P.Output)
    else
      SL.LoadFromStream(P.StdErr);
    Result.MessageArray := SLToSA(SL);
    WriteLog(lsInfo, SL.Text);
  finally
    SL.Free;
    P.Free;
  end;
end;

function ExecAsync(Prog: String; const Params: TStringDynArray; const ASignal: TSignalMethod): TExecResult;
var
  I: LongInt;
  P: TProcess;
  S: String;
  SL: Classes.TStringList;

  procedure PollForData;
  begin
    SL.Clear;
    SL.LoadFromStream(P.Output);
    if SL.Count > 0 then
    begin
      if ASignal <> nil then
        ASignal(SL);
      Result.Message := Result.Message + SL.Text;
    end;
  end;

begin
  WriteLog(Prog, Params);
  Prog := FindProgram(Prog);
  Result.ExitCode := -1;
  P := TProcess.Create(nil);
  SL := Classes.TStringList.Create;
  try
    P.Executable := Prog;
    for S in Params do
      P.Parameters.Add(S);
    P.Options := P.Options + [poUsePipes, poStderrToOutPut] - [poWaitOnExit];
    P.Execute;
    while P.Running do
    begin
      PollForData;
      Sleep(1000);
    end;
    Result.ExitCode := P.ExitStatus;
    PollForData;
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
    S := V.ToString;
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
  Result := S.ToInt64;
end;

function GetUnicodeStr(const S: String): PUnicodeString;
begin
  New(Result);
  Result^ := S.ToUnicode;
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

function PadRightLimit(S: String; Limit: LongInt): String;
var
  L, I: LongInt;
  SR: String;
begin
  L := UTF8TerminalLength(S);
  if L > Limit then
  begin
    SR := '';
    I := 0;
    while UTF8TerminalLength(SR) < Limit - 1 do
    begin
      Inc(I);
      SR := SR + UTF8Copy(S, I, 1);
    end;
  end else
    SR := S;
  Result := UTF8PadRight(SR, Limit);
end;

function PadLeftLimit(S: String; Limit: LongInt): String;
var
  L, I: LongInt;
  SR: String;
begin
  L := UTF8TerminalLength(S);
  if L > Limit then
  begin
    SR := '';
    I := 0;
    while UTF8TerminalLength(SR) < Limit - 1 do
    begin
      Inc(I);
      SR := SR + UTF8Copy(S, I, 1);
    end;
  end else
    SR := S;
  Result := UTF8PadLeft(SR, Limit);
end;

function PadCenterLimit(S: String; Limit: LongInt): String;
var
  L, I: LongInt;
  SR: String;
begin
  L := UTF8TerminalLength(S);
  if L > Limit then
  begin
    SR := '';
    I := 0;
    while UTF8TerminalLength(SR) < Limit - 1 do
    begin
      Inc(I);
      SR := SR + UTF8Copy(S, I, 1);
    end;
  end else
    SR := S;
  Result := UTF8PadCenter(SR, Limit);
end;

initialization
  Randomize;
  TempRandom := Random($FFFFFFFF).ToString;
  DefaultFormatSettings.DecimalSeparator := '.';
  PathDict := TPartedPathDict.Create;

finalization
  PathDict.Free;

end.
