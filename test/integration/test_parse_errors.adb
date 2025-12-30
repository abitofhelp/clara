pragma Ada_2022;
--  ======================================================================
--  Test_Parse_Errors - Integration test for error conditions
--  ======================================================================
--  Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
--  SPDX-License-Identifier: BSD-3-Clause
--
--  Usage:
--    test_parse_errors --unknown      # Unknown switch error
--    test_parse_errors -o             # Missing value error
--    test_parse_errors                # Missing required error
--
--  Exit codes:
--    0 - Expected error occurred
--    1 - Unexpected result
--  ======================================================================

with Ada.Text_IO;
with Ada.Command_Line;
with Clara.Application;
with Clara.Errors;

procedure Test_Parse_Errors is

   use Ada.Text_IO;
   use Ada.Command_Line;

   --  Instantiate CLI application
   package CLI is new Clara.Application
     (App_Name        => "test_parse_errors",
      App_Description => "Integration test for error conditions");

   --  Define option that requires value
   package Output is new CLI.Option
     (Short      => 'o',
      Long       => "output",
      Value_Name => "FILE",
      Help       => "Output file path");

   --  Define required option
   package Config is new CLI.Option
     (Long       => "config",
      Value_Name => "PATH",
      Help       => "Configuration file",
      Required   => True);

   Result : CLI.Parse_Result.Result;

begin
   --  Parse command line
   Result := CLI.Parse;

   --  Output result for verification
   if Result.Is_Ok then
      Put_Line ("parsed=true");
      Put_Line ("output_has=" & Boolean'Image (Output.Has_Value));
      Put_Line ("config_has=" & Boolean'Image (Config.Has_Value));
      Set_Exit_Status (Success);
   else
      Put_Line ("parsed=false");
      Put_Line ("error_kind=" &
                Clara.Errors.Error_Kind'Image
                  (CLI.Parse_Result.Error (Result).Kind));
      Put_Line ("error=" &
                Clara.Errors.Format (CLI.Parse_Result.Error (Result)));

      --  For error tests, error is expected - exit with success
      --  The test runner will verify the specific error type
      Set_Exit_Status (Success);
   end if;

end Test_Parse_Errors;
