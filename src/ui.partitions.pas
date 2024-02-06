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

unit UI.Partitions;

{$I configs.inc}

interface

uses
  Classes, SysUtils, StrUtils,
  FreeVision,
  Parted.Commons, Parted.Devices, Parted.Partitions,
  UI.Commons;

type
  TUITable = object(TUIListBox)
  public
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

procedure TUITable.HandleEvent(var E: TEvent);
begin
  inherited HandleEvent(E);
  Message(Self.Owner^.Owner, evCommand, cmListChanged, nil);
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
  Self.Insert(Self.List);

  // ListCollection
  Self.RefreshList;

  // Table header
  Dec(R.A.Y);
  Inc(R.B.X);
  R.B.Y := R.A.Y + 1;
  S := Format('%s│%s│%s│%s│%s│%s', [
    PadCenter(S_Partition, 15),
    PadCenter(S_FileSystem, 15),
    PadCenter(S_Size, 7),
    PadCenter(S_Used, 7),
    PadRight(S_Flags, 16),
    PadRight(S_Label, 16)
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
begin
  Self.ListCollection := New(PUnicodeStringPtrCollection, Init(8, 8));
  FocusedOld := Self.List^.Focused;
  PPart := Self.Device^.PartitionRoot;
  while PPart <> nil do
  begin
    // Prepare partition string
    S := Format('%s│%s│%s│%s│%s│%s', [
      PadRight(PPart^.GetPartitionPathForDisplay, 15),
      PadRight(PPart^.FileSystem, 15),
      PadLeft(SizeString(PPart^.PartSize), 7),
      PadLeft(SizeString(PPart^.PartUsed), 7),
      PadRight(SAToS(PPart^.Flags, ','), 16),
      PadRight(PPart^.LabelName, 16)
    ]);
    Self.ListCollection^.Insert(GetUnicodeStr(S));
    PPart := PPart^.Next;
  end;
  Self.List^.NewList(Self.ListCollection);
  if FocusedOld <= Self.ListCollection^.Count then
    Self.List^.FocusItem(FocusedOld);
end;

// -------------------------------------------

end.

