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

unit Parted.Logs;

{$I configs.inc}

interface

uses
  SysUtils, Classes, Types, StrUtils;

const
  LOG_PATH = '/var/log/tparted/log.txt';

type
  TPartedLogStatus = (
    lsInfo,
    lsError
  );

var
  Log: TStringList;

procedure WriteLog(Status: TPartedLogStatus; Text: String); overload;
procedure WriteLog(Path: String; Params: TStringDynArray); overload;
procedure WriteLogAndRaise(Text: String); overload;

implementation

uses
  Parted.Commons;

procedure WriteToLogFile(S: String);
var
  FS: TFileStream;
begin
  FS := TFileStream.Create(LOG_PATH, fmOpenWrite);
  try
    FS.Position := Pred(FS.Size);
    S := S + #10;
    FS.WriteBuffer(Pointer(S)^, Length(S) + 1);
  finally
    FS.Free;
  end;
end;

procedure TruncateLog;
begin
  if Log.Count > 10000 then
    Log.Delete(0);
end;

procedure WriteLog(Status: TPartedLogStatus; Text: String);
var
  S, S2: String;
  Texts: TStringDynArray;
begin
  TruncateLog;
  Texts := SplitString(Text, #10);
  for S in Texts do
  begin
    case Status of
      lsError:
        S2 := '[ERROR] ' + S;
      else
        S2 := S;
    end;
    Log.Add(S2);
    WriteToLogFile(S2);
  end;
end;

procedure WriteLog(Path: String; Params: TStringDynArray);
var
  S, I: String;
begin
  TruncateLog;
  S := '';
  S := S + '+ ' + Path;
  for I in Params do
    S := S + ' ' + I;
  Log.Add(S);
  WriteToLogFile(S);
end;

procedure WriteLogAndRaise(Text: String);
var
  S, S2: String;
  Texts: TStringDynArray;
begin
  TruncateLog;
  Texts := SplitString(Text, #10);
  for S in Texts do
  begin
    S2 := '[ERROR] ' + S;
    Log.Add(S2);
    WriteToLogFile(S2);
  end;
  raise ExceptionAbnormalExitCode.Create(Text);
end;

initialization
  Log := TStringList.Create;
  CreateDir('/var/log/tparted');
  if FileExists(LOG_PATH) then
    DeleteFile(LOG_PATH);
  FileClose(FileCreate(LOG_PATH));

finalization
  Log.Free;

end.