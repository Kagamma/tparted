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

unit UI.Main;

{$I configs.inc}

interface

uses
  Classes, SysUtils, Types,
  FreeVision,
  Parted.Devices,
  Parted.Partitions,
  Parted.Commons, Locale,
  UI.Devices.PTable,
  UI.Devices;

const
  cmNothing = 60000;
  cmMenuAbout = 1001;
  cmMenuRefreshDevice = 1002;
  cmMessageDeviceRefresh = 1003;
  cmMenuDisplayLog = 1004;
  cmMenuDisplayFileSystemSupport = 1005;
  cmMenuSwitchColor = 1006;
  cmDeviceAnchor = 12000;
  cmPartitionShowInfo = 1100;
  cmPartitionCreate = 1101;
  cmPartitionDelete = 1102;
  cmPartitionFormat = 1104;
  cmPartitionResize = 1105;
  cmPartitionUnmount = 1106;
  cmPartitionLabel = 1107;
  cmPartitionFlag = 1108;
  cmDeviceCreateGPT = 1109;
  cmOperationUndo = 1200;
  cmOperationClear = 1201;
  cmOperationApply = 1202;
  cmMessageOperatorExists = 1203;

type
  TUIMain = object(TApplication)
  private
    FMenuHelp,
    FMenuWindow,
    FMenuDevices,
    FMenuSystem: PMenuItem;
    FMenuItemRootDevice: PMenuItem;
    FDeviceArray: TPartedDeviceArray;

    procedure ResizeApplication(X, Y: LongInt);
  public
    destructor Done; virtual;
    constructor Init;
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
  Parted.Logs,
  UI.Commons,
  UI.FileSystemSupport,
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

constructor TUIMain.Init;
begin
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

  Self.FMenuHelp := NewSubMenu(S_Help.ToUnicode, hcNoContext, NewMenu(
    NewItem(S_About.ToUnicode, '', kbNoKey, cmMenuAbout, hcNoContext, nil)
  ), nil);

  Self.FMenuWindow := NewSubMenu(S_MenuWindow.ToUnicode, hcNoContext, NewMenu(
    NewItem(S_MenuPreviousWindow.ToUnicode, 'Shift-F7', kbShiftF7, cmPrev, hcNoContext,
    NewItem(S_MenuNextWindow.ToUnicode, 'F7', kbF7, cmNext, hcNoContext,
    NewItem(S_MenuMaximize.ToUnicode, 'F8', kbF8, cmZoom, hcNoContext,
    NewLine(
    NewItem(S_MenuSwitchColor.ToUnicode, '', kbNoKey, cmMenuSwitchColor, hcNoContext, nil)))))
  ), Self.FMenuHelp);

  // Construct device menu
  Self.FMenuItemRootDevice := nil;
  for I := Pred(Length(Self.FDeviceArray)) downto 0 do
  begin
    FMenuItemRootDevice := NewItem(
      Format('%s (%s) %s', [Self.FDeviceArray[I].Path, Self.FDeviceArray[I].SizeApprox, Self.FDeviceArray[I].Name]).ToUnicode,
      '', kbNoKey, cmDeviceAnchor + I, hcNoContext, FMenuItemRootDevice
    );
  end;

  Self.FMenuDevices := NewSubMenu(S_Devices.ToUnicode, hcNoContext, NewMenu(Self.FMenuItemRootDevice), Self.FMenuWindow);

  Self.FMenuSystem := NewSubMenu('~T~Parted'.ToUnicode, hcNoContext, NewMenu(
    NewItem(S_RefreshDevices.ToUnicode, 'F5', kbF5, cmMenuRefreshDevice, hcNoContext,
    NewLine(
    NewItem(S_MenuLogs.ToUnicode, '', kbNoKey, cmMenuDisplayLog, hcNoContext,
    NewItem(S_MenuFileSystemSupport.ToUnicode, '', kbNoKey, cmMenuDisplayFileSystemSupport, hcNoContext,
    NewLine(
    NewItem(S_Quit.ToUnicode, 'Alt-X', kbAltX, cmQuit, hcNoContext, nil))))))
  ), FMenuDevices);

  M := NewMenu(Self.FMenuSystem);

  MenuBar := New(PMenuBar, Init(R, M));
end;

procedure TUIMain.HandleEvent(var E: TEvent);
var
  LDevice: PPartedDevice;
  Path: String;
  TableType: String;
  I: LongInt;
begin
  if E.What = evCommand then
  begin
    case E.Command of
      cmQuit:
        begin
          if Message(Desktop, evBroadcast, cmMessageOperatorExists, nil) <> nil then
          begin
            if MsgBox(S_QuitMessage, nil, mfConfirmation + mfYesButton + mfNoButton) <> cmYes then
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
          MsgBox(Format(S_AboutMessage, [{$I %DATE%}, IntToStr(FPC_VERSION) + '.' + IntToStr(FPC_RELEASE) + '.' + IntToStr(FPC_PATCH)]), nil, mfInformation + mfOKButton);
          Self.ClearEvent(E);
        end;
      cmMenuDisplayLog:
        begin
          ShowLogDialog;
          Self.ClearEvent(E);
        end;
      cmMenuDisplayFileSystemSupport:
        begin
          ShowFileSystemSupportDialog;
          Self.ClearEvent(E);
        end;
      cmMenuSwitchColor:
        begin
          if AppPalette = apColor then
            AppPalette := apMonochrome
          else
            AppPalette := apColor;
          Self.ReDraw;
          Self.ClearEvent(E);
        end;
      cmMenuRefreshDevice:
        begin
          Self.Delete(MenuBar);
          Dispose(MenuBar, Done);
          Self.InitMenuBar;
          Self.Insert(MenuBar);
          Self.ClearEvent(E);
          Message(Desktop, evBroadcast, cmMessageDeviceRefresh, nil);
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
              QueryDeviceAndPartitions(Path, LDevice^);
              if LDevice^.Table = 'unknown' then // This device has no partition table, wanna create it?
              begin
                if (MsgBox(Format(S_CreatePartitionTableAsk, [LDevice^.Path]), nil, mfInformation + mfYesButton + mfNoButton) = cmYes) and
                   ShowPTableDialog(TableType)  then
                begin
                  LoadingStart(Format(S_CreatingGPT, [TableType]));
                  QueryCreatePTable(TableType, LDevice^.Path);
                  // Query for device again
                  QueryDeviceAndPartitions(Path, LDevice^);
                  LoadingStop;
                end else
                begin
                  Self.ClearEvent(E);
                  Exit;
                end;
              end;
              LoadingStart(S_LoadingPartitions);
              // Get partition's details
              QueryDeviceAll(LDevice^);
              LoadingStop;
              AddDeviceWindowToList(LDevice^, E.Command);
            except
              on E: Exception do
              begin
                LoadingStop;
                WriteLog(lsError, E.Message);
                MsgBox(E.Message, nil, mfOKButton);
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

