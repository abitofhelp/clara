pragma Ada_2022;
--  ======================================================================
--  Test_Option_Value - Integration test for Option.Value() returning Some
--  ======================================================================
--  Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
--  SPDX-License-Identifier: BSD-3-Clause
--
--  Usage:
--    test_option_value -o file.txt   # Tests Value() returning Some
--
--  Exit codes:
--    0 - Test passed
--    1 - Test failed
--  ======================================================================

with Ada.Text_IO;
with Ada.Command_Line;
with Clara.Application;
with Clara.Errors;
with Clara.Types;

procedure Test_Option_Value is

   use Ada.Text_IO;
   use Ada.Command_Line;

   --  Instantiate CLI application
   package CLI is new Clara.Application
     (App_Name        => "test_option_value",
      App_Description => "Integration test for Option.Value()");

   --  Define option to test Value() function
   package Output is new CLI.Option
     (Short      => 'o',
      Long       => "output",
      Value_Name => "FILE",
      Help       => "Output file path");

   Result : CLI.Parse_Result.Result;

begin
   --  Parse command line
   Result := CLI.Parse;

   if Result.Is_Ok then
      Put_Line ("parsed=true");
      Put_Line ("has_value=" & Boolean'Image (Output.Has_Value));

      --  This exercises Option.Value returning Some
      declare
         Val_Opt : constant Output.String_Option.Option := Output.Value;
      begin
         Put_Line ("is_some=" &
                   Boolean'Image (Output.String_Option.Is_Some (Val_Opt)));
         if Output.String_Option.Is_Some (Val_Opt) then
            Put_Line ("value=" &
                      Clara.Types.Value_Strings.To_String
                        (Output.String_Option.Value (Val_Opt)));
         end if;
      end;

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

end Test_Option_Value;
