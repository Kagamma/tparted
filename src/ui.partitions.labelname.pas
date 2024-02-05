unit UI.Partitions.LabelName;

{$I configs.inc}

interface

uses
  SysUtils, Classes, FreeVision,
  UI.Commons,
  Parted.Operations,
  Parted.Commons,
  Parted.Devices,
  Parted.Partitions;

function ShowLabelNameDialog(const PPart: PPartedPartition; const AData: PPartedOpDataLabel): Boolean;

implementation

function ShowLabelNameDialog(const PPart: PPartedPartition; const AData: PPartedOpDataLabel): Boolean;
const
  HW = 22;
var
  MX, MY: LongInt;
  R: TRect;
  D: PDialog;
  I: LongInt;
  V: PView;
  DataOld: TPartedOpDataLabel;
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
  R.Assign(MX - HW, MY - 5, MX + HW, MY + 4);
  D := New(PDialog, Init(R, UTF8Decode(Format(S_InputLabelTitle, [PPart^.GetPartitionPath]))));
  try
    D^.GetExtent(R);

    // Label
    R.Assign(3, 2, 40, 3);
    V := New(PUIInputLine, Init(R, 30));
    D^.Insert(V);
    R.Assign(3, 1, 20, 2);
    D^.Insert(New(PLabel, Init(R, UTF8Decode(S_Label), V)));

    // Name
    R.Assign(3, 4, 40, 5);
    V := New(PUIInputLine, Init(R, 30));
    D^.Insert(V);
    R.Assign(3, 3, 20, 4);
    D^.Insert(New(PLabel, Init(R, UTF8Decode(S_Name), V)));

    // Ok-Button
    R.Assign(15, 6, 27, 8);
    D^.Insert(New(PUIButton, Init(R, UTF8Decode(S_OkButton), cmOK, bfDefault)));

    // Cancel-Button
    R.Assign(28, 6, 40, 8);
    D^.Insert(New(PUIButton, Init(R, UTF8Decode(S_CancelButton), cmCancel, bfDefault)));

    D^.FocusNext(False);

    DataOld := AData^;
    D^.SetData(AData^);
    if Desktop^.ExecView(D) = cmOk then
    begin
      D^.GetData(AData^);
      Result := (DataOld.LabelName <> AData^.LabelName) or (DataOld.Name <> AData^.Name);
    end;
  finally
    Dispose(D, Done);
  end;
end;

end.
