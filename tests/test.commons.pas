unit Test.Commons;

{$mode ObjFPC}{$H+}

interface

uses
  Framework, Parted.Commons, Types;

type
  TTestCommonsMatch = class(TTestCase)
  public
    procedure Run; override;
  end;

  TTestCommonsConversions = class(TTestCase)
  public
    procedure Run; override;
  end;

implementation

procedure TTestCommonsMatch.Run;
var
  MatchResult: TStringDynArray;
begin
  MatchResult := Match('/dev/sda1   512 disk', ['([^\s]+)', '([^\s]+)']);
  Assert(Length(MatchResult) = 2, 'MatchResult length');
  Assert(MatchResult[0] = '/dev/sda1', 'MatchResult value 0');
  Assert(MatchResult[1] = '512', 'MatchResult value 1');
end;

procedure TTestCommonsConversions.Run;
begin
  Assert(BToGB(1024 * 1024 * 1024) = 1, 'BToGB(1024 * 1024 * 1024) = 1');
  Assert(BToMB(1024 * 1024) = 1, 'BToMB(1024 * 1024) = 1');
  Assert(BToKB(1024) = 1, 'BToKB(1024) = 1');
  Assert(ExtractQWordFromSize('1000204886016B') = 1000204886016, 'ExtractQWordFromSize(''1000204886016B'') = 1000204886016');
end;

initialization
  RegisterTest(TTestCommonsMatch);
  RegisterTest(TTestCommonsConversions);

end.
