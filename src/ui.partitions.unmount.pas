unit UI.Partitions.Unmount;

{$I configs.inc}

interface

uses
  SysUtils, Classes, FreeVision,
  UI.Commons,
  Parted.Commons,
  Parted.Devices,
  Parted.Partitions;

function ShowUnmountDialog(const PPart: PPartedPartition): Boolean;

implementation

function ShowUnmountDialog(const PPart: PPartedPartition): Boolean;
begin
  Result := False;
  if PPart^.IsMounted then // Only perform on a mounted partition
  begin
    try
      LoadingStart(Format(S_PartitionUnmounting, [PPart^.GetPartitionPath]));
      QueryPartitionUnmount(PPart^);
      LoadingStop;
      MsgBox(UTF8Decode(Format(S_PartitionUnmounted, [PPart^.GetPartitionPath])), nil, mfInformation + mfOKButton);
      Result := True;
    except
      on E: Exception do
      begin
        LoadingStop;
        MsgBox(UTF8Decode(E.Message), nil, mfError + mfOKButton);
      end;
    end;
  end;
end;

end.