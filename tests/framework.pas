unit Framework;

{$mode ObjFPC}{$H+}

interface

uses
  SysUtils, Classes, Contnrs, Generics.Collections;

type
  TTestCase = class
  public
    Name: String;
    procedure Setup; virtual;
    procedure Teardown; virtual;
    procedure Run; virtual;
  end;
  TTestCaseClass = class of TTestCase;
  TClassList = specialize TList<TTestCaseClass>;

procedure RegisterTest(ATestCase: TTestCaseClass);
procedure RunTests;

var
  TestCaseList: TClassList;

implementation

procedure TTestCase.Setup;
begin
end;

procedure TTestCase.Teardown;
begin
end;

procedure TTestCase.Run;
begin
end;

procedure RegisterTest(ATestCase: TTestCaseClass);
begin
  TestCaseList.Add(ATestCase);
end;

procedure RunTests;
var
  I,
  Passed: QWord;
  TestCase: TTestCase;
begin
  Passed := 0;
  for I := 0 to Pred(TestCaseList.Count) do
  begin
    TestCase := TestCaseList[I].Create;
    TestCase.Setup;
    try
      try
        TestCase.Run;
        Inc(Passed);
        Writeln(I, #9, '[PASSED] ', TestCase.ClassName);
      except
        on E: Exception do
          Writeln(I, #9, '[FAILED] ', TestCase.ClassName, ': ', E.Message);
      end;
    finally
      TestCase.Teardown;
      TestCase.Free;
    end;
  end;
  Writeln;
  Writeln(Passed, ' / ', TestCaseList.Count, ' test cases passed.');
end;

initialization
  TestCaseList := TClassList.Create;

finalization
  TestCaseList.Free;

end.
