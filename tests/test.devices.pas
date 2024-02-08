unit Test.Devices;

{$mode ObjFPC}{$H+}

interface

uses
  SysUtils, Classes, Types,
  Framework,
  Parted.Commons, Locale, Parted.Devices;

type
  TTestDevices = class(TTestCase)
  public
    DeviceRawArray: TStringDynArray;
    procedure Setup; override;
    procedure Run; override;
  end;

implementation

procedure TTestDevices.Setup;
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.LoadFromFile('../testdata/parted_output_machine.txt');
    DeviceRawArray := SLToSA(SL);
  finally
    SL.Free;
  end;
end;

procedure TTestDevices.Run;
var
  DeviceArray: TPartedDeviceArray;
begin
  DeviceArray := ParseDevicesFromStringArray(DeviceRawArray);
  Assert(Length(DeviceArray) = 3, 'Length(DeviceArray) = 3');
  Assert(DeviceArray[0].Path = '/dev/sda', 'DeviceArray[0].Path = ''/dev/sda''');
  Assert(DeviceArray[0].SizeApprox = '1000GB', 'DeviceArray[0].SizeApprox = ''1000GB''');
end;

initialization
  RegisterTest(TTestDevices);

end.

