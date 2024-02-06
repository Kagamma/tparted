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

unit UI.Devices;

{$I configs.inc}

interface

uses
  Classes, SysUtils,
  FreeVision,
  Parted.Devices,
  Parted.Partitions,
  Parted.Commons,
  Parted.Operations,
  Parted.Logs,
  UI.Commons,
  UI.Partitions;

type
  { The main dialog for device }
  TUIDevice = object(TUIWindow)
  private
    FIsClosing: Boolean;
    procedure UpdateButtonsState(var APart: TPartedPartition);
    procedure AddOp(const OpKind: TPartedOpKind; const AData: Pointer; const PPart: PPartedPartition);
  public
    OpList: TPartedOpList;
    ListPartition: PUIPartitionList;
    LabelPendingOperations: PUILabel;
    LabelDeviceInfo: PUILabel;

    ButtonPartitionArray: array[0..7] of PUIButton;
    ButtonOperationArray: array[0..2] of PUIButton;
    constructor Init(var ADevice: TPartedDevice; AIndex: LongInt);
    destructor Done; virtual;
    procedure Draw; virtual;
    procedure HandleEvent(var E: TEvent); virtual;
    procedure Refresh;
  end;
  PUIDevice = ^TUIDevice;

function IsDeviceWindowOpened(var ADevice: TPartedDevice): Boolean;
function AddDeviceWindowToList(var ADevice: TPartedDevice): Boolean;
procedure RemoveDeviceWindowFromList(const ADeviceWindow: PUIDevice);

var
  OpenedDeviceWindowList: array[1..9] of PUIDevice; // A list of device windows to keep track which device we are opening right now.

implementation

uses
  Math,
  UI.Main,
  UI.Partitions.Create,
  UI.Partitions.Resize,
  UI.Partitions.Info,
  UI.Partitions.Unmount,
  UI.Partitions.LabelName,
  UI.Partitions.Flags,
  UI.Partitions.Delete,
  UI.Partitions.Format;

const
  SIZE_X = 79;
  SIZE_Y = 23;

var
  XPos: LongInt = 0;
  YPos: LongInt = 0;

function IsDeviceWindowOpened(var ADevice: TPartedDevice): Boolean;
var
  I: LongInt;
begin
  Result := False;
  // Check to see if this device is already opened on another window
  for I := Low(OpenedDeviceWindowList) to High(OpenedDeviceWindowList) do
  begin
    if (OpenedDeviceWindowList[I] <> nil) and (OpenedDeviceWindowList[I]^.OpList.GetCurrentDevice^.Path = ADevice.Path) then
    begin
      MsgBox(UTF8Decode(Format(S_DeviceAlreadyOpened, [ADevice.Path])), nil, mfInformation + mfOKButton);
      Exit(True);
    end;
  end;
end;

function AddDeviceWindowToList(var ADevice: TPartedDevice): Boolean;
var
  I: LongInt;
  W: PUIDevice;
begin
  Result := False;
  // Check to see if we still have slot for new window
  for I := Low(OpenedDeviceWindowList) to High(OpenedDeviceWindowList) do
  begin
    if OpenedDeviceWindowList[I] = nil then
    begin
      W := New(PUIDevice, Init(ADevice, I));
      Desktop^.Insert(W);
      OpenedDeviceWindowList[I] := W;
      Exit(True);
    end;
  end;
  // No slot left, show message
  MsgBox(UTF8Decode(Format(S_MaxDeviceWindow, [High(OpenedDeviceWindowList)])), nil, mfInformation + mfOKButton);
end;

procedure RemoveDeviceWindowFromList(const ADeviceWindow: PUIDevice);
var
  I: LongInt;
begin
  for I := Low(OpenedDeviceWindowList) to High(OpenedDeviceWindowList) do
  begin
    if (OpenedDeviceWindowList[I] <> nil) and
       (OpenedDeviceWindowList[I]^.Number = ADeviceWindow^.Number) then
    begin
      OpenedDeviceWindowList[I] := nil;
      Exit;
    end;
  end;
end;

// -------------------------------------------

procedure TUIDevice.AddOp(const OpKind: TPartedOpKind; const AData: Pointer; const PPart: PPartedPartition);
begin
  Self.OpList.AddOp(OpKind, AData, PPart);
end;

procedure TUIDevice.UpdateButtonsState(var APart: TPartedPartition);
var
  IsDisabled: Boolean;
  IsResizeableDisabled: Boolean;
begin
  IsDisabled := (APart.PartEnd <= 1024 * 1024) // The first 1MB in device
    or (APart.PartSize < 1024 * 1024) // Partition is less than 1MB in size
    or (Self.OpList[0].Device^.Table <> 'gpt'); // Parition is not a gpt partition
  IsResizeableDisabled := SToFlag(APart.FileSystem, FileSystemResizableArray) = 0; // Can it be resize?
  // Create button
  Self.ButtonPartitionArray[1]^.SetDisabled((APart.Number <> 0) or IsDisabled);
  // Delete button
  Self.ButtonPartitionArray[2]^.SetDisabled((APart.Number = 0) or (APart.IsMounted) or IsDisabled);
  // Format button
  Self.ButtonPartitionArray[3]^.SetDisabled((APart.Number = 0) or (APart.IsMounted) or IsDisabled);
  // Resize button
  Self.ButtonPartitionArray[4]^.SetDisabled((APart.Number = 0) or (APart.IsMounted) or APart.ContainsFlag('esp') or IsDisabled or IsResizeableDisabled);
  // Label button
  Self.ButtonPartitionArray[5]^.SetDisabled((APart.Number = 0) or (APart.IsMounted) or IsDisabled);
  // Flag button
  Self.ButtonPartitionArray[6]^.SetDisabled((APart.Number = 0) or (APart.IsMounted) or IsDisabled);
  // Unmount button
  Self.ButtonPartitionArray[7]^.SetDisabled((not APart.IsMounted) or (APart.FileSystem = 'linux-swap') or IsDisabled);
  // Undo button
  Self.ButtonOperationArray[0]^.SetDisabled(Self.OpList.GetOpCount = 0);
  // Empty button
  Self.ButtonOperationArray[1]^.SetDisabled(Self.OpList.GetOpCount = 0);
  // Apply button
  Self.ButtonOperationArray[2]^.SetDisabled(Self.OpList.GetOpCount = 0);
end;

constructor TUIDevice.Init(var ADevice: TPartedDevice; AIndex: LongInt);
var
  R, DesktopR: TRect;
  I: LongInt;
  Op: TPartedOp;
begin
  // Boundary and position
  UIMain.GetBounds(DesktopR);
  if (XPos + SIZE_X) > DesktopR.B.X then
    XPos := 0;
  if (YPos + SIZE_Y) >= DesktopR.B.Y then
    YPos := 0;
  R.Assign(XPos, YPos, XPos + Max(SIZE_X, DesktopR.B.X - 10), YPos + Max(SIZE_Y, DesktopR.B.Y - 10));
  Inc(XPos);
  Inc(YPos);
  //
  inherited Init(R, UTF8Decode(Format(S_PartitionWindowTitle, [ADevice.Path, ADevice.SizeApprox, ADevice.Name])), AIndex);
  Self.OpList := TPartedOpList.Create;
  Op.Device := ADevice.Clone;
  Op.OpData := nil;
  Self.OpList.Add(Op);
  // Partition list
  Self.GetExtent(R);
  R.A.X := R.A.X + 1;
  R.A.Y := R.A.Y + 2;
  R.B.X := R.B.X - 14;
  R.B.Y := R.B.Y - 3;
  Self.ListPartition := New(PUIPartitionList, Init(R, Self.OpList.GetCurrentDevice^));
  Self.Insert(Self.ListPartition);
  // Pending operation status
  Self.GetExtent(R);
  R.A.Y := R.B.Y - 1;
  Inc(R.A.X);
  Self.LabelPendingOperations := New(PUILabel, Init(R, Format(S_PendingOperations, [Self.OpList.GetOpCount]), nil));
  Self.Insert(Self.LabelPendingOperations);
  // Device info
  Self.GetExtent(R);
  Inc(R.A.X);
  Inc(R.A.Y);
  R.B.X := R.B.X - 14;
  R.B.Y := R.A.Y + 1;
  Self.LabelDeviceInfo := New(PUILabel, Init(R, Format(S_DeviceInfo, [
    Self.OpList.GetCurrentDevice^.Table, Self.OpList.GetCurrentDevice^.Transport
  ]), nil, #7#6#7#7));
  Self.Insert(Self.LabelDeviceInfo);

  // Buttons
  Self.GetExtent(R);
  R.B.X := R.B.X - 1;
  R.A.X := R.B.X - 13;
  R.A.Y := 2;
  R.B.Y := R.A.Y + 2;
  Self.ButtonPartitionArray[0] := New(PUIButton, Init(R, UTF8Decode(S_InfoButton), cmPartitionShowInfo, bfDefault));
  Inc(R.A.Y, 2);
  Inc(R.B.Y, 2);
  Self.ButtonPartitionArray[1] := New(PUIButton, Init(R, UTF8Decode(S_CreateButton), cmPartitionCreate, bfDefault));
  Inc(R.A.Y, 2);
  Inc(R.B.Y, 2);
  Self.ButtonPartitionArray[2] := New(PUIButton, Init(R, UTF8Decode(S_DeleteButton), cmPartitionDelete, bfDefault));
  Inc(R.A.Y, 2);
  Inc(R.B.Y, 2);
  Self.ButtonPartitionArray[3] := New(PUIButton, Init(R, UTF8Decode(S_FormatButton), cmPartitionFormat, bfDefault));
  Inc(R.A.Y, 2);
  Inc(R.B.Y, 2);
  Self.ButtonPartitionArray[4] := New(PUIButton, Init(R, UTF8Decode(S_ResizeButton), cmPartitionResize, bfDefault));
  Inc(R.A.Y, 2);
  Inc(R.B.Y, 2);
  Self.ButtonPartitionArray[5] := New(PUIButton, Init(R, UTF8Decode(S_LabelButton), cmPartitionLabel, bfDefault));
  Inc(R.A.Y, 2);
  Inc(R.B.Y, 2);
  Self.ButtonPartitionArray[6] := New(PUIButton, Init(R, UTF8Decode(S_FlagButton), cmPartitionFlag, bfDefault));
  Inc(R.A.Y, 2);
  Inc(R.B.Y, 2);
  Self.ButtonPartitionArray[7] := New(PUIButton, Init(R, UTF8Decode(S_UnmountButton), cmPartitionUnmount, bfDefault));
  for I := 0 to High(Self.ButtonPartitionArray) do
    Self.Insert(Self.ButtonPartitionArray[I]);

  Self.GetExtent(R);
  R.A.X := R.A.X + 1;
  R.A.Y := R.B.Y - 3;
  R.B.X := R.A.X + 13;
  R.B.Y := R.B.Y - 1;
  Self.ButtonOperationArray[0] := New(PUIButton, Init(R, UTF8Decode(S_UndoButton), cmOperationUndo, bfDefault));
  Inc(R.A.X, 14);
  Inc(R.B.X, 14);
  Self.ButtonOperationArray[1] := New(PUIButton, Init(R, UTF8Decode(S_EmptyButton), cmOperationClear, bfDefault));
  Inc(R.A.X, 14);
  Inc(R.B.X, 21);
  Self.ButtonOperationArray[2] := New(PUIButton, Init(R, UTF8Decode(S_ApplyOperationButton), cmOperationApply, bfDefault));
  for I := 0 to High(ButtonOperationArray) do
    Self.Insert(Self.ButtonOperationArray[I]);

  //
  Self.FocusNext(False);
end;

destructor TUIDevice.Done;
var
  I: LongInt;
begin
  Self.FIsClosing := True;
  Self.OpList.Free;
  RemoveDeviceWindowFromList(@Self);
  inherited Done;
end;

procedure TUIDevice.Draw;
var
  R: TRect;
  I: LongInt;
begin
  if FIsClosing then Exit;
  // Adjust child controls's position
  Self.GetExtent(R);
  R.A.Y := R.B.Y - 1;
  Inc(R.A.X);
  R.B.X := Min(R.B.X - 1, Length(Self.LabelPendingOperations^.Text) + R.A.X + 2);
  Self.LabelPendingOperations^.SetBounds(R);
  // Partition Buttons
  Self.GetExtent(R);
  R.B.X := R.B.X - 1;
  R.A.X := R.B.X - 13;
  R.A.Y := 2;
  R.B.Y := R.A.Y + 2;
  for I := 0 to High(Self.ButtonPartitionArray) do
  begin
    Self.ButtonPartitionArray[I]^.SetBounds(R);
    Inc(R.A.Y, 2);
    Inc(R.B.Y, 2);
  end;
  // Operation Buttons
  Self.GetExtent(R);
  R.A.X := R.A.X + 1;
  R.A.Y := R.B.Y - 3;
  R.B.X := R.A.X + 13;
  R.B.Y := R.B.Y - 1;
  for I := 0 to High(Self.ButtonOperationArray) do
  begin
    Self.ButtonOperationArray[I]^.SetBounds(R);
    Inc(R.A.X, 14);
    if I = 1 then
      Inc(R.B.X, 21)
    else
      Inc(R.B.X, 14);
  end;
  inherited;
end;

procedure TUIDevice.HandleEvent(var E: TEvent);

  procedure DoCreate;
  var
    CurrentDevice: PPartedDevice;
    Data: PPartedOpDataCreate;
    PPart: PPartedPartition;
  begin
    CurrentDevice := Self.OpList.GetCurrentDevice;
    if CurrentDevice^.GetPrimaryPartitionCount >= CurrentDevice^.MaxPartitions then
    begin
      MsgBox(S_MaximumPartitionReached, nil, mfInformation + mfOKButton);
      Exit;
    end;
    PPart := Self.ListPartition^.GetSelectedPartition;
    GetMem(Data, SizeOf(TPartedOpDataCreate)); // Allocate memory for op data
    FillChar(Data^, SizeOf(TPartedOpDataCreate), 0);
    with Data^ do
    begin
      FileSystem := SToIndex('ext4', FileSystemFormattableArray); // Default to ext4
      if PPart^.Prev = nil then
        Preceding := 1
      else
        Preceding := 0;
      Name := 'primary';
      Size := BToMBFloor(PPart^.PartSizeZero) - Preceding;
    end;
    if ShowCreateDialog(PPart, Data) then
    begin
      Self.AddOp(okCreate, Data, PPart);
      Self.Refresh;
    end else
    begin
      Dispose(Data); // Data discarded
    end;
  end;

  procedure DoResize;
  var
    Data: PPartedOpDataResize;
    PPart: PPartedPartition;
  begin
    PPart := Self.ListPartition^.GetSelectedPartition;
    GetMem(Data, SizeOf(TPartedOpDataResize)); // Allocate memory for op data
    FillChar(Data^, SizeOf(TPartedOpDataResize), 0);
    with Data^ do
    begin
      if (PPart^.Prev <> nil) and (PPart^.Prev^.Prev = nil) then
        Preceding := Max(BToMBCeil(PPart^.Prev^.PartSize), 1)
      else
      if (PPart^.Prev <> nil) and (PPart^.Prev^.Number = 0) then // A minimum of 1MB is need at the start of the disk
        Preceding := BToMBCeil(PPart^.Prev^.PartSize)
      else
        Preceding := 0;
      Size := BToMBFloor(PPart^.PartSizeZero);
    end;
    if ShowResizeDialog(PPart, Data) then
    begin
      Self.AddOp(okResize, Data, PPart);
      Self.Refresh;
    end else
    begin
      Dispose(Data); // Data discarded
    end;
  end;

  procedure DoLabel;
  var
    Data: PPartedOpDataLabel;
    PPart: PPartedPartition;
  begin
    PPart := Self.ListPartition^.GetSelectedPartition;
    GetMem(Data, SizeOf(TPartedOpDataLabel)); // Allocate memory for op data
    FillChar(Data^, SizeOf(TPartedOpDataLabel), 0);
    with Data^ do
    begin
      LabelName := PPart^.LabelName;
      Name := PPart^.Name;
    end;
    if ShowLabelNameDialog(PPart, Data) then
    begin
      Self.AddOp(okLabel, Data, PPart);
      Self.Refresh;
    end else
    begin
      Dispose(Data); // Data discarded
    end;
  end;

  procedure DoFormat;
  var
    Data: PPartedOpDataFormat;
    PPart: PPartedPartition;
  begin
    PPart := Self.ListPartition^.GetSelectedPartition;
    GetMem(Data, SizeOf(TPartedOpDataFormat)); // Allocate memory for op data
    FillChar(Data^, SizeOf(TPartedOpDataFormat), 0);
    with Data^ do
    begin
      FileSystem := SToIndex('ext4', FileSystemFormattableArray);
    end;
    if ShowFormatDialog(PPart, Data) then
    begin
      Self.AddOp(okFormat, Data, PPart);
      Self.Refresh;
    end else
    begin
      Dispose(Data); // Data discarded
    end;
  end;

  procedure DoFlag;
  var
    Data: PPartedOpDataFlags;
    PPart: PPartedPartition;
  begin
    PPart := Self.ListPartition^.GetSelectedPartition;
    GetMem(Data, SizeOf(TPartedOpDataFlags)); // Allocate memory for op data
    FillChar(Data^, SizeOf(TPartedOpDataFlags), 0);
    with Data^ do
    begin
      Flags := SAToFlag(PPart^.Flags, FlagArray);
    end;
    if ShowFlagsDialog(PPart, Data) then
    begin
      Self.AddOp(okFlag, Data, PPart);
      Self.Refresh;
    end else
    begin
      Dispose(Data); // Data discarded
    end;
  end;

  procedure DoDelete;
  var
    Data: PPartedOpDataDelete;
    PPart: PPartedPartition;
  begin
    PPart := Self.ListPartition^.GetSelectedPartition;
    GetMem(Data, SizeOf(TPartedOpDataDelete)); // Allocate memory for op data
    FillChar(Data^, SizeOf(TPartedOpDataDelete), 0);
    with Data^ do
    begin
    end;
    if ShowDeleteDialog(PPart) then
    begin
      Self.AddOp(okDelete, Data, PPart);
      Self.Refresh;
    end else
    begin
      Dispose(Data); // Data discarded
    end;
  end;

  procedure DoApplyRefreshDevice;
  begin
    Self.OpList.Empty;
    LoadingStart(UTF8Decode(S_LoadingPartitions));
    try
      QueryDeviceAndPartitions(Self.OpList.GetCurrentDevice^.Path, Self.OpList.GetCurrentDevice^);
      QueryDeviceAll(Self.OpList.GetCurrentDevice^);
    except
      on E: Exception do
        Self.OpList.GetCurrentDevice^.Done;
    end;
    LoadingStop;
    Self.Refresh;
  end;

  procedure DoApplyOperations;
  begin
    try
      try
        Self.OpList.Execute;
      except
        on E: Exception do
          MsgBox(E.Message, nil, mfError + mfOKButton);
      end;
    finally
      DoApplyRefreshDevice;
    end;
  end;

begin
  if Self.FIsClosing then Exit;
  if E.What = evKeyDown then
  begin
    case E.KeyCode of
      kbEsc:
        begin
          Message(@Self, evCommand, cmClose, nil);
          Exit;
        end;
    end;
  end else
  if E.What = evBroadcast then
  begin
    case E.Command of
      cmOperatorExists:
        begin
          if Self.OpList.GetOpCount > 0 then
            ClearEvent(E);
        end;
      // Clear all ops and refresh partition list
      cmDeviceRefresh:
        begin
          DoApplyRefreshDevice;
          Exit;
        end;
    end;
  end else
  if E.What = evCommand then
  begin
    case E.Command of
      cmListChanged:
        begin
          // TODO: Update button state
          Self.UpdateButtonsState(Self.OpList.GetCurrentDevice^.GetPartitionAt(Self.ListPartition^.List^.Focused)^);
          Exit;
        end;
      cmPartitionShowInfo:
        begin
          ShowPartitionInfoDialog(Self.ListPartition^.GetSelectedPartition);
          Exit;
        end;
      cmPartitionCreate:
        begin
          DoCreate;
          Exit;
        end;
      cmPartitionResize:
        begin
          DoResize;
          Exit;
        end;
      cmPartitionFormat:
        begin
          DoFormat;
          Exit;
        end;
      cmPartitionUnmount:
        begin
          if ShowUnmountDialog(Self.ListPartition^.GetSelectedPartition) then
            Self.ListPartition^.RefreshList;
          Exit;
        end;
      cmPartitionLabel:
        begin
          DoLabel;
          Exit;
        end;
      cmPartitionFlag:
        begin
          DoFlag;
          Exit;
        end;
      cmPartitionDelete:
        begin
          DoDelete;
          Exit;
        end;
      cmOperationUndo:
        begin
          Self.OpList.Undo;
          Self.Refresh;
          Self.UpdateButtonsState(Self.ListPartition^.GetSelectedPartition^);
          Exit;
        end;
      cmOperationClear:
        begin
          Self.OpList.Empty;
          Self.Refresh;
          Self.UpdateButtonsState(Self.ListPartition^.GetSelectedPartition^);
          Exit;
        end;
      cmOperationApply:
        begin
          if MsgBox(UTF8Decode(Format(S_OperationAdvise, [Self.OpList.GetCurrentDevice^.Path])), nil, mfConfirmation + mfYesButton + mfNoButton) = cmYes then
            DoApplyOperations;
          Exit;
        end;
      cmClose:
        begin
          if Self.OpList.GetOpCount > 0 then
          begin
            if MsgBox(UTF8Decode(Format(S_CloseMessage, [Self.OpList.GetCurrentDevice^.Path])), nil, mfConfirmation + mfYesButton + mfNoButton) <> cmYes then
            begin
              Exit;
            end;
          end;
        end;
    end;
  end;
  inherited HandleEvent(E);
end;

procedure TUIDevice.Refresh;
var
  PDevice: PPartedDevice;
begin
  PDevice := Self.OpList.GetCurrentDevice;
  Self.ListPartition^.Device := PDevice;
  Self.ListPartition^.RefreshList; // Redraw partition list
  // Redraw pending operation text
  Self.LabelPendingOperations^.Text := UTF8Decode(Format(S_PendingOperations, [Self.OpList.GetOpCount]));
  Self.LabelPendingOperations^.DrawView;
end;

end.

