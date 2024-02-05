unit UI.Main;

{$I configs.inc}

interface

uses
  Classes, SysUtils, Types,
  FreeVision,
  Parted.Devices,
  Parted.Partitions,
  Parted.Commons,
  UI.Devices;

const
  cmMenuAbout = 1001;
  cmMenuRefreshDevice = 1002;
  cmDeviceRefresh = 1003;
  cmMenuDisplayLog = 1004;
  cmDeviceAnchor = 12000;
  cmPartitionShowInfo = 1100;
  cmPartitionCreate = 1101;
  cmPartitionDelete = 1102;
  cmPartitionFormat = 1104;
  cmPartitionResize = 1105;
  cmPartitionUnmount = 1106;
  cmPartitionLabel = 1107;
  cmPartitionFlag = 1108;
  cmOperationUndo = 1200;
  cmOperationClear = 1201;
  cmOperationApply = 1202;
  cmOperatorExists = 1203;

type
  TUIMain = object(TApplication)
  private
    FMenuHelp,
    FMenuDevices,
    FMenuSystem: PMenuItem;
    FMenuItemRootDevice: PMenuItem;
    FDeviceArray: TPartedDeviceArray;

    procedure ResizeApplication(X, Y: LongInt);
  public
    destructor Done; virtual;
    procedure InitStatusLine; virtual;
    procedure InitMenuBar; virtual;
    procedure InitDeskTop; virtual;
    procedure HandleEvent(var E: TEvent); virtual;
  end;

var
  UIMain : TUIMain;
  WindowCountValue: LongInt;

implementation

uses
  UI.Commons,
  UI.Logs;

type
  // Draw a blank background
  TUIBlankBlackground = object(TBackground)
  public
    procedure Draw; virtual;
  end;
  PUIBlankBlackground = ^TUIBlankBlackground;

procedure TUIBlankBlackground.Draw;
var
  B: TDrawBuffer;
begin
  MoveChar(B, ' ', 0, Size.X);
  WriteLine(0, 0, Size.X, Size.Y, B);
end;

// ----------------------------------------------

destructor TUIMain.Done;
var
  I: LongInt;
begin
  for I := 0 to High(FDeviceArray) do
    FDeviceArray[I].Done;
  inherited;
end;

procedure TUIMain.InitDeskTop;
var
  R: TRect;
begin
  Self.GetExtent(R);
  if (MenuBar <> nil) then
    Inc(R.A.Y);
  if (StatusLine <> nil) then
    Dec(R.B.Y);
  DeskTop := New(PDesktop, Init(R));
  // We delete the default background, then insert our own
  {DeskTop^.Delete(DeskTop^.Background);
  Dispose(DeskTop^.Background, Done);
  DeskTop^.GetExtent(R);
  DeskTop^.Background := New(PUIBlankBlackground, Init(R, ' '));
  DeskTop^.Insert(DeskTop^.Background);}
end;

procedure TUIMain.InitStatusLine;
begin
end;

procedure TUIMain.InitMenuBar;
var
  R: TRect;
  M: PMenu;
  I: LongInt;
  DeviceArray: TPartedDeviceArray;
begin
  Self.GetExtent(R);
  R.B.Y := R.A.Y + 1;

  // Request for array of devices
  Self.FDeviceArray := QueryDeviceArray;

  Self.FMenuHelp := NewSubMenu(UTF8Decode(S_Help), hcNoContext, NewMenu(
    NewItem(UTF8Decode(S_About), '', kbNoKey, cmMenuAbout, hcNoContext, nil)
  ), nil);

  // Construct device menu
  Self.FMenuItemRootDevice := nil;
  for I := Pred(Length(Self.FDeviceArray)) downto 0 do
  begin
    FMenuItemRootDevice := NewItem(
      UTF8Decode(Format('%s (%s) %s', [Self.FDeviceArray[I].Path, Self.FDeviceArray[I].SizeApprox, Self.FDeviceArray[I].Name])),
      '', kbNoKey, cmDeviceAnchor + I, hcNoContext, FMenuItemRootDevice
    );
  end;

  Self.FMenuDevices := NewSubMenu(UTF8Decode(S_Devices), hcNoContext, NewMenu(Self.FMenuItemRootDevice), Self.FMenuHelp);

  Self.FMenuSystem := NewSubMenu(UTF8Decode('~T~Parted'), hcNoContext, NewMenu(
    NewItem(UTF8Decode(S_RefreshDevices), 'F5', kbF5, cmMenuRefreshDevice, hcNoContext,
    NewItem(UTF8Decode(S_Log), '', kbNoKey, cmMenuDisplayLog, hcNoContext,
    NewLine(
    NewItem(UTF8Decode(S_Quit), 'Alt-X', kbAltX, cmQuit, hcNoContext, nil))))
  ), FMenuDevices);

  M := NewMenu(Self.FMenuSystem);

  MenuBar := New(PMenuBar, Init(R, M));
end;

procedure TUIMain.HandleEvent(var E: TEvent);
var
  LDevice: PPartedDevice;
  Path: String;
  I: LongInt;
begin
  if E.What = evCommand then
  begin
    case E.Command of
      cmQuit:
        begin
          if Message(Desktop, evBroadcast, cmOperatorExists, nil) <> nil then
          begin
            if MsgBox(UTF8Decode(S_QuitMessage), nil, mfConfirmation + mfYesButton + mfNoButton) <> cmYes then
              Self.ClearEvent(E);
          end;
        end;
      cmResizeApp:
        begin
          Self.ResizeApplication(E.Id, E.InfoWord);
          Self.ClearEvent(E);
        end;
      cmMenuAbout:
        begin
          MsgBox(UTF8Decode(Format(S_AboutMessage, [{$I %DATE%}, IntToStr(FPC_VERSION) + '.' + IntToStr(FPC_RELEASE) + '.' + IntToStr(FPC_PATCH)])), nil, mfInformation + mfOKButton);
          Self.ClearEvent(E);
        end;
      cmMenuDisplayLog:
        begin
          ShowLogDialog;
          Self.ClearEvent(E);
        end;
      cmMenuRefreshDevice:
        begin
          Self.Delete(MenuBar);
          Dispose(MenuBar, Done);
          Self.InitMenuBar;
          Self.Insert(MenuBar);
          Self.ClearEvent(E);
          Message(Desktop, evBroadcast, cmDeviceRefresh, nil);
        end
      else
      begin
        if (E.Command >= cmDeviceAnchor) and (E.Command < cmDeviceAnchor + 1000) then
        begin
          LDevice := @Self.FDeviceArray[E.Command - cmDeviceAnchor];
          Path := LDevice^.Path;
          // Get device's detail information
          if not IsDeviceWindowOpened(LDevice^) then
          begin
            try
              QueryDeviceExists(Path);
              QueryDeviceAndPartitions(Path, LDevice^);
              if LDevice^.Table = 'unknown' then // This device has no partition table, wanna create it?
              begin
                if MsgBox(UTF8Decode(Format(S_CreatePartitionTableAsk, [LDevice^.Path])), nil, mfInformation + mfYesButton + mfNoButton) = cmYes then
                begin
                  // TODO: Create a new GPT
                  LoadingStart(UTF8Decode(S_CreatingGPT));
                  QueryCreateGPT(LDevice^.Path);
                  // Query for device again
                  QueryDeviceAndPartitions(Path, LDevice^);
                  LoadingStop;
                end;
              end;
              LoadingStart(S_LoadingPartitions);
              // Get partition's details
              QueryDeviceAll(LDevice^);
              LoadingStop;
              AddDeviceWindowToList(LDevice^);
            except
              on E: Exception do
              begin
                LoadingStop;
                MsgBox(UTF8Decode(E.Message), nil, mfOKButton);
                LDevice^.Done; // An exception here is dangerous - set partitions to empty to avoid further damage
              end;
            end;
            //
          end;
          Self.ClearEvent(E);
        end;
      end;
    end;
  end;
  inherited HandleEvent(E);
end;

procedure TUIMain.ResizeApplication(X, Y: LongInt);
var
  R: TRect;
  Mode: TVideoMode;
begin
  Self.GetBounds(R);
  { adapt to new size }
  if (R.B.Y - R.A.Y <> Y) or
     (R.B.X - R.A.X <> X) then
  begin
    Mode.Color := ScreenMode.Color;
    Mode.Col := X;
    Mode.Row := Y;
    Self.SetScreenVideoMode(Mode);
    Self.Redraw;
  end;
end;

end.

