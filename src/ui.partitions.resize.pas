unit UI.Partitions.Resize;

{$I configs.inc}

interface

uses
  SysUtils, Classes, FreeVision,
  UI.Commons,
  Parted.Operations,
  Parted.Commons,
  Parted.Devices,
  Parted.Partitions;

function ShowResizeDialog(const PPart: PPartedPartition; const AData: PPartedOpDataResize): Boolean;

implementation

function ShowResizeDialog(const PPart: PPartedPartition; const AData: PPartedOpDataResize): Boolean;
const
  HW = 22;
var
  MX, MY: LongInt;
  R: TRect;
  D: PDialog;
  CItemRoot,
  CItem: PSItem;
  I: LongInt;
  DataOld: TPartedOpDataResize;
  V: PView;
  Preceding: PUIInputNumber;
  Size: PUIInputNumber = nil;

  // Real-time correction for preceding
  function PrecedingMin(V: Int64): Int64;
  var
    Flooring: Int64;
  begin
    if (PPart^.Prev <> nil) and (PPart^.Prev^.Prev = nil) and (V < 1) then // A minimum of 1MB is need at the start of the disk
      Result := 1
    else
      Result := V;
  end;

  function PrecedingMax(V: Int64): Int64;
  var
    Ceiling: Int64;
  begin
    if Size <> nil then
      Ceiling := BToMBFloor(PPart^.GetPossibleExpandSize) - Size^.GetValue
    else
      Ceiling := BToMBFloor(PPart^.GetPossibleExpandSize) - BToMBFloor(PPart^.PartSizeZero);
    if V > Ceiling then
      Result := Ceiling
    else
      Result := V;
  end;

  // Real-time correction for size
  function SizeMin(V: Int64): Int64;
  var
    M: Int64;
  begin
    M := BToMBFloor(PPart^.PartUsed);
    if V < M then
      Result := M
    else
      Result := V;
  end;

  function SizeMax(V: Int64): Int64;
  var
    Ceiling: Int64;
  begin
    Ceiling := BToMBFloor(PPart^.GetPossibleExpandSize) - Preceding^.GetValue;
    if V > Ceiling then
      Result := Ceiling
    else
      Result := V;
  end;

begin
  Result := False;
  if PPart^.Number = 0 then
  begin
    Exit;
  end;
  Desktop^.GetExtent(R);
  MX := R.B.X div 2;
  MY := R.B.Y div 2;
  R.Assign(MX - HW, MY - 8, MX + HW, MY + 7);
  D := New(PDialog, Init(R, UTF8Decode(Format(S_ResizeDialogTitle, [PPart^.GetPartitionPath]))));
  try
    D^.GetExtent(R);

    // Free space preceding
    R.Assign(5, 3, 30, 4);
    Preceding := New(PUIInputNumber, Init(R, 16));
    Preceding^.OnMin := @PrecedingMin;
    Preceding^.OnMax := @PrecedingMax;
    D^.Insert(Preceding);
    R.Assign(5, 2, 30, 3);
    D^.Insert(New(PLabel, Init(R, UTF8Decode(S_FreeSpacePreceding), Preceding)));

    // New size
    R.Assign(5, 5, 30, 6);
    Size := New(PUIInputNumber, Init(R, 16));
    Size^.OnMin := @SizeMin;
    Size^.OnMax := @SizeMax;
    D^.Insert(Size);
    R.Assign(5, 4, 30, 5);
    D^.Insert(New(PLabel, Init(R, UTF8Decode(S_NewSize), Size)));

    // Total size
    R.Assign(6, 6, 30, 8);
    D^.Insert(New(PStaticText, Init(R, UTF8Decode(Format(S_MaxPossibleSpace, [BToMBFloor(PPart^.GetPossibleExpandSize)])))));

    // Min possible size
    R.Assign(6, 8, 30, 10);
    D^.Insert(New(PStaticText, Init(R, UTF8Decode(Format(S_MinPossibleSpace, [BToMBFloor(PPart^.PartUsed)])))));

    // Ok-Button
    R.Assign(11, 12, 23, 14);
    D^.Insert(New(PUIButton, Init(R, UTF8Decode(S_OkButton), cmOK, bfDefault)));

    // Cancel-Button
    R.Assign(25, 12, 37, 14);
    D^.Insert(New(PUIButton, Init(R, UTF8Decode(S_CancelButton), cmCancel, bfDefault)));

    D^.FocusNext(False);

    DataOld := AData^;
    D^.SetData(AData^);
    if Desktop^.ExecView(D) = cmOk then
    begin
      D^.GetData(AData^);
      Result := True;
    end;
  finally
    Dispose(D, Done);
  end;
end;

end.

