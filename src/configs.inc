{$mode ObjFPC}{$H+}

{$macro on}
{$modeswitch advancedrecords}
{$modeswitch nestedprocvars}
{$modeswitch typehelpers}
{$if FPC_FULLVERSION >= 30301}
  {$define TPARTED_UNICODE}
{$endif}

{$ifndef UNIX}
  {$define TPARTED_TEST}
{$endif}

{$ifdef TPARTED_UNICODE}
  {$define FreeVision := UApp, UMsgBox, UDrivers, UViews, UMenus, FVConsts, UFVCommon, UDialogs, UValidate, Video, Objects, UEditors}
{$else}
  {$define FreeVision := App, MsgBox, Drivers, Views, Menus, FVConsts, FVCommon, Dialogs, Validate, Video, Objects, Editors}
{$endif}


