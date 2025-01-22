unit Locale;

{$I configs.inc}

interface

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
  S_RefreshDevices = '~R~efresh Devices';
  S_QuitMessage = #3'You have pending operations.'#13#3'Quit TParted?';
  S_AboutMessage = #3'TParted (%s) by kagamma'#13#3'Built with Free Pascal %s';
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
  S_FileSystem = 'F.System';
  S_Create = 'Create';
  S_Move = 'Move';
  S_Shrink = 'Shrink';
  S_Grow = 'Grow';
  S_Dependencies = 'Dependencies';
  S_FreeSpacePreceding = 'Preceding (MB)';
  S_NewSize = 'New size (MB)';
  S_FreeSpaceFollowing = 'Following (MB)';
  S_Size = 'Size';
  S_Used = 'Used';
  S_Flags = 'Flags';
  S_Label = 'Label';
  S_Name = 'Name';
  S_Mount = 'Mount';
  S_Logs = 'In-memory Logs';
  S_MenuLogs = 'In-memory ~L~ogs';
  S_FileSystemSupport = 'File System Support';
  S_MenuFileSystemSupport = '~F~ile System Support';
  S_PartitionUnmounted = #3'"%s" unmounted!';
  S_PartitionUnmounting = 'Unmounting %s...';
  S_CreatePartitionTableAsk = 'Device %s has no partition table.'#13'Do you want to create a GUID Partition Table?';
  S_ProcessExitCode = '"%s" exited with exit code %d: %s';
  S_FormatsDialogTitle = 'Format %s';
  S_FlagsDialogTitle = 'Edit %s flags';
  S_CreateDialogTitle = 'Create new partition';
  S_ResizeDialogTitle = 'Move/Resize %s';
  S_MinPossibleSpace = 'Min.Possible (MB)'#13'%d';
  S_MaxPossibleSpace = 'Max.Possible (MB)'#13'%d';
  S_CreatingGPT = 'Creating GUID Partition Table...';
  S_MaximumPartitionReached = 'Maximum number of partitions reached!';
  S_OperationAdvise = 'Are you sure you want to apply the pending operations to %s? Editing partitions has the potential to cause LOSS of DATA.';
  S_Executing = 'Performing %d/%d operations...';
  S_VerifyMinSize = '%s requires a minimal size of %dMB!';
  S_VerifyMaxSize = '%s cannot larger than %dMB!';
  S_MenuWindow = '~W~indows';
  S_MenuPreviousWindow = '~P~revious Window';
  S_MenuNextWindow = '~N~ext Window';
  S_MenuMaximize = '~M~aximize';
  S_MenuSwitchColor = 'Switch Colors';

implementation

uses
  SysUtils, Classes, GetText, Dos;

var
  Lang: String;
  Lang4,
  Lang2: String;

initialization
  Lang := GetEnv('LANG');
  if Lang <> '' then
  begin
    Lang4 := ExtractFileName(Lang);
    Lang4 := StringReplace(Lang4, ExtractFileExt(Lang4), '', []);
    if Length(Lang4) > 2 then
      Lang2 := Copy(Lang4, 1, 2);
    if DirectoryExists('/opt/tparted') then
    begin
      Lang4 := '/opt/tparted/locale/' + Lang4 + '.mo';
      Lang2 := '/opt/tparted/locale/' + Lang2 + '.mo';
    end else
    begin
      Lang4 := './locale/' + Lang4 + '.mo';
      Lang2 := './locale/' + Lang2 + '.mo';
    end;
    if FileExists(Lang4) then
      TranslateResourceStrings(Lang4)
    else
    if FileExists(Lang2) then
      TranslateResourceStrings(Lang2);
  end;

end.