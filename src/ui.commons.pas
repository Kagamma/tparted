{
tparted
Copyright (C) 2024-2026 kagamma

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
  Classes, SysUtils, Types, StrUtils,
  FreeVision,
  Parted.Commons, Locale,
  DataTypes;

const
  CUIButton = #10#22#12#13#14#14#14#15;
  cmListChanged = 50000;

type
  TUIWindow = object(TWindow)
  public
    constructor Init(var Bounds: TRect; ATitle: String; ANumber: LongInt);
    function GetPalette: PPalette; virtual;
  end;
  PUIWindow = ^TUIWindow;

  // A new listbox, to be used with TUnicodeStringPtrCollection
  TUIListBox = object(TListBox)
  public
    function GetText(Item: LongInt; MaxLen: LongInt): TPartedString; virtual;
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
    procedure AtUpdate(Index: LongInt; const AText: TPartedString);
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
    Status: String;
    TextLabel: PLabel;
    constructor Init(const AText: String);
    procedure HandleEvent(var E: TEvent); virtual;
    procedure Update(const AText: String);
  end;
  PUILoadingDialog = ^TUILoadingDialog;

  // New TUIInputLine with proper DataSize and SetData methods to replace the buggy ones
  // See https://gitlab.com/freepascal.org/fpc/source/-/merge_requests/581
  TUIInputLine = object(TInputLine)
  public
    IsPassword: Boolean;
    function DataSize: LongWord; virtual;
    procedure SetData(var Rec); virtual;
    procedure GetData(var Rec); virtual;
    procedure Draw; virtual;
  end;
  PUIInputLine = ^TUIInputLine;

  // TUIInputNmber
  TUIInputNumberValidateProc = function(V: Int64): Int64 is nested;
  TUIInputNumberChangedProc = procedure(V: Int64) is nested;
  TUIInputNumber = object(TUIInputLine)
  private
    procedure Validate;
  public
    Disabled: Boolean;
    OnChanged: TUIInputNumberChangedProc;
    OnMin,
    OnMax: TUIInputNumberValidateProc;
    procedure HandleEvent(var E: TEvent); virtual;
    function GetValue: Int64;
    function DataSize: LongWord; virtual;
    procedure SetData(var Rec); virtual;
    procedure GetData(var Rec); virtual;
    procedure Draw; virtual;
    procedure SetDisabled(const V: Boolean);
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

  // New TUIMenuBox, with fixes for misaligned mouse position (TODO: latest FPC trunk fixed the issue already)
  PUIMenuBox = ^TUIMenuBox;
  TUIMenuBox = object(TMenuBox)
  public
    procedure Draw; virtual;
  end;

procedure LoadingStart(const S: String);
procedure LoadingUpdate(const S: String);
procedure LoadingStop;

// Copied from Free Vision source code. Since the original MessageBox is buggy, we implement fixes
// on our own instead. See https://gitlab.com/freepascal.org/fpc/source/-/issues/40607
FUNCTION MessageDlg(Const Msg: String; Params: Pointer; AOptions: Word): Word;
FUNCTION MsgBoxRect(Var R: TRect; Const Msg: TPartedString; Params: Pointer;
  AOptions: Word): Word;

var
  UILoading: PUILoadingDialog = nil;

implementation

uses
  Lazarus.UTF8,
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

FUNCTION MsgBoxRectDlg (Dlg: PDialog; Var R: TRect; Const Msg: TPartedString;
  Params: Pointer; AOptions: Word): Word;
VAR I, X, ButtonCount: SmallInt; S: TPartedString; Control: PView;
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
         Control := New(PButton, Init(R, ButtonName[I].ToUnicode,
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

FUNCTION MsgBoxRect(Var R: TRect; Const Msg: TPartedString; Params: Pointer;
  AOptions: Word): Word;
var
  Dialog: PDialog;
BEGIN
  Dialog := New (PDialog, Init (R, MsgBoxTitles [AOptions
    AND $3].ToUnicode));                             { Create dialog }
  with Dialog^ do
    R.Assign(3, 2, Size.X - 2, Size.Y - 3);          { Assign area for text }
  MsgBoxRect := MsgBoxRectDlg (Dialog, R, Msg, Params, AOptions);
  Dispose (Dialog, Done);                            { Dispose of dialog }
END;

FUNCTION MessageDlg(Const Msg: String; Params: Pointer; AOptions: Word): Word;
VAR R: TRect;
BEGIN
   R.Assign(0, 0, 50, 10);                             { Assign area }
   If (AOptions AND mfInsertInApp = 0) Then           { Non app insert }
     R.Move((Desktop^.Size.X - R.B.X) DIV 2,
       (Desktop^.Size.Y - R.B.Y) DIV 2) Else          { Calculate position }
     R.Move((Application^.Size.X - R.B.X) DIV 2,
       (Application^.Size.Y - R.B.Y) DIV 2);          { Calculate position }
   MessageDlg := MsgBoxRect(R, Msg.TrimRight.ToUnicode, Params,
     AOptions);                                       { Create message box }
END;

// ---------------------------------

var
  LoadingText: String;

procedure LoadingStart(const S: String);
begin
  if UILoading <> nil then
    Dispose(UILoading, Done);
  LoadingText := S;
  UILoading := New(PUILoadingDialog, Init(S));
  Desktop^.Insert(UILoading);
  UILoading^.ReDraw;
end;

procedure LoadingUpdate(const S: String);
begin
  if UILoading <> nil then
  begin
    UILoading^.Update(LoadingText + #13 + S);
  end else
  begin
    UILoading := New(PUILoadingDialog, Init(LoadingText + #13 + S));
    Desktop^.Insert(UILoading);
  end;
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

// ---------------------------------

constructor TUIWindow.Init(var Bounds: TRect; ATitle: String; ANumber: LongInt);
begin
  inherited Init(Bounds, ATitle.ToUnicode, ANumber);
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

function TUIListBox.GetText(Item: LongInt; MaxLen: LongInt): TPartedString;
begin
  Result := PPartedString(List^.At(Item))^;
end;

// ---------------------------------

procedure TUnicodeStringPtrCollection.Insert(Item: Pointer);
begin
  AtInsert(Count, Item);
end;

function TUnicodeStringPtrCollection.GetItem(var S: TStream): Pointer;
begin
  Result := nil;
  {$ifdef TPARTED_UNICODE}
  PPartedString(Result)^ := S.ReadUnicodeString;
  {$else}
  PPartedString(Result)^ := S.ReadStr^;
  {$endif}
end;

procedure TUnicodeStringPtrCollection.FreeItem(Item: Pointer);
begin
  PPartedString(Item)^ := '';
  Dispose(PPartedString(Item));
end;

procedure TUnicodeStringPtrCollection.PutItem(var S: TStream; Item: Pointer);
begin
  {$ifdef TPARTED_UNICODE}
  S.WriteUnicodeString(PPartedString(Item)^);
  {$else}
  S.WriteStr(PPartedString(Item));
  {$endif}
end;

procedure TUnicodeStringPtrCollection.AtUpdate(Index: LongInt; const AText: TPartedString);
begin
  if (Index >= 0) and (Index <= Self.Count) then
  begin
    PPartedString(Items^[Index])^ := AText;
  end else
    Error(coIndexError, Index)
end;

// ---------------------------------

constructor TUILabel.Init(var Bounds: TRect; const AText: String; ALink: PView; APalette: RawByteString = CLabel);
begin
  inherited Init(Bounds, AText.ToUnicode, ALink);
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
  //Self.GetBounds(R);
  //R.B.X := R.A.X + UTF8TerminalLength(Self.Text.ToUTF8) + 2;
  //Self.SetBounds(R);
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
  Len, H: LongInt;
  I: LongInt;
  ATexts: TStringDynArray;
begin
  ATexts := SplitString(AText, #13);
  // Find the max length of text
  Len := 1;
  for I := 0 to High(ATexts) do
    if Len < Length(ATexts[I]) then
      Len := Length(ATexts[I]);
  //
  H := AText.CountChar(#13) + 1;
  Desktop^.GetExtent(R);
  R.A.X := (R.B.X div 2) - Len div 2 - 4;
  R.B.X := (R.B.X div 2) + Len div 2 + 3;
  R.A.Y := (R.B.Y div 2) - 5;
  R.B.Y := (R.B.Y div 2) - 1 + H;
  inherited Init(R, '');
  //
  Self.Status := AText;
  for I := 0 to High(ATexts) do
  begin
    R.Assign(2, 2 + I, 2 + Len + 1, 3 + I);
    Self.TextLabel := New(PLabel, Init(R, ATexts[I].ToUnicode, nil));
    Self.Insert(Self.TextLabel);
  end;
end;

procedure TUILoadingDialog.HandleEvent(var E: TEvent);
begin
  inherited HandleEvent(E);
end;

procedure TUILoadingDialog.Update(const AText: String);
var
  R, RO: TRect;
  L: PLabel;
  Len, H: LongInt;
  I: LongInt;
  ATexts: TStringDynArray;
begin
  ATexts := SplitString(AText, #13);
  // Find the max length of text
  Len := 1;
  for I := 0 to High(ATexts) do
    if Len < Length(ATexts[I]) then
      Len := Length(ATexts[I]);
  //
  H := AText.CountChar(#13) + 1;
  Desktop^.GetExtent(R);
  Self.GetBounds(RO);
  R.A.X := (R.B.X div 2) - Len div 2 - 4;
  R.B.X := (R.B.X div 2) + Len div 2 + 3;
  R.A.Y := (R.B.Y div 2) - 5;
  R.B.Y := (R.B.Y div 2) - 1 + H;
  R.A.X := Min(R.A.X, RO.A.X);
  R.A.Y := Min(R.A.Y, RO.A.Y);
  R.B.X := Max(R.B.X, RO.B.X);
  R.B.Y := Max(R.B.Y, RO.B.Y);
  Self.ChangeBounds(R);
  //
  Self.Status := AText;
  if Self.TextLabel <> nil then
  begin
    Dispose(Self.TextLabel, Done);
    Self.TextLabel := nil;
  end;
  for I := 0 to High(ATexts) do
  begin
    R.Assign(2, 2 + I, 2 + Len + 1, 3 + I);
    Self.TextLabel := New(PLabel, Init(R, ATexts[I].ToUnicode, nil));
    Self.Insert(Self.TextLabel);
  end;
end;

// ---------------------------------

function TUIInputLine.DataSize: LongWord;
var
  DSize: LongWord;
begin
  Result := SizeOf(UnicodeString);
end;

procedure TUIInputLine.SetData(var Rec);
begin
  {$ifdef TPARTED_UNICODE}
  Self.Data := UnicodeString(Rec);
  {$else}
  Self.Data^ := UnicodeString(Rec);
  {$endif}
  Self.SelectAll(True);
end;

procedure TUIInputLine.GetData(var Rec);
begin
  {$ifdef TPARTED_UNICODE}
  UnicodeString(Rec) := Self.Data;
  {$else}
  UnicodeString(Rec) := Self.Data^;
  {$endif}
end;

procedure TUIInputLine.Draw;
var
  OldData: TPartedString;
  I: LongInt;
begin
  if Self.IsPassword then
  begin
    {$ifdef TPARTED_UNICODE}
    OldData := Self.Data;
    {$else}
    OldData := Self.Data^;
    {$endif}
    for I := 1 to Length(OldData) do
      {$ifdef TPARTED_UNICODE}
      Self.Data[I] := '*';
      {$else}
      Self.Data^[I] := '*';
      {$endif}
    inherited;
    {$ifdef TPARTED_UNICODE}
    Self.Data := OldData;
    {$else}
    Self.Data^ := OldData;
    {$endif}
  end else
    inherited;
end;

procedure TUIInputNumber.Validate;
var
  V, V0: Int64;
begin
  V := Self.GetValue;
  {$ifdef TPARTED_UNICODE}
  Self.Data := V.ToString.ToUnicode;
  {$else}
  Self.Data^ := V.ToString.ToUnicode;
  {$endif}
  // Real-time validation
  if Self.OnMax <> nil then
  begin
    V0 := V;
    V := Self.OnMax(V);
    if V <> V0 then
    begin
      {$ifdef TPARTED_UNICODE}
      Self.Data := V.ToString.ToUnicode;
      {$else}
      Self.Data^ := V.ToString.ToUnicode;
      {$endif}
    end;
  end;
  V := Self.GetValue;
  if Self.OnMin <> nil then
  begin
    V0 := V;
    V := Self.OnMin(V);
    if V <> V0 then
    begin
      {$ifdef TPARTED_UNICODE}
      Self.Data := V.ToString.ToUnicode;
      {$else}
      Self.Data^ := V.ToString.ToUnicode;
      {$endif}
    end;
  end;
end;

procedure TUIInputNumber.HandleEvent(var E: TEvent);
var
  OldS: {$ifdef TPARTED_UNICODE}UnicodeString{$else}ShortString{$endif}; // Old string
begin
  {$ifdef TPARTED_UNICODE}
  OldS := Self.Data;
  {$else}
  OldS := Self.Data^;
  {$endif}

  inherited HandleEvent(E);
  {$ifdef TPARTED_UNICODE}
  Self.Data := UpCase(Self.Data);
  {$else}
  Self.Data^ := UpCase(Self.Data^);
  {$endif}
  Self.DrawView;

  if Self.OnChanged <> nil then
  begin
    {$ifdef TPARTED_UNICODE}
    if OldS <> Self.Data then
      Self.OnChanged(Self.GetValue);
    {$else}
    if OldS <> Self.Data^ then
      Self.OnChanged(Self.GetValue);
    {$endif}
  end;
end;

function TUIInputNumber.GetValue: Int64;
begin
  {$ifdef TPARTED_UNICODE}
  Result := Eval(Self.Data.ToUTF8);
  {$else}
  Result := Eval(Self.Data^);
  {$endif}
end;

function TUIInputNumber.DataSize: LongWord;
begin
  Result := SizeOf(Int64);
end;

procedure TUIInputNumber.SetData(var Rec);
begin
  {$ifdef TPARTED_UNICODE}
  Self.Data := Int64(Rec).ToString.ToUnicode;
  {$else}
  Self.Data^ := Int64(Rec).ToString.ToUnicode;
  {$endif}
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

procedure TUIInputNumber.SetDisabled(const V: Boolean);
begin
  if V then
  begin
    Self.Options := Self.Options and not ofSelectable;
    Self.State := Self.State or sfDisabled;
    Self.DrawView;
  end else
  begin
    Self.Options := Self.Options or ofSelectable;
    Self.State := Self.State and not sfDisabled;
    Self.DrawView;
  end;
  Self.Disabled := V;
end;

// ---------------------------------

// Copied from Free Vision implementation of TStaticText, with fixes for weird artifact issue
PROCEDURE TUIStaticText.Draw;
VAR Just: Byte; I, J, P, Y, L: Sw_Integer; S: TPartedString;
  B : TDrawBuffer;
  Color : Byte;
BEGIN
   GetText(S);                                        { Fetch text to write }
   Color := GetColor(1);
   P := 1;                                            { X start position }
   Y := 0;                                            { Y start position }
   L := Length(S);                                    { Length of text }
   While (Y < Size.Y) Do Begin
    MoveChar(B, ' ', Color, Size.X);
    if P <= L then
    begin
      Just := 0;                                       { Default left justify }
      If (S[P] = #2) Then Begin                        { Right justify AnsiChar }
        Just := 2;                                     { Set right justify }
        Inc(P);                                        { Next character }
      End;
      If (S[P] = #3) Then Begin                        { Centre justify AnsiChar }
        Just := 1;                                     { Set centre justify }
        Inc(P);                                        { Next character }
      End;
      I := P;                                          { Start position }
      repeat
        J := P;
        while (P <= L) and (S[P] = ' ') do
          Inc(P);
        while (P <= L) and (S[P] <> ' ') and (S[P] <> #13) do
          Inc(P);
      until (P > L) or (P >= I + Size.X) or (S[P] = #13);
      If P > I + Size.X Then                           { Text to long }
        If J > I Then
          P := J
        Else
          P := I + Size.X;
      Case Just Of
        0: J := 0;                           { Left justify }
        1: J := (Size.X - (P-I)) DIV 2;      { Centre justify }
        2: J := Size.X - (P-I);              { Right justify }
      End;
      MoveBuf(B[J], S[I], Color, P - I);
      While (P <= L) AND (P-I <= Size.X) AND ((S[P] = #13) OR (S[P] = #10))
        Do Inc(P);                                     { Remove CR/LF }
    End;
    WriteLine(0, Y, Size.X, 1, B);
    Inc(Y);                                          { Next line }
  End;
END;

// ---------------------------------

procedure TUIMenuBox.Draw;
var
  R: TRect;
begin
  {$if FPC_FULLVERSION >= 30301}
  inherited;
  {$else}
  State := State and not sfShadow;
  Self.GetBounds(R);
  Dec(R.A.Y);
  Dec(R.B.Y);
  Self.SetBounds(R);
  inherited;
  Inc(R.A.Y);
  Inc(R.B.Y);
  Self.SetBounds(R);
  {$endif}
end;

end.

