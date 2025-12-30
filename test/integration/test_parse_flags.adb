pragma Ada_2022;
--  ======================================================================
--  Test_Parse_Flags - Integration test for flag parsing
--  ======================================================================
--  Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
--  SPDX-License-Identifier: BSD-3-Clause
--
--  Usage:
--    test_parse_flags -v              # Test single flag
--    test_parse_flags -v -v -v        # Test flag counting
--    test_parse_flags --verbose       # Test long flag
--    test_parse_flags -vd             # Test combined short flags
--
--  Exit codes:
--    0 - All tests passed
--    1 - Test failed
--  ======================================================================

with Ada.Text_IO;
with Ada.Command_Line;
with Clara.Application;
with Clara.Errors;

procedure Test_Parse_Flags is

   use Ada.Text_IO;
   use Ada.Command_Line;

   --  Instantiate CLI application
   package CLI is new Clara.Application
     (App_Name        => "test_parse_flags",
      App_Description => "Integration test for flag parsing");

   --  Define flags
   package Verbose is new CLI.Flag
     (Short => 'v',
      Long  => "verbose",
      Help  => "Enable verbose output");

   package Debug is new CLI.Flag
     (Short => 'd',
      Long  => "debug",
      Help  => "Enable debug mode");

   --  Flag without short form
   package Quiet is new CLI.Flag
     (Long  => "quiet",
      Help  => "Suppress output");

   --  Dummy required option to avoid "required option missing" error
   package Config is new CLI.Option
     (Long       => "config",
      Value_Name => "PATH",
      Help       => "Config file");

   Result : CLI.Parse_Result.Result;

begin
   --  Parse command line
   Result := CLI.Parse;

   if Result.Is_Ok then
      --  Output test results as key=value pairs for verification
      Put_Line ("parsed=true");
      Put_Line ("verbose_set=" & Boolean'Image (Verbose.Is_Set));
      Put_Line ("verbose_count=" & Natural'Image (Verbose.Count));
      Put_Line ("debug_set=" & Boolean'Image (Debug.Is_Set));
      Put_Line ("debug_count=" & Natural'Image (Debug.Count));
      Put_Line ("quiet_set=" & Boolean'Image (Quiet.Is_Set));
      Set_Exit_Status (Success);

   elsif CLI.Parse_Result.Error (Result).Kind in
           Clara.Errors.Help_Requested | Clara.Errors.Version_Requested
   then
      --  These are expected behaviors for specific tests
      Put_Line ("parsed=false");
      Put_Line ("error_kind=" &
                Clara.Errors.Error_Kind'Image
                  (CLI.Parse_Result.Error (Result).Kind));
      Set_Exit_Status (Success);

   else
      Put_Line ("parsed=false");
      Put_Line ("error_kind=" &
                Clara.Errors.Error_Kind'Image
                  (CLI.Parse_Result.Error (Result).Kind));
      Put_Line ("error=" &
                Clara.Errors.Format (CLI.Parse_Result.Error (Result)));
      Set_Exit_Status (Failure);
   end if;

end Test_Parse_Flags;
