pragma Ada_2022;
--  ======================================================================
--  Test_Errors - Unit tests for Clara.Errors
--  ======================================================================
--  Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
--  SPDX-License-Identifier: BSD-3-Clause
--  ======================================================================

with Ada.Text_IO;
with Test_Framework;
with Clara.Errors; use Clara.Errors;
with Clara.Types;  use Clara.Types;

procedure Test_Errors is

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
   Put_Line ("=== Clara.Errors Tests ===");
   Put_Line ("");

   --  =========================================================================
   --  Test Make_Error
   --  =========================================================================

   Put_Line ("-- Make_Error --");

   declare
      E : constant Parse_Error :=
        Make_Error (Unknown_Switch, "Test message", "test context");
   begin
      Check ("Make_Error sets Kind", E.Kind = Unknown_Switch);
      Check ("Make_Error sets Message",
             Message_Strings.To_String (E.Message) = "Test message");
      Check ("Make_Error sets Context",
             Value_Strings.To_String (E.Context) = "test context");
   end;

   declare
      E : constant Parse_Error := Make_Error (Internal_Error, "No context");
   begin
      Check ("Make_Error with empty context",
             Value_Strings.Length (E.Context) = 0);
   end;

   --  =========================================================================
   --  Test Error Factory Functions
   --  =========================================================================

   Put_Line ("");
   Put_Line ("-- Error Factory Functions --");

   declare
      E : constant Parse_Error := Unknown_Switch_Error ("--unknown");
   begin
      Check ("Unknown_Switch_Error Kind", E.Kind = Unknown_Switch);
      Check ("Unknown_Switch_Error Context",
             Value_Strings.To_String (E.Context) = "--unknown");
   end;

   declare
      E : constant Parse_Error := Missing_Value_Error ("--output");
   begin
      Check ("Missing_Value_Error Kind", E.Kind = Missing_Value);
      Check ("Missing_Value_Error Context",
             Value_Strings.To_String (E.Context) = "--output");
   end;

   declare
      E : constant Parse_Error := Missing_Required_Error ("config");
   begin
      Check ("Missing_Required_Error Kind", E.Kind = Missing_Required);
      Check ("Missing_Required_Error Context",
             Value_Strings.To_String (E.Context) = "config");
   end;

   declare
      E : constant Parse_Error := Too_Many_Values_Error (10);
   begin
      Check ("Too_Many_Values_Error Kind", E.Kind = Too_Many_Values);
   end;

   declare
      E : constant Parse_Error := Help_Requested_Error;
   begin
      Check ("Help_Requested_Error Kind", E.Kind = Help_Requested);
   end;

   declare
      E : constant Parse_Error := Version_Requested_Error;
   begin
      Check ("Version_Requested_Error Kind", E.Kind = Version_Requested);
   end;

   --  =========================================================================
   --  Test Error Predicates
   --  =========================================================================

   Put_Line ("");
   Put_Line ("-- Error Predicates --");

   Check ("Help is graceful exit",
          Is_Graceful_Exit (Help_Requested_Error));
   Check ("Version is graceful exit",
          Is_Graceful_Exit (Version_Requested_Error));
   Check ("Unknown_Switch is not graceful exit",
          not Is_Graceful_Exit (Unknown_Switch_Error ("x")));

   Check ("Unknown_Switch is user error",
          Is_User_Error (Unknown_Switch_Error ("x")));
   Check ("Missing_Value is user error",
          Is_User_Error (Missing_Value_Error ("x")));
   Check ("Help is not user error",
          not Is_User_Error (Help_Requested_Error));

   --  =========================================================================
   --  Test Format
   --  =========================================================================

   Put_Line ("");
   Put_Line ("-- Format --");

   declare
      E : constant Parse_Error :=
        (Kind    => None,
         Message => Message_Strings.Null_Bounded_String,
         Context => Value_Strings.Null_Bounded_String);
   begin
      Check ("Format None returns empty", Format (E) = "");
   end;

   declare
      E : constant Parse_Error := Unknown_Switch_Error ("--bad");
   begin
      Check ("Format with context includes colon",
             Format (E) = "Unknown switch: --bad");
   end;

   declare
      E : constant Parse_Error := Make_Error (Internal_Error, "Internal fail");
   begin
      Check ("Format without context excludes colon",
             Format (E) = "Internal fail");
   end;

   --  =========================================================================
   --  Summary
   --  =========================================================================

   Put_Line ("");
   Put_Line ("Clara.Errors: " & Passed'Image & " /" & Total'Image & " passed");

   Test_Framework.Register_Results (Total, Passed);

end Test_Errors;
