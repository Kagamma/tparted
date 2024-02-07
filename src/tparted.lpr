program TParted;

{$I configs.inc}

uses
  {$ifdef UNIX}
  CThreads, cwstring, Unix,
  {$endif}
  SysUtils, Classes, Types,
  FileSystem,
  // You must include file system implementation behind FileSystem!
  FileSystem.Ext,
  FileSystem.NTFS,
  FileSystem.BTRFS,
  FileSystem.Swap,
  FileSystem.XFS,
  FileSystem.JFS,
  FileSystem.ExFat,
  FileSystem.F2FS,
  FileSystem.Fat,
  FreeVision,
  Parted.Commons, Parted.Devices, Parted.Partitions,
  Parted.Operations, Parted.Logs,
  UI.Main, UI.Devices, UI.Partitions, UI.Commons, UI.Partitions.Create, UI.Partitions.Resize;

var
  Report: String;

begin
  UIMain.Init;
  try
    try
      UIMain.Run;
    except
      on E: Exception do
      begin
        // All exceptions need to be handled!
        // If it makes to this message box, then stop the app immediately!
        MsgBox(E.Message, nil, mfError + mfOKButton);
        DumpCallStack(Report);
        WriteLog(lsError, Report);
      end;
    end;
  finally
    UIMain.Done;
    {$ifdef UNIX}
    fpSystem('tput cnorm');
    {$endif}
  end;
end.
