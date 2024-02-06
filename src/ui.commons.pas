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

unit UI.Commons;

{$I configs.inc}

interface

uses
  Classes, SysUtils,
  FreeVision,
  Parted.Commons;

const
  CUIButton = #10#22#12#13#14#14#14#15;
  cmListChanged = 50000;

type
  TUIWindow = object(TWindow)
  public
    constructor Init(var Bounds: TRect; ATitle: Sw_String; ANumber: LongInt);
    function GetPalette: PPalette; virtual;
  end;
  PUIWindow = ^TUIWindow;

  // A new listbox, to be used with TUnicodeStringPtrCollection
  TUIListBox = object(TListBox)
  public
    function GetText(Item: LongInt; MaxLen: LongInt): Sw_String; virtual;
  end;
  PUIListBox = ^TUIListBox;

  // Yes because the TUnicodeStringCollection is kinda not good, so we resort to creating a new one
  // Also we don't need any sorting mechanics
  TUnicodeStringPtrCollection = object(TCollection)
  public
    procedure Insert(Item: Pointer); virtual;
    function GetItem(var S: TStream): Pointer; virtual;
    procedure FreeItem(Item: Pointer); virtual;
    procedure PutItem(var S: TStream; Item: Pointer); virtual;
    // New method allows to update existing item
    procedure AtUpdate(Index: LongInt; const AText: UnicodeString);
  end;
  PUnicodeStringPtrCollection = ^TUnicodeStringPtrCollection;

  // New label with custom palette
  TUILabel = object(TLabel)
  public
    Palette: RawByteString;
    constructor Init(var Bounds: TRect; const AText: String; ALink: PView; APalette: RawByteString = CLabel);
    function GetPalette: PPalette; virtual;
    procedure Draw; virtual;
  end;
  PUILabel = ^TUILabel;

  // New button with better palette
  TUIButton = object(TButton)
  public
    Disabled: Boolean;
    function GetPalette: PPalette; virtual;
    procedure Draw; virtual;
    procedure SetDisabled(const V: Boolean);
  end;
  PUIButton = ^TUIButton;

  // Loading window, show it to user while doing something
  TUILoadingDialog = object(TDialog)
  public
    constructor Init(const AText: String);
    procedure HandleEvent(var E: TEvent); virtual;
  end;
  PUILoadingDialog = ^TUILoadingDialog;

  // New TUIInputLine with proper DataSize and SetData methods to replace the buggy ones
  // See https://gitlab.com/freepascal.org/fpc/source/-/merge_requests/581
  TUIInputLine = object(TInputLine)
  public
    function DataSize: LongWord; virtual;
    procedure SetData(var Rec); virtual;
    procedure GetData(var Rec); virtual;
  end;
  PUIInputLine = ^TUIInputLine;

  // TUIInputNmber
  TUIInputNumberValidateProc = function(V: Int64): Int64 is nested;
  TUIInputNumber = object(TUIInputLine)
  private
    procedure Validate;
  public
    OnMin,
    OnMax: TUIInputNumberValidateProc;
    procedure HandleEvent(var E: TEvent); virtual;
    function GetValue: Int64;
    procedure SetData(var Rec); virtual;
    procedure GetData(var Rec); virtual;
    procedure Draw; virtual;
  end;
  PUIInputNumber = ^TUIInputNumber;

  // New TUIRadioButtons. It doesnt do aything for now.
  TUIRadioButtons = object(TRadioButtons)
  end;

  // New TUIMultiCheckBoxes. It doesnt do aything for now.
  TUIMultiCheckBoxes = object(TMultiCheckBoxes)
  end;

  // New TUIStaticText, with fixes for MessageBox
  PUIStaticText = ^TUIStaticText;
  TUIStaticText = object(TStaticText)
  public
    procedure Draw; virtual;
  end;

procedure LoadingStart(const S: String);
procedure LoadingStop;

// Copied from Free Vision source code. Since the original MessageBox is buggy, we implement fixes
// on our own instead. See https://gitlab.com/freepascal.org/fpc/source/-/issues/40607
FUNCTION MsgBox(Const Msg: Sw_String; Params: Pointer; AOptions: Word): Word;
FUNCTION MsgBoxRect(Var R: TRect; Const Msg: Sw_String; Params: Pointer;
  AOptions: Word): Word;

var
  UILoading: PUILoadingDialog = nil;

implementation

uses
  Math;

const
  Commands: array[0..3] of word =
    (cmYes, cmNo, cmOK, cmCancel);
  ButtonName: array[0..3] of String = (
    S_YesButton, S_NoButton, S_OkButton, S_CancelButton
  );
  MsgBoxTitles: array[0..3] of String = (
    S_WarningTitle, S_ErrorTitle, S_InformationTitle, S_ConfirmationTitle
  );

// From FreeVision

FUNCTION MsgBoxRectDlg (Dlg: PDialog; Var R: TRect; Const Msg: Sw_String;
  Params: Pointer; AOptions: Word): Word;
VAR I, X, ButtonCount: SmallInt; S: Sw_String; Control: PView;
    ButtonList: Array[0..4] Of PView;
BEGIN
   With Dlg^ Do Begin
     FormatStr(S, Msg, Params^);                      { Format the message }
     Control := New(PUIStaticText, Init(R, S));         { Create static text }
     Insert(Control);                                 { Insert the text }
     X := -2;                                         { Set initial value }
     ButtonCount := 0;                                { Clear button count }
     For I := 0 To 3 Do
       If (AOptions AND ($0100 SHL I) <> 0) Then Begin
         R.Assign(0, 0, 10, 2);                       { Assign screen area }
         Control := New(PButton, Init(R, UTF8Decode(ButtonName[I]),
           Commands[i], bfNormal));                   { Create button }
         Inc(X, Control^.Size.X + 2);                 { Adjust position }
         ButtonList[ButtonCount] := Control;          { Add to button list }
         Inc(ButtonCount);                            { Inc button count }
       End;
     X := (Size.X - X) SHR 1;                         { Calc x position }
     If (ButtonCount > 0) Then
       For I := 0 To ButtonCount - 1 Do Begin         { For each button }
        Control := ButtonList[I];                     { Transfer button }
        Insert(Control);                              { Insert button }
        Control^.MoveTo(X, Size.Y - 3);               { Position button }
        Inc(X, Control^.Size.X + 2);                  { Adjust position }
       End;
     SelectNext(False);                               { Select first button }
   End;
   If (AOptions AND mfInsertInApp = 0) Then
     MsgBoxRectDlg := DeskTop^.ExecView(Dlg) Else { Execute dialog }
     MsgBoxRectDlg := Application^.ExecView(Dlg); { Execute dialog }
end;

FUNCTION MsgBoxRect(Var R: TRect; Const Msg: Sw_String; Params: Pointer;
  AOptions: Word): Word;
var
  Dialog: PDialog;
BEGIN
  Dialog := New (PDialog, Init (R, UTF8Decode(MsgBoxTitles [AOptions
    AND $3])));                                       { Create dialog }
  with Dialog^ do
    R.Assign(3, 2, Size.X - 2, Size.Y - 3);          { Assign area for text }
  MsgBoxRect := MsgBoxRectDlg (Dialog, R, Msg, Params, AOptions);
  Dispose (Dialog, Done);                            { Dispose of dialog }
END;

FUNCTION MsgBox(Const Msg: Sw_String; Params: Pointer; AOptions: Word): Word;
VAR R: TRect;
BEGIN
   R.Assign(0, 0, 50, 10);                             { Assign area }
   If (AOptions AND mfInsertInApp = 0) Then           { Non app insert }
     R.Move((Desktop^.Size.X - R.B.X) DIV 2,
       (Desktop^.Size.Y - R.B.Y) DIV 2) Else          { Calculate position }
     R.Move((Application^.Size.X - R.B.X) DIV 2,
       (Application^.Size.Y - R.B.Y) DIV 2);          { Calculate position }
   MsgBox := MsgBoxRect(R, Msg, Params,
     AOptions);                                       { Create message box }
END;

// ---------------------------------

procedure LoadingStart(const S: String);
begin
  if UILoading <> nil then
    Dispose(UILoading, Done);
  UILoading := New(PUILoadingDialog, Init(S));
  Desktop^.Insert(UILoading);
  UILoading^.ReDraw;
end;

procedure LoadingStop;
begin
  if UILoading <> nil then
  begin
    Dispose(UILoading, Done);
    UILoading := nil;
  end;
end;

constructor TUIWindow.Init(var Bounds: TRect; ATitle: Sw_String; ANumber: LongInt);
begin
  inherited Init(Bounds, UTF8Decode(ATitle), ANumber);
  Self.Palette := wpBlueWindow;
  Self.Options := Self.Options or ofVersion20;
  Self.GrowMode := 0;
end;

function TUIWindow.GetPalette: PPalette;
const
  P: array [dpBlueDialog..dpGrayDialog] of String[Length(CBlueDialog)] =
    (CBlueDialog, CCyanDialog, CGrayDialog);
begin
  Result := PPalette(@P[Palette]);
end;

// ---------------------------------

function TUIListBox.GetText(Item: LongInt; MaxLen: LongInt): Sw_String;
begin
  Result := PUnicodeString(List^.At(Item))^;
end;

// ---------------------------------

procedure TUnicodeStringPtrCollection.Insert(Item: Pointer);
begin
  AtInsert(Count, Item);
end;

function TUnicodeStringPtrCollection.GetItem(var S: TStream): Pointer;
begin
  PUnicodeString(Result)^ := S.ReadUnicodeString;
end;

procedure TUnicodeStringPtrCollection.FreeItem(Item: Pointer);
begin
  PUnicodeString(Item)^ := '';
  Dispose(PUnicodeString(Item));
end;

procedure TUnicodeStringPtrCollection.PutItem(var S: TStream; Item: Pointer);
begin
  S.WriteUnicodeString(PUnicodeString(Item)^);
end;

procedure TUnicodeStringPtrCollection.AtUpdate(Index: LongInt; const AText: UnicodeString);
begin
  if (Index >= 0) and (Index <= Self.Count) then
  begin
    PUnicodeString(Items^[Index])^ := AText;
  end else
    Error(coIndexError, Index)
end;

// ---------------------------------

constructor TUILabel.Init(var Bounds: TRect; const AText: String; ALink: PView; APalette: RawByteString = CLabel);
begin
  inherited Init(Bounds, UTF8Decode(AText), ALink);
  Self.Palette := APalette;
end;

function TUILabel.GetPalette: PPalette;
begin
  Result := PPalette(@Self.Palette[1]);
end;

procedure TUILabel.Draw;
var
  R: TRect;
begin
  Self.GetBounds(R);
  R.B.X := R.A.X + Length(Self.Text) + 1;
  inherited Draw;
end;

// ---------------------------------

function TUIButton.GetPalette: PPalette;
const
  P: String[Length(CUIButton)] = CUIButton;
begin
  GetPalette := PPalette(@P);
end;

procedure TUIButton.Draw;
begin
  Self.SetState(sfDisabled, Self.Disabled);
  inherited Draw;
end;

procedure TUIButton.SetDisabled(const V: Boolean);
begin
  Self.Disabled := V;
  Self.DrawView;
end;

// ---------------------------------

constructor TUILoadingDialog.Init(const AText: String);
var
  R: TRect;
  L: PLabel;
begin
  Desktop^.GetExtent(R);
  R.A.X := (R.B.X div 2) - Length(AText) div 2 - 3;
  R.B.X := (R.B.X div 2) + Length(AText) div 2 + 4;
  R.A.Y := (R.B.Y div 2) - 3;
  R.B.Y := (R.B.Y div 2) + 2;
  inherited Init(R, '');
  //
  R.Assign(2, 2, 2 + Length(AText) + 1, 3);
  L := New(PLabel, Init(R, UTF8Decode(AText), nil));
  Self.Insert(L);
end;

procedure TUILoadingDialog.HandleEvent(var E: TEvent);
begin
  inherited HandleEvent(E);
end;

// ---------------------------------

function TUIInputLine.DataSize: LongWord;
begin
  Result := SizeOf(Sw_String);
end;

procedure TUIInputLine.SetData(var Rec);
begin
  Self.Data := Sw_String(Rec);
  Self.SelectAll(True);
end;

procedure TUIInputLine.GetData(var Rec);
begin
  Sw_String(Rec) := Self.Data;
end;

procedure TUIInputNumber.Validate;
var
  V, V0: Int64;
begin
  V := StrToInt64(Self.Data);
  // Real-time validation
  if Self.OnMax <> nil then
  begin
    V0 := V;
    V := Self.OnMax(V);
    if V <> V0 then
    begin
      Self.Data := IntToStr(V);
    end;
  end;
  V := StrToInt64(Self.Data);
  if Self.OnMin <> nil then
  begin
    V0 := V;
    V := Self.OnMin(V);
    if V <> V0 then
    begin
      Self.Data := IntToStr(V);
    end;
  end;
end;

procedure TUIInputNumber.HandleEvent(var E: TEvent);
var
  V: Int64;
  S: UnicodeString; // Old string
  C: LongInt; // Old cursor position
begin
  S := Self.Data;
  C := Self.CurPos;
  inherited HandleEvent(E);
  // Make sure the text is valid number
  if not TryStrToInt64(Self.Data, V) then
  begin
    if Self.Data = '' then
      Self.Data := '0'
    else
      Self.Data := S;
    Self.CurPos := C;
    Self.DrawView;
  end;
  // Remove left zeroes
  while (Self.Data[1] = '0') and (Length(Self.Data) > 1) do
  begin
    Delete(Self.Data, 1, 1);
    if Self.CurPos > Length(Self.Data) then
      Self.CurPos := Length(Self.Data);
  end;
  Self.DrawView;
end;

function TUIInputNumber.GetValue: Int64;
begin
  Result := StrToInt64(Self.Data);
end;

procedure TUIInputNumber.SetData(var Rec);
begin
  Self.Data := IntToStr(Int64(Rec));
end;

procedure TUIInputNumber.GetData(var Rec);
begin
  Self.Validate;
  Int64(Rec) := Self.GetValue;
end;

procedure TUIInputNumber.Draw;
begin
  if Self.State and sfFocused = 0 then
  begin
    Self.Validate;
  end;
  inherited Draw;
end;

// ---------------------------------

procedure TUIStaticText.Draw;
var
  B: TDrawBuffer;
begin
  // Fill the view with background color first before render text
  MoveChar(B, ' ', GetColor(1), Size.X);
  WriteLine(0, 0, Size.X, Size.Y, B);
  inherited Draw;
end;

end.

