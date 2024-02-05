program tests;

{$I configs.inc}

uses
  SysUtils, Classes, Framework,
  Test.Commons, Test.Devices, Test.Partitions;

begin
  RunTests;
  Writeln('Press ENTER to exit...');
  Readln;
end.
