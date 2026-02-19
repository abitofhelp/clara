pragma Ada_2022;
--  ===========================================================================
--  SPARK_Static_Test (Body)
--  ===========================================================================
--  Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
--  SPDX-License-Identifier: BSD-3-Clause
--  ===========================================================================

package body SPARK_Static_Test with
  SPARK_Mode => On
is

   function Test_Parse return Boolean is
      Result : constant Test_CLI.Parse_Result.Result :=
        Test_CLI.Parse (Test_Config);
      pragma Unreferenced (Result);
   begin
      return True;
   end Test_Parse;

   function Test_Results_Access return Boolean is
      --  Create a default results record for testing access patterns
      Results : Test_CLI.Parse_Results;

      --  Test flag access
      V1 : constant Boolean := Test_CLI.Is_Set (Results, Verbose);
      V2 : constant Natural := Test_CLI.Flag_Count (Results, Debug);

      --  Test option access
      O1 : constant Boolean := Test_CLI.Has_Option (Results, Output);
      O2 : constant Test_CLI.Option_Value.Option :=
        Test_CLI.Get_Option (Results, Config);
      O3 : constant Clara.Types.Value_String :=
        Test_CLI.Get_Option_Or (Results, Format, "text");

      --  Test positional access
      P1 : constant Boolean := Test_CLI.Has_Positional (Results, Input_File);
      P2 : constant Natural := Test_CLI.Positional_Count (Results, Output_File);
      P3 : constant Test_CLI.Positional_Values :=
        Test_CLI.Get_Positional (Results, Input_File);

      pragma Unreferenced (V1, V2, O1, O2, O3, P1, P2, P3);
   begin
      return True;
   end Test_Results_Access;

end SPARK_Static_Test;
