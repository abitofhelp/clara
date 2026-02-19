pragma Ada_2022;
--  ======================================================================
--  Test_Parse_Options - Integration test for option parsing
--  ======================================================================
--  Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
--  SPDX-License-Identifier: BSD-3-Clause
--
--  Usage:
--    test_parse_options -o file.txt           # Short option with value
--    test_parse_options --output=file.txt     # Long option with =
--    test_parse_options --output file.txt     # Long option with space
--    test_parse_options -ofile.txt            # Short option attached value
--
--  Exit codes:
--    0 - All tests passed
--    1 - Test failed
--  ======================================================================

with Ada.Text_IO;
with Ada.Command_Line;
with Clara.Application;
with Clara.Errors;
with Clara.Types;

procedure Test_Parse_Options is

   use Ada.Text_IO;
   use Ada.Command_Line;
   use Clara.Types;

   --  Instantiate CLI application
   package CLI is new Clara.Application
     (App_Name        => "test_parse_options",
      App_Description => "Integration test for option parsing");

   --  Define options
   package Output is new CLI.Option
     (Short      => 'o',
      Long       => "output",
      Value_Name => "FILE",
      Help       => "Output file path");

   package Config is new CLI.Option
     (Short      => 'c',
      Long       => "config",
      Value_Name => "PATH",
      Help       => "Configuration file");

   --  Option without short form
   package Format is new CLI.Option
     (Long       => "format",
      Value_Name => "FMT",
      Help       => "Output format");

   Result : CLI.Parse_Result.Result;

begin
   --  Parse command line
   Result := CLI.Parse;

   if Result.Is_Ok then
      --  Output test results as key=value pairs for verification
      Put_Line ("parsed=true");
      Put_Line ("output_has=" & Boolean'Image (Output.Has_Value));
      if Output.Has_Value then
         Put_Line ("output_value=" & Output.Value_Or (""));
      end if;
      Put_Line ("config_has=" & Boolean'Image (Config.Has_Value));
      if Config.Has_Value then
         Put_Line ("config_value=" & Config.Value_Or (""));
      end if;
      Put_Line ("format_has=" & Boolean'Image (Format.Has_Value));
      if Format.Has_Value then
         Put_Line ("format_value=" & Format.Value_Or (""));
      end if;
      Set_Exit_Status (Success);

   elsif CLI.Parse_Result.Error (Result).Kind in
           Clara.Errors.Help_Requested | Clara.Errors.Version_Requested
   then
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
      Set_Exit_Status (Success);
   end if;

end Test_Parse_Options;
