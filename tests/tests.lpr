program tests;

{$I configs.inc}
{$define TPARTED_TEST}

uses
  SysUtils, Classes, Framework,
  Test.Commons, Test.Devices, Test.Partitions;

begin
  RunTests;
  Writeln('Press ENTER to exit...');
  Readln;
end.
