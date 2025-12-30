pragma Ada_2022;
--  ======================================================================
--  Test_Application - Unit tests for Clara.Application
--  ======================================================================
--  Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
--  SPDX-License-Identifier: BSD-3-Clause
--  ======================================================================

with Ada.Text_IO;
with Test_Framework;
with Clara.Application;
with Clara.Types; use Clara.Types;

procedure Test_Application is

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

   --  =========================================================================
   --  Instantiate the CLI Application Generic
   --  =========================================================================
   --  This exercises:
   --    - Generic instantiation
   --    - Package state initialization (Arguments, Registered_Count, etc.)
   --    - Result type instantiation (Parse_Result)

   package Test_CLI is new Clara.Application
     (App_Name        => "test_app",
      App_Description => "Test application for unit testing");

   --  =========================================================================
   --  Instantiate Flag Child Generic
   --  =========================================================================
   --  This exercises:
   --    - Flag generic instantiation
   --    - Register_Flag procedure (called at elaboration)
   --    - Flag state initialization (Is_Flag_Set, Flag_Counter)

   package Verbose_Flag is new Test_CLI.Flag
     (Short => 'v',
      Long  => "verbose",
      Help  => "Enable verbose output");

   package Debug_Flag is new Test_CLI.Flag
     (Short => 'd',
      Long  => "debug",
      Help  => "Enable debug mode");

   --  Flag without short form
   package Quiet_Flag is new Test_CLI.Flag
     (Long  => "quiet",
      Help  => "Suppress output");

   --  =========================================================================
   --  Instantiate Option Child Generic
   --  =========================================================================
   --  This exercises:
   --    - Option generic instantiation
   --    - Register_Option procedure (called at elaboration)
   --    - Option state initialization (Has_Val, Stored_Val)
   --    - String_Option instantiation

   package Output_Option is new Test_CLI.Option
     (Short      => 'o',
      Long       => "output",
      Value_Name => "FILE",
      Help       => "Output file path");

   package Config_Option is new Test_CLI.Option
     (Long       => "config",
      Value_Name => "PATH",
      Help       => "Configuration file",
      Required   => True);

   --  =========================================================================
   --  Instantiate Positional Child Generic
   --  =========================================================================
   --  This exercises:
   --    - Positional generic instantiation
   --    - Register_Positional procedure (called at elaboration)
   --    - Positional state initialization (Stored_Values)

   package Input_Files is new Test_CLI.Positional
     (Name     => "FILES",
      Help     => "Input files to process",
      Multiple => True);

   package Single_File is new Test_CLI.Positional
     (Name     => "FILE",
      Help     => "Single input file");

begin
   Put_Line ("");
   Put_Line ("=== Clara.Application Tests ===");
   Put_Line ("");

   --  =========================================================================
   --  Test Initial State (Before Parse)
   --  =========================================================================

   Put_Line ("-- Initial State Before Parse --");

   Check ("Is_Parsed returns False before Parse",
          not Test_CLI.Is_Parsed);

   --  =========================================================================
   --  Test Flag Initial State
   --  =========================================================================

   Put_Line ("");
   Put_Line ("-- Flag Initial State --");

   Check ("Verbose_Flag.Is_Set returns False initially",
          not Verbose_Flag.Is_Set);

   Check ("Verbose_Flag.Count returns 0 initially",
          Verbose_Flag.Count = 0);

   Check ("Debug_Flag.Is_Set returns False initially",
          not Debug_Flag.Is_Set);

   Check ("Quiet_Flag.Is_Set returns False initially",
          not Quiet_Flag.Is_Set);

   --  =========================================================================
   --  Test Option Initial State
   --  =========================================================================

   Put_Line ("");
   Put_Line ("-- Option Initial State --");

   Check ("Output_Option.Has_Value returns False initially",
          not Output_Option.Has_Value);

   Check ("Output_Option.Value returns None initially",
          Output_Option.String_Option.Is_None (Output_Option.Value));

   Check ("Output_Option.Value_Or returns default",
          Output_Option.Value_Or ("default.txt") = "default.txt");

   Check ("Config_Option.Has_Value returns False initially",
          not Config_Option.Has_Value);

   --  =========================================================================
   --  Test Positional Initial State
   --  =========================================================================

   Put_Line ("");
   Put_Line ("-- Positional Initial State --");

   Check ("Input_Files.Has_Values returns False initially",
          not Input_Files.Has_Values);

   Check ("Input_Files.Count returns 0 initially",
          Input_Files.Count = 0);

   declare
      V : constant Value_Vector := Input_Files.Values;
   begin
      Check ("Input_Files.Values returns empty vector",
             V.Count = 0);
   end;

   Check ("Single_File.Has_Values returns False initially",
          not Single_File.Has_Values);

   --  =========================================================================
   --  Test Print_Help (exercises help formatting code)
   --  =========================================================================

   Put_Line ("");
   Put_Line ("-- Print_Help --");
   Put_Line ("  (Output follows:)");
   Put_Line ("  ---");

   Test_CLI.Print_Help;

   Put_Line ("  ---");
   Check ("Print_Help executes without error", True);

   --  =========================================================================
   --  Test Print_Version (exercises version output code)
   --  =========================================================================

   Put_Line ("");
   Put_Line ("-- Print_Version --");
   Put_Line ("  (Output follows:)");
   Put_Line ("  ---");

   Test_CLI.Print_Version;

   Put_Line ("  ---");
   Check ("Print_Version executes without error", True);

   --  =========================================================================
   --  Test Parse Result Type
   --  =========================================================================

   Put_Line ("");
   Put_Line ("-- Parse_Result Type --");

   declare
      Ok_Result : constant Test_CLI.Parse_Result.Result :=
        Test_CLI.Parse_Result.Ok ((null record));
   begin
      Check ("Parse_Result.Ok creates success result",
             Ok_Result.Is_Ok);
   end;

   --  =========================================================================
   --  Summary
   --  =========================================================================

   Put_Line ("");
   Put_Line ("Clara.Application: " & Passed'Image & " /" & Total'Image &
             " passed");

   Test_Framework.Register_Results (Total, Passed);

end Test_Application;
