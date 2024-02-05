unit Test.Partitions;

{$mode ObjFPC}{$H+}

interface

uses
  SysUtils, Classes, Types,
  Framework,
  Parted.Commons, Parted.Devices, Parted.Partitions;

type
  TTestPartitions = class(TTestCase)
  public
    DeviceRawJsonString: String;
    PartUsedAndAvailString: String;
    MountStatusJsonString: String;
    procedure Setup; override;
    procedure Run; override;
  end;

implementation

procedure TTestPartitions.Setup;
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.LoadFromFile('../testdata/parted_output_json.txt');
    DeviceRawJsonString := SL.Text;
    SL.LoadFromFile('../testdata/findmnt_output_json.txt');
    MountStatusJsonString := SL.Text;
    SL.Clear;
    SL.LoadFromFile('../testdata/df_output_human.txt');
    PartUsedAndAvailString := SL[1];
  finally
    SL.Free;
  end;
end;

procedure TTestPartitions.Run;
var
  Device: TPartedDevice;
  Part: TPartedPartition;
begin
  ParseDeviceAndPartitionsFromJsonString(DeviceRawJsonString, Device);
  ParseUsedAndAvailableBlockFromString(PartUsedAndAvailString, Part);
  Assert(Part.PartUsed = 25792503808, 'Part.PartUsed = 25792503808, but ' + IntToStr(Part.PartUsed));
  Assert(Part.PartFree = 70167166976, 'Part.PartFree = 70167166976, but ' + IntToStr(Part.PartFree));
  ParseMountStatusFromJsonString(MountStatusJsonString, Part);
  Assert(Part.MountPoint = '/home', 'Part.MountPoint = /home');
end;

initialization
  RegisterTest(TTestPartitions);

end.

