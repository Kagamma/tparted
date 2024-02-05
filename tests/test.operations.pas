unit Test.Devices;

{$mode ObjFPC}{$H+}

interface

uses
  SysUtils, Classes, Types,
  Framework,
  Parted.Commons, Parted.Operations;

type
  TTestOperations = class(TTestCase)
  public
    procedure Setup; override;
    procedure Run; override;
  end;

implementation

procedure TTestOperations.Setup;
begin
end;

procedure TTestOperations.Run;
begin
end;

initialization
  RegisterTest(TTestOperations);

end.

