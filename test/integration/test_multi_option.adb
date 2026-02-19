pragma Ada_2022;
--  ======================================================================
--  Test_Multi_Option - Integration test for repeatable option parsing
--  ======================================================================
--  Copyright (c) 2026 Michael Gardner, A Bit of Help, Inc.
--  SPDX-License-Identifier: BSD-3-Clause
--
--  Usage:
--    test_multi_option --exclude-path=/foo --exclude-path=/bar src/
--    test_multi_option -e /foo -e /bar src/
--    test_multi_option -e/foo -e/bar src/
--    test_multi_option src/   (no excludes)
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

procedure Test_Multi_Option is

   use Ada.Text_IO;
   use Ada.Command_Line;
   use Clara.Types;

   --  Instantiate CLI application
   package CLI is new Clara.Application
     (App_Name        => "test_multi_option",
      App_Description => "Integration test for repeatable options");

   --  Repeatable option (Multiple => True)
   package Exclude is new CLI.Option
     (Short      => 'e',
      Long       => "exclude-path",
      Value_Name => "PATH",
      Help       => "Exclude path (repeatable)",
      Multiple   => True);

   --  Multi-value positional
   package Paths is new CLI.Positional
     (Name     => "PATHS",
      Help     => "Source paths",
      Multiple => True);

   Result : CLI.Parse_Result.Result;

begin
   --  Parse command line
   Result := CLI.Parse;

   if Result.Is_Ok then
      Put_Line ("parsed=true");
      Put_Line ("exclude_count=" & Natural'Image (Exclude.Count));
      Put_Line ("exclude_has=" & Boolean'Image (Exclude.Has_Value));
      Put_Line ("exclude_has_values=" & Boolean'Image (Exclude.Has_Values));

      if Exclude.Count > 0 then
         Put_Line ("exclude_first=" &
                   Value_Strings.To_String (Exclude.First));
      end if;

      --  Print all exclude values
      declare
         V : constant Value_Vector := Exclude.Values;
      begin
         for I in 1 .. V.Count loop
            Put_Line ("exclude_" & Natural'Image (I) & "=" &
                      Value_Strings.To_String (V.Items (I)));
         end loop;
      end;

      Put_Line ("paths_count=" & Natural'Image (Paths.Count));
      if Paths.Count > 0 then
         Put_Line ("paths_first=" &
                   Value_Strings.To_String (Paths.First));
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

end Test_Multi_Option;
