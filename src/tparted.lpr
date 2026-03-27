program TParted;

{$I configs.inc}

uses
  CThreads, cwstring, Unix, BaseUnix,
  SysUtils, Classes, Types,
  Termio,
  FileSystem,
  // You must include file system implementation behind FileSystem!
  FileSystem.Ext,
  FileSystem.NTFS,
  FileSystem.BTRFS,
  FileSystem.Bcachefs,
  FileSystem.Swap,
  FileSystem.XFS,
  FileSystem.JFS,
  FileSystem.ExFat,
  FileSystem.F2FS,
  FileSystem.Fat,
  FileSystem.NILFS2,
  FreeVision,
  Parted.Commons, Locale, Parted.Devices, Parted.Partitions,
  Parted.Operations, Parted.Logs,
  UI.Main, UI.Devices, UI.Partitions, UI.Commons, UI.Partitions.Create, UI.Partitions.Resize;

var
  Report: String;
  OrigAttr: Termios;

procedure TermBackupAttr;
begin
  TcGetAttr(0, OrigAttr);
end;

procedure TermEnableRawExceptSig;
var
  Attr: Termios;
begin
  Attr := OrigAttr;
  // Disable echo, canonical mode
  Attr.c_lflag := Attr.c_lflag and not (ECHO or ICANON);
  // Disable Ctrl-S/Q and CR-to-NL translation
  Attr.c_iflag := Attr.c_iflag and not (IXON or ICRNL);
  // Disable output processing
  Attr.c_oflag := Attr.c_oflag and not (OPOST);
  TcSetAttr(0, TCSAFLUSH, Attr);
end;

procedure HandleSigInt(Sig: LongInt); cdecl;
begin
  case Sig of
    2:
      begin
        // Restore terminal before exiting
        fpSystem('clear');
        Halt(130);
      end;
  end;
end;

begin
  if FpGeteuid() <> 0 then
  begin
    Writeln(StdErr, S_RootRequired);
    Halt(1);
  end;
  TermBackupAttr;
  UIMain.Init;
  try
    try
      TermEnableRawExceptSig;
      fpSignal(SIGINT, @HandleSigInt);
      UIMain.Run;
    except
      on E: Exception do
      begin
        // All exceptions need to be handled!
        // If it makes to this message box, then stop the app immediately!
        DumpCallStack(Report);
        WriteLog(lsError, Report);
        MessageDlg(E.Message, nil, mfError + mfOKButton);
      end;
    end;
  finally
    UIMain.Done;
    fpSystem('tput cnorm');
  end;
end.
