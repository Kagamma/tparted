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
  S := S + '+ ' + Path;
  for I in Params do
    S := S + ' ' + I;
  Log.Add(S);
end;

procedure WriteLogAndRaise(Text: String);
var
  S: String;
begin
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