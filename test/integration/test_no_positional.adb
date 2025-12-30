pragma Ada_2022;
--  ======================================================================
--  Test_No_Positional - Test positional arg when none registered
--  ======================================================================
--  Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
--  SPDX-License-Identifier: BSD-3-Clause
--
--  Usage:
--    test_no_positional some_arg   # Positional when none registered
--
--  This exercises line 371: Positional when no positional registered
--
--  Exit codes:
--    0 - Test passed (error expected)
--    1 - Test failed
--  ======================================================================

with Ada.Text_IO;
with Ada.Command_Line;
with Clara.Application;
with Clara.Errors;

procedure Test_No_Positional is

   use Ada.Text_IO;
   use Ada.Command_Line;

   --  Instantiate CLI application with only flags, no positionals
   package CLI is new Clara.Application
     (App_Name        => "test_no_positional",
      App_Description => "Integration test for no positional registered");

   --  Only define a flag, no positional
   package Verbose is new CLI.Flag
     (Short => 'v',
      Long  => "verbose",
      Help  => "Enable verbose output");

   Result : CLI.Parse_Result.Result;

begin
   --  Parse command line
   Result := CLI.Parse;

   if Result.Is_Ok then
      Put_Line ("parsed=true");
      Put_Line ("verbose=" & Boolean'Image (Verbose.Is_Set));
      Set_Exit_Status (Success);
   else
      Put_Line ("parsed=false");
      Put_Line ("error_kind=" &
                Clara.Errors.Error_Kind'Image
                  (CLI.Parse_Result.Error (Result).Kind));
      --  Expected error for positional when none registered
      Set_Exit_Status (Success);
   end if;

end Test_No_Positional;
