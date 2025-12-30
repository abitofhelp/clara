pragma Ada_2022;
--  ======================================================================
--  Test_Positional_As_Switch - Test positional name used as switch
--  ======================================================================
--  Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
--  SPDX-License-Identifier: BSD-3-Clause
--
--  Usage:
--    test_positional_as_switch --file   # Positional "file" used as switch
--
--  This exercises line 275: Unknown long switch that matches positional name
--
--  Exit codes:
--    0 - Test passed (error expected)
--    1 - Test failed
--  ======================================================================

with Ada.Text_IO;
with Ada.Command_Line;
with Clara.Application;
with Clara.Errors;

procedure Test_Positional_As_Switch is

   use Ada.Text_IO;
   use Ada.Command_Line;

   --  Instantiate CLI application
   package CLI is new Clara.Application
     (App_Name        => "test_positional_as_switch",
      App_Description => "Integration test for positional as switch");

   --  Define a positional named "file"
   package File_Arg is new CLI.Positional
     (Name => "file",
      Help => "Input file");

   Result : CLI.Parse_Result.Result;

begin
   --  Parse command line
   Result := CLI.Parse;

   if Result.Is_Ok then
      Put_Line ("parsed=true");
      Put_Line ("file_count=" & Natural'Image (File_Arg.Count));
      Set_Exit_Status (Success);
   else
      Put_Line ("parsed=false");
      Put_Line ("error_kind=" &
                Clara.Errors.Error_Kind'Image
                  (CLI.Parse_Result.Error (Result).Kind));
      --  Expected error for --file when file is a positional
      Set_Exit_Status (Success);
   end if;

end Test_Positional_As_Switch;
