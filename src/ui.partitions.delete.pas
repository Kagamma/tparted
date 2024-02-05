unit UI.Partitions.Delete;

{$I configs.inc}

interface

uses
  SysUtils, Classes, FreeVision,
  UI.Commons,
  Parted.Operations,
  Parted.Commons,
  Parted.Devices,
  Parted.Partitions;

function ShowDeleteDialog(const PPart: PPartedPartition): Boolean;

implementation

function ShowDeleteDialog(const PPart: PPartedPartition): Boolean;
begin
  //Result := False;
  //if MsgBox(UTF8Decode(Format(S_PartitionAskDelete, [PPart^.GetPartitionPath])), nil, mfInformation + mfYesButton + mfNoButton) = cmYes then
    Result := True;
end;

end.
