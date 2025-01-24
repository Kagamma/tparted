{
tparted
Copyright (C) 2024-2025 kagamma

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

unit UI.Partitions;

{$I configs.inc}

interface

uses
  Classes, SysUtils, StrUtils,
  FreeVision,
  Parted.Commons, Locale, Parted.Devices, Parted.Partitions,
  UI.Commons;

type
  TUITable = object(TUIListBox)
  public
    IsFirstEvent: Boolean;
    procedure HandleEvent(var E: TEvent); virtual;
  end;
  PUITable = ^TUITable;

  { List of partitions for device }
  TUIPartitionList = object(TGroup)
  public
    Device: PPartedDevice;
    ListCollection: PUnicodeStringPtrCollection;
    List: PUITable;
    ListHeader: PUILabel;
    ScrollBar: PScrollBar;

    constructor Init(var Bounds: TRect; var ADevice: TPartedDevice);
    destructor Done; virtual;
    procedure Draw; virtual;
    procedure RefreshList; // Update list based on current device information
    function GetSelectedPartition: PPartedPartition;
  end;
  PUIPartitionList = ^TUIPartitionList;

implementation

uses
  UI.Main,
  UI.Devices;

procedure TUITable.HandleEvent(var E: TEvent);
var
  PopupMenu: PUIMenuBox;
  MI: PMenuItem;
  R: TRect;
  P: TPoint;
  UIDevice: PUIDevice;
  I: LongInt;
  EventOld: TEvent;
  FocusedOld,
  CountOld: LongInt;

  procedure UpdateButtonStates;
  begin
    if Self.IsFirstEvent or (FocusedOld <> Self.Focused) or (CountOld <> Self.List^.Count) then
      Message(Self.Owner^.Owner, evCommand, cmListChanged, nil);
  end;

begin
  UIDevice := PUIDevice(Self.Owner^.Owner);
  EventOld := E; // Backup old event so we can use right mouse click for both selection and drop down menu
  FocusedOld := Self.Focused;
  CountOld := Self.List^.Count;
  inherited HandleEvent(E);
  // Update button states
  UpdateButtonStates;
  // Handle old event
  if EventOld.What = evMouseDown then
  begin
    if (EventOld.Buttons and mbRightButton) <> 0 then
    begin
      Desktop^.GetBounds(R);
      PopupMenu := New(PUIMenuBox, Init(R, NewMenu(
        NewItem(S_InfoButton.ToUnicode, '', kbNoKey, cmPartitionShowInfo, hcNoContext,
        NewItem(S_CreateButton.ToUnicode, '', kbNoKey, cmPartitionCreate, hcNoContext,
        NewItem(S_DeleteButton.ToUnicode, '', kbNoKey, cmPartitionDelete, hcNoContext,
        NewItem(S_FormatButton.ToUnicode, '', kbNoKey, cmPartitionFormat, hcNoContext,
        NewItem(S_ResizeButton.ToUnicode, '', kbNoKey, cmPartitionResize, hcNoContext,
        NewItem(S_LabelButton.ToUnicode, '', kbNoKey, cmPartitionLabel, hcNoContext,
        NewItem(S_FlagButton.ToUnicode, '', kbNoKey, cmPartitionFlag, hcNoContext,
        NewItem(S_UnmountButton.ToUnicode, '', kbNoKey, cmPartitionUnmount, hcNoContext, nil))))))))
      ), nil));
      // Set menu states
      MI := PopupMenu^.Menu^.Items;
      // 'Pred' to exclude 'Create GPT' button
      for I := Low(UIDevice^.ButtonPartitionArray) to Pred(High(UIDevice^.ButtonPartitionArray)) do
      begin
        MI^.Disabled := UIDevice^.ButtonPartitionArray[I]^.Disabled;
        if MI^.Disabled then
          MI^.Command := cmNothing;
        MI := MI^.Next;
      end;
      // Make sure popup menu is within screen
      P := EventOld.Where;
      if P.Y + PopupMenu^.Size.Y > R.B.Y then
      begin
        Dec(P.Y, PopupMenu^.Size.Y+1);
        if P.Y < R.A.Y then
        begin
          P.Y := R.A.Y;
          Inc(P.X);
        end;
      end;
      if P.X + PopupMenu^.Size.X > R.B.X then
        Dec(P.X, PopupMenu^.Size.X);
      PopupMenu^.MoveTo(P.X + 1, P.Y + 1);
      //
      Desktop^.Insert(PopupMenu);
      Message(PopupMenu, evCommand, cmMenu, nil);
      Dispose(PopupMenu, Done);
    end;
  end;
  Self.IsFirstEvent := False;
end;

// -------------------------

constructor TUIPartitionList.Init(var Bounds: TRect; var ADevice: TPartedDevice);
var
  R: TRect;
  I: Integer;
  S: String;
begin
  inherited Init(Bounds);

  Self.Device := @ADevice;

  Self.GetExtent(R);
  Self.GrowMode := gfGrowHiX or gfGrowHiY;

  // Scrollbar
  Inc(R.A.Y);
  R.A.X := R.B.X - 1;
  Self.ScrollBar := New(PScrollBar, Init(R));
  Self.ScrollBar^.GrowMode := 0;
  Self.Insert(ScrollBar);

  // Listbox (Table)
  R.A.X := 0;
  Dec(R.B.X, 1);
  Self.List := New(PUITable, Init(R, 1, Self.ScrollBar));
  Self.List^.GrowMode := 0;
  Self.List^.IsFirstEvent := True;
  Self.Insert(Self.List);

  // ListCollection
  Self.RefreshList;

  // Table header
  Dec(R.A.Y);
  Inc(R.B.X);
  R.B.Y := R.A.Y + 1;
  S := Format('%s│%s│%s│%s│%s│%s│%s', [
    PadCenterLimit(S_Partition, 15), // TODO: The size should be based on the text with highest length
    PadCenterLimit(S_FileSystem, 12),
    PadCenterLimit(S_Size, 7),
    PadCenterLimit(S_Used, 7),
    PadRightLimit(S_Flags, 20),
    PadRightLimit(S_Label, 20),
    PadRightLimit(S_Mount, 40)
  ]);
  Self.ListHeader := New(PUILabel, Init(R, S, @Self, #7#7#19#7));
  Self.Insert(Self.ListHeader);
end;

destructor TUIPartitionList.Done;
begin
  Dispose(Self.ListCollection, Done);
  inherited Done;
end;

procedure TUIPartitionList.Draw;
var
  R: TRect;
begin
  // Adjust child controls's position
  Self.GetExtent(R);
  R.A.X := R.B.X - 1;
  Inc(R.A.Y);
  Self.ScrollBar^.SetBounds(R);

  R.A.X := 0;
  Dec(R.B.X, 1);
  Self.List^.SetBounds(R);

  Dec(R.A.Y);
  Inc(R.B.X);
  R.B.Y := R.A.Y + 1;
  Self.ListHeader^.SetBounds(R);
  inherited Draw;
end;

function TUIPartitionList.GetSelectedPartition: PPartedPartition;
begin
  if Self.ListCollection^.Count <= 0 then // Make sure the list is not empty
    Result := nil
  else
    Result := Self.Device^.GetPartitionAt(Self.List^.Focused);
end;

procedure TUIPartitionList.RefreshList; // Update list based on current device information
var
  I: LongInt;
  FocusedOld: LongInt = 0;
  PPart: PPartedPartition;
  S: String;
  IsMountedSymbol: String;
begin
  Self.ListCollection := New(PUnicodeStringPtrCollection, Init(8, 8));
  FocusedOld := Self.List^.Focused;
  PPart := Self.Device^.PartitionRoot;
  while PPart <> nil do
  begin
    // Prepare partition string
    if PPart^.IsMounted then
      IsMountedSymbol := 'M '
    else
    if PPart^.Number < 0 then
      IsMountedSymbol := '* '
    else
      IsMountedSymbol := '  ';
    S := Format('%s│%s│%s│%s│%s│%s│%s', [
      PadRightLimit(IsMountedSymbol + ExtractFileName(PPart^.GetPartitionPathForDisplay), 15),
      PadRightLimit(PPart^.FileSystem, 12),
      PadLeftLimit(SizeString(PPart^.PartSize), 7),
      PadLeftLimit(SizeString(PPart^.PartUsed), 7),
      PadRightLimit(SAToS(PPart^.Flags, ','), 20),
      PadRightLimit(PPart^.LabelName, 20),
      PadRightLimit(PPart^.MountPoint, 40)
    ]);
    Self.ListCollection^.Insert(GetUnicodeStr(S));
    PPart := PPart^.Next;
  end;
  Self.List^.NewList(Self.ListCollection);
  if FocusedOld < Self.ListCollection^.Count then
    Self.List^.FocusItem(FocusedOld);
end;

// -------------------------------------------

end.

