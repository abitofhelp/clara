pragma Ada_2022;
--  ======================================================================
--  Test_Parse_Positionals - Integration test for positional arguments
--  ======================================================================
--  Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
--  SPDX-License-Identifier: BSD-3-Clause
--
--  Usage:
--    test_parse_positionals file1.txt file2.txt    # Multiple positionals
--    test_parse_positionals -- --not-a-flag        # After "--"
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

procedure Test_Parse_Positionals is

   use Ada.Text_IO;
   use Ada.Command_Line;
   use Clara.Types;

   --  Instantiate CLI application
   package CLI is new Clara.Application
     (App_Name        => "test_parse_positionals",
      App_Description => "Integration test for positional arguments");

   --  Define flags to test interleaving
   package Verbose is new CLI.Flag
     (Short => 'v',
      Long  => "verbose",
      Help  => "Verbose output");

   --  Define positional that accepts multiple values
   package Files is new CLI.Positional
     (Name     => "FILES",
      Help     => "Input files to process",
      Multiple => True);

   Result : CLI.Parse_Result.Result;

begin
   --  Parse command line
   Result := CLI.Parse;

   if Result.Is_Ok then
      --  Output test results as key=value pairs for verification
      Put_Line ("parsed=true");
      Put_Line ("files_has=" & Boolean'Image (Files.Has_Values));
      Put_Line ("files_count=" & Natural'Image (Files.Count));

      if Files.Has_Values then
         Put_Line ("files_first=" &
                   Value_Strings.To_String (Files.First));
         declare
            V : constant Value_Vector := Files.Values;
         begin
            for I in 1 .. V.Count loop
               Put_Line ("files[" & I'Image & "]=" &
                         Value_Strings.To_String (V.Items (I)));
            end loop;
         end;
      end if;

      Put_Line ("verbose_set=" & Boolean'Image (Verbose.Is_Set));
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
      Set_Exit_Status (Failure);
   end if;

end Test_Parse_Positionals;
