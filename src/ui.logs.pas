unit UI.Logs;

{$I configs.inc}

interface

uses
  SysUtils, Classes, FreeVision,
  UI.Commons,
  Parted.Commons,
  Parted.Logs;

procedure ShowLogDialog;

implementation

procedure ShowLogDialog;
var
  R: TRect;
  D: PDialog;
  S: PScrollBar;
  C: PUnicodeStringPtrCollection;
  L: PUIListBox;
  Str: String;
begin
  Desktop^.GetExtent(R);
  R.Grow(-1, -1);

  D := New(PDialog, Init(R, S_Logs));

  // Scrollbar
  D^.GetExtent(R);
  Dec(R.B.X);
  R.A.X := R.B.X - 1;
  Inc(R.A.Y);
  Dec(R.B.Y);
  S := New(PScrollBar, Init(R));
  D^.Insert(S);

  R.A.X := 1;
  Dec(R.B.X);
  L := New(PUIListBox, Init(R, 1, S));
  D^.Insert(L);

  C := New(PUnicodeStringPtrCollection, Init(8, 8));
  for Str in Log do
  begin
    C^.Insert(GetUnicodeStr(Str));
  end;
  L^.NewList(C);
  L^.FocusItem(Pred(Log.Count));

  Desktop^.ExecView(D);

  Dispose(D);
  Dispose(C);
end;

end.