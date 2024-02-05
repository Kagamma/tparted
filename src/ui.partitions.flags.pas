unit UI.Partitions.Flags;

{$I configs.inc}

interface

uses
  SysUtils, Classes, FreeVision,
  UI.Commons,
  Parted.Operations,
  Parted.Commons,
  Parted.Devices,
  Parted.Partitions;

function ShowFlagsDialog(const PPart: PPartedPartition; const AData: PPartedOpDataFlags): Boolean;

implementation

function ShowFlagsDialog(const PPart: PPartedPartition; const AData: PPartedOpDataFlags): Boolean;
const
  HW = 21;
var
  MX, MY: LongInt;
  R: TRect;
  D: PDialog;
  CItemRoot,
  CItem: PSItem;
  I: LongInt;
  DataOld: TPartedOpDataFlags;
begin
  Result := False;
  if PPart^.Number = 0 then
  begin
    MsgBox(UTF8Decode(Format(S_PartitionIsUnallocated, [])), nil, mfInformation + mfOKButton);
    Exit;
  end;
  Desktop^.GetExtent(R);
  MX := R.B.X div 2;
  MY := R.B.Y div 2;
  R.Assign(MX - HW, MY - 11, MX + HW, MY + 11);
  D := New(PDialog, Init(R, UTF8Decode(Format(S_FlagsDialogTitle, [PPart^.GetPartitionPath]))));
  try
    D^.GetExtent(R);

    // Flags
    CItemRoot := NewSItem(FlagArray[0], nil);
    CItem := CItemRoot;
    for I := 1 to High(FlagArray) do
    begin
      CItem^.Next := NewSItem(FlagArray[I], nil);
      CItem := CItem^.Next;
    end;
    R.Assign(HW - HW + 3, 2, HW + 5, 2 + Length(FlagArray));
    D^.Insert(New(PCheckBoxes, Init(R, CItemRoot)));

    // Ok-Button
    R.Assign(HW + HW - 14, 17, HW + HW - 2, 19);
    D^.Insert(New(PUIButton, Init(R, UTF8Decode(S_OkButton), cmOK, bfDefault)));

    // Cancel-Button
    R.Assign(HW + HW - 14, 19, HW + HW - 2, 21);
    D^.Insert(New(PUIButton, Init(R, UTF8Decode(S_CancelButton), cmCancel, bfDefault)));

    D^.FocusNext(False);

    DataOld := AData^;
    D^.SetData(AData^);
    if Desktop^.ExecView(D) = cmOk then
    begin
      D^.GetData(AData^);
      Result := DataOld.Flags <> AData^.Flags;
    end;
  finally
    Dispose(D, Done);
  end;
end;

end.
