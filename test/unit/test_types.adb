pragma Ada_2022;
--  ======================================================================
--  Test_Types - Unit tests for Clara.Types
--  ======================================================================
--  Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
--  SPDX-License-Identifier: BSD-3-Clause
--  ======================================================================

with Ada.Text_IO;
with Test_Framework;
with Clara.Types; use Clara.Types;

procedure Test_Types is

   use Ada.Text_IO;

   Total  : Natural := 0;
   Passed : Natural := 0;

   procedure Check (Name : String; Condition : Boolean) is
   begin
      Total := Total + 1;
      if Condition then
         Passed := Passed + 1;
         Put_Line ("  PASS: " & Name);
      else
         Put_Line ("  FAIL: " & Name);
      end if;
   end Check;

begin
   Put_Line ("");
   Put_Line ("=== Clara.Types Tests ===");
   Put_Line ("");

   --  =========================================================================
   --  Test Bounded String Conversions
   --  =========================================================================

   Put_Line ("-- Bounded String Conversions --");

   declare
      NS : constant Name_String := To_Name ("myapp");
   begin
      Check ("To_Name creates bounded string",
             Name_Strings.To_String (NS) = "myapp");
      Check ("To_Name length correct",
             Name_Strings.Length (NS) = 5);
   end;

   declare
      LS : constant Long_Switch_String := To_Long_Switch ("verbose");
   begin
      Check ("To_Long_Switch creates bounded string",
             Long_Switch_Strings.To_String (LS) = "verbose");
   end;

   declare
      VN : constant Value_Name_String := To_Value_Name ("FILE");
   begin
      Check ("To_Value_Name creates bounded string",
             Value_Name_Strings.To_String (VN) = "FILE");
   end;

   declare
      HS : constant Help_String := To_Help ("Enable verbose output");
   begin
      Check ("To_Help creates bounded string",
             Help_Strings.To_String (HS) = "Enable verbose output");
   end;

   declare
      VS : constant Value_String := To_Value ("/path/to/file");
   begin
      Check ("To_Value creates bounded string",
             Value_Strings.To_String (VS) = "/path/to/file");
   end;

   declare
      MS : constant Message_String := To_Message ("Error occurred");
   begin
      Check ("To_Message creates bounded string",
             Message_Strings.To_String (MS) = "Error occurred");
   end;

   --  =========================================================================
   --  Test Length Constants
   --  =========================================================================

   Put_Line ("");
   Put_Line ("-- Length Constants --");

   pragma Warnings (Off, "condition is always*");
   Check ("Max_Name_Length is 32", Max_Name_Length = 32);
   Check ("Max_Long_Switch_Length is 64", Max_Long_Switch_Length = 64);
   Check ("Max_Value_Name_Length is 16", Max_Value_Name_Length = 16);
   Check ("Max_Help_Length is 256", Max_Help_Length = 256);
   Check ("Max_Value_Length is 4096", Max_Value_Length = 4096);
   Check ("Max_Message_Length is 512", Max_Message_Length = 512);
   Check ("Max_Arguments is 256", Max_Arguments = 256);
   Check ("Max_Positional_Values is 4096", Max_Positional_Values = 4096);
   pragma Warnings (On, "condition is always*");

   --  =========================================================================
   --  Test Value_Vector
   --  =========================================================================

   Put_Line ("");
   Put_Line ("-- Value_Vector --");

   declare
      V : Value_Vector (10);
   begin
      Check ("New vector is empty", Is_Empty (V));
      Check ("New vector length is 0", Length (V) = 0);
      Check ("New vector is not full", not Is_Full (V));

      V.Count := 1;
      V.Items (1) := To_Value ("first");

      Check ("After add, not empty", not Is_Empty (V));
      Check ("After add, length is 1", Length (V) = 1);
      Check ("After add, still not full", not Is_Full (V));

      V.Count := 10;
      Check ("At capacity, is full", Is_Full (V));
   end;

   --  =========================================================================
   --  Test Argument_Kind
   --  =========================================================================

   Put_Line ("");
   Put_Line ("-- Argument_Kind --");

   declare
      FK : constant Argument_Kind := Flag_Argument;
      OK : constant Argument_Kind := Option_Argument;
      PK : constant Argument_Kind := Positional_Argument;
   begin
      pragma Warnings (Off, "condition is always*");
      Check ("Flag_Argument exists", FK = Flag_Argument);
      Check ("Option_Argument exists", OK = Option_Argument);
      Check ("Positional_Argument exists", PK = Positional_Argument);
      Check ("Kinds are distinct", FK /= OK and OK /= PK and FK /= PK);
      pragma Warnings (On, "condition is always*");
   end;

   --  =========================================================================
   --  Summary
   --  =========================================================================

   Put_Line ("");
   Put_Line ("Clara.Types: " & Passed'Image & " /" & Total'Image & " passed");

   Test_Framework.Register_Results (Total, Passed);

end Test_Types;
