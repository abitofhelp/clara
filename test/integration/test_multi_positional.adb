pragma Ada_2022;
--  ======================================================================
--  Test_Multi_Positional - Test multiple non-Multiple positionals
--  ======================================================================
--  Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
--  SPDX-License-Identifier: BSD-3-Clause
--
--  Usage:
--    test_multi_positional input.txt output.txt  # Two positionals
--
--  This exercises lines 357-360: Finding next positional after consuming one
--
--  Exit codes:
--    0 - Test passed
--    1 - Test failed
--  ======================================================================

with Ada.Text_IO;
with Ada.Command_Line;
with Clara.Application;
with Clara.Types;

procedure Test_Multi_Positional is

   use Ada.Text_IO;
   use Ada.Command_Line;

   --  Instantiate CLI application
   package CLI is new Clara.Application
     (App_Name        => "test_multi_positional",
      App_Description => "Integration test for multiple positionals");

   --  Define two non-Multiple positionals
   package Input_File is new CLI.Positional
     (Name => "input",
      Help => "Input file");

   package Output_File is new CLI.Positional
     (Name => "output",
      Help => "Output file");

   Result : CLI.Parse_Result.Result;

begin
   --  Parse command line
   Result := CLI.Parse;

   if Result.Is_Ok then
      Put_Line ("parsed=true");
      Put_Line ("input_count=" & Natural'Image (Input_File.Count));
      Put_Line ("output_count=" & Natural'Image (Output_File.Count));
      if Input_File.Count > 0 then
         Put_Line ("input_value=" &
                   Clara.Types.Value_Strings.To_String (Input_File.First));
      end if;
      if Output_File.Count > 0 then
         Put_Line ("output_value=" &
                   Clara.Types.Value_Strings.To_String (Output_File.First));
      end if;
      Set_Exit_Status (Success);
   else
      Put_Line ("parsed=false");
      Set_Exit_Status (Failure);
   end if;

end Test_Multi_Positional;
