pragma Ada_2022;
--  ======================================================================
--  Test_Parse_Help - Integration test for help/version requests
--  ======================================================================
--  Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
--  SPDX-License-Identifier: BSD-3-Clause
--
--  Usage:
--    test_parse_help -h        # Short help
--    test_parse_help --help    # Long help
--    test_parse_help --version # Version request
--
--  Exit codes:
--    0 - Help/version correctly detected
--    1 - Unexpected result
--  ======================================================================

with Ada.Text_IO;
with Ada.Command_Line;
with Clara.Application;
with Clara.Errors;

procedure Test_Parse_Help is

   use Ada.Text_IO;
   use Ada.Command_Line;
   use Clara.Errors;

   --  Instantiate CLI application
   package CLI is new Clara.Application
     (App_Name        => "test_parse_help",
      App_Description => "Integration test for help/version");

   --  Define some flags/options to populate help output
   package Verbose is new CLI.Flag
     (Short => 'v',
      Long  => "verbose",
      Help  => "Verbose output");

   package Output is new CLI.Option
     (Short      => 'o',
      Long       => "output",
      Value_Name => "FILE",
      Help       => "Output file");

   package Files is new CLI.Positional
     (Name     => "FILES",
      Help     => "Input files",
      Multiple => True);

   Result : CLI.Parse_Result.Result;
   Err    : Clara.Errors.Parse_Error;

begin
   --  Parse command line
   Result := CLI.Parse;

   if Result.Is_Ok then
      Put_Line ("parsed=true");
      Set_Exit_Status (Success);
   else
      Err := CLI.Parse_Result.Error (Result);
      Put_Line ("parsed=false");
      Put_Line ("error_kind=" & Clara.Errors.Error_Kind'Image (Err.Kind));

      if Err.Kind = Clara.Errors.Help_Requested then
         Put_Line ("action=help");
         CLI.Print_Help;
         Set_Exit_Status (Success);

      elsif Err.Kind = Clara.Errors.Version_Requested then
         Put_Line ("action=version");
         CLI.Print_Version;
         Set_Exit_Status (Success);

      else
         Put_Line ("error=" & Clara.Errors.Format (Err));
         Set_Exit_Status (Success);
      end if;
   end if;

end Test_Parse_Help;
