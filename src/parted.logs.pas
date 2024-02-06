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
  SysUtils, Classes, Types;

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

procedure WriteLog(Status: TPartedLogStatus; Text: String);
var
  S: String;
begin
  S := '';
  Text := StringReplace(Text, #10, '', [rfReplaceAll]);
  Text := StringReplace(Text, #13, '', [rfReplaceAll]);
  case Status of
    lsInfo: S := '';
    lsError: S := '[ERROR] ';
  end;
  S := S + Text;
  Log.Add(S);
end;

procedure WriteLog(Path: String; Params: TStringDynArray);
var
  S, I: String;
begin
  S := '';
  S := S + '+ ' + Path;
  for I in Params do
    S := S + ' ' + I;
  Log.Add(S);
end;

procedure WriteLogAndRaise(Text: String);
var
  S: String;
begin
  S := '';
  Text := StringReplace(Text, #10, '', [rfReplaceAll]);
  Text := StringReplace(Text, #13, '', [rfReplaceAll]);
  S := S + '[ERROR] ' + Text;
  Log.Add(S);
  raise ExceptionAbnormalExitCode.Create(Text);
end;

initialization
  Log := TStringList.Create;

finalization
  Log.Free;

end.