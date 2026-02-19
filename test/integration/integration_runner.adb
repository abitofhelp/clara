pragma Ada_2022;
--  ======================================================================
--  Integration_Runner - Integration test runner for Clara
--  ======================================================================
--  Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
--  SPDX-License-Identifier: BSD-3-Clause
--
--  Purpose:
--    Runs integration test executables with specific command lines
--    and verifies the expected output/behavior via exit codes.
--  ======================================================================

with Ada.Text_IO;
with Ada.Command_Line;
with Ada.Directories;
with GNAT.OS_Lib;
with Test_Framework;

procedure Integration_Runner is

   use Ada.Text_IO;
   use Ada.Command_Line;

   --  Get the directory containing test executables.
   --  Works when run from project root: ./test/bin/integration_runner
   --  or via make: make test-integration
   Bin_Dir : constant String :=
     Ada.Directories.Current_Directory & "/test/bin/";

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

   --  Run a test executable with given arguments and check exit code.
   --  Returns True if the test executed successfully (exit code 0).
   function Run_Test
     (Executable : String;
      Arguments  : String := "") return Boolean
   is
      Full_Path   : constant String := Bin_Dir & Executable;
      Return_Code : Integer;
      Args        : GNAT.OS_Lib.Argument_List_Access;
   begin
      if not Ada.Directories.Exists (Full_Path) then
         Put_Line ("    (executable not found: " & Full_Path & ")");
         return False;
      end if;

      --  Parse arguments string into argument list
      if Arguments'Length > 0 then
         Args := GNAT.OS_Lib.Argument_String_To_List (Arguments);
      else
         Args := new GNAT.OS_Lib.Argument_List (1 .. 0);
      end if;

      --  Use Spawn that returns actual exit code
      Return_Code := GNAT.OS_Lib.Spawn
        (Program_Name => Full_Path,
         Args         => Args.all);

      --  Free allocated argument list
      GNAT.OS_Lib.Free (Args);

      --  Return true if exit code is 0 (success)
      return Return_Code = 0;
   end Run_Test;

begin
   Put_Line ("");
   Put_Line ("========================================");
   Put_Line ("     CLARA INTEGRATION TEST SUITE");
   Put_Line ("========================================");
   Put_Line ("");

   --  Reset test framework
   Test_Framework.Reset;

   --  =========================================================================
   --  Flag Parsing Tests
   --  =========================================================================

   Put_Line ("=== Flag Parsing Tests ===");
   Put_Line ("");

   Check ("test_parse_flags -v",
          Run_Test ("test_parse_flags", "-v"));

   Check ("test_parse_flags --verbose",
          Run_Test ("test_parse_flags", "--verbose"));

   Check ("test_parse_flags -v -d",
          Run_Test ("test_parse_flags", "-v -d"));

   Check ("test_parse_flags --help (triggers help branch)",
          Run_Test ("test_parse_flags", "--help"));

   --  =========================================================================
   --  Option Parsing Tests
   --  =========================================================================

   Put_Line ("");
   Put_Line ("=== Option Parsing Tests ===");
   Put_Line ("");

   Check ("test_parse_options -o file.txt",
          Run_Test ("test_parse_options", "-o file.txt"));

   Check ("test_parse_options --output=result.txt",
          Run_Test ("test_parse_options", "--output=result.txt"));

   Check ("test_parse_options --config=app.cfg",
          Run_Test ("test_parse_options", "--config=app.cfg"));

   Check ("test_parse_options --format=json",
          Run_Test ("test_parse_options", "--format=json"));

   Check ("test_parse_options --help (triggers help branch)",
          Run_Test ("test_parse_options", "--help"));

   Check ("test_option_value --output=test",
          Run_Test ("test_option_value", "--output=test"));

   --  =========================================================================
   --  Positional Argument Tests
   --  =========================================================================

   Put_Line ("");
   Put_Line ("=== Positional Argument Tests ===");
   Put_Line ("");

   Check ("test_parse_positionals f1.txt f2.txt",
          Run_Test ("test_parse_positionals", "f1.txt f2.txt"));

   Check ("test_parse_positionals --help (triggers help branch)",
          Run_Test ("test_parse_positionals", "--help"));

   Check ("test_multi_positional a b c",
          Run_Test ("test_multi_positional", "a b c"));

   Check ("test_multi_positional --help (triggers help branch)",
          Run_Test ("test_multi_positional", "--help"));

   Check ("test_no_positional (no args)",
          Run_Test ("test_no_positional"));

   Check ("test_no_positional --help (triggers help branch)",
          Run_Test ("test_no_positional", "--help"));

   Check ("test_positional_as_switch --file test.txt",
          Run_Test ("test_positional_as_switch", "--file test.txt"));

   Check ("test_positional_as_switch --help (triggers help branch)",
          Run_Test ("test_positional_as_switch", "--help"));

   --  =========================================================================
   --  Help and Error Tests
   --  =========================================================================

   Put_Line ("");
   Put_Line ("=== Help and Error Tests ===");
   Put_Line ("");

   Check ("test_parse_help --help",
          Run_Test ("test_parse_help", "--help"));

   Check ("test_parse_help -h",
          Run_Test ("test_parse_help", "-h"));

   Check ("test_parse_help --version (triggers version branch)",
          Run_Test ("test_parse_help", "--version"));

   Check ("test_parse_help (no flags - success path)",
          Run_Test ("test_parse_help"));

   Check ("test_parse_errors --unknown",
          Run_Test ("test_parse_errors", "--unknown"));

   --  =========================================================================
   --  Additional Coverage Tests - trigger error branches in test files
   --  =========================================================================

   Put_Line ("");
   Put_Line ("=== Additional Coverage Tests ===");
   Put_Line ("");

   --  Trigger error branches by passing unknown flags
   Check ("test_parse_flags --unknown (triggers error branch)",
          Run_Test ("test_parse_flags", "--unknown"));

   Check ("test_parse_options --unknown (triggers error branch)",
          Run_Test ("test_parse_options", "--unknown"));

   Check ("test_option_value --help (triggers help branch)",
          Run_Test ("test_option_value", "--help"));

   Check ("test_parse_positionals --unknown (triggers error branch)",
          Run_Test ("test_parse_positionals", "--unknown"));

   Check ("test_parse_help --unknown (triggers error branch)",
          Run_Test ("test_parse_help", "--unknown"));

   --  Run with single positional to exercise Files.Has_Values path
   Check ("test_parse_positionals single.txt",
          Run_Test ("test_parse_positionals", "single.txt"));

   --  =========================================================================
   --  Subcommand Tests
   --  =========================================================================

   Put_Line ("");
   Put_Line ("=== Subcommand Tests ===");
   Put_Line ("");

   --  Basic command detection
   Check ("test_parse_commands write src/",
          Run_Test ("test_parse_commands", "write src/"));

   Check ("test_parse_commands check src/",
          Run_Test ("test_parse_commands", "check src/"));

   Check ("test_parse_commands dry-run src/",
          Run_Test ("test_parse_commands", "dry-run src/"));

   --  Command with scoped flag
   Check ("test_parse_commands write -y src/",
          Run_Test ("test_parse_commands", "write -y src/"));

   --  Command with scoped option (= syntax)
   Check ("test_parse_commands write -b /backup src/",
          Run_Test ("test_parse_commands", "write -b /backup src/"));

   --  Global option before command
   Check ("test_parse_commands -j 4 write src/",
          Run_Test ("test_parse_commands", "-j 4 write src/"));

   --  Global option with = (long form) before command
   Check ("test_parse_commands --workers=4 write src/",
          Run_Test ("test_parse_commands", "--workers=4 write src/"));

   --  Global flag + command
   Check ("test_parse_commands -v write src/",
          Run_Test ("test_parse_commands", "-v write src/"));

   --  Help without command
   Check ("test_parse_commands --help",
          Run_Test ("test_parse_commands", "--help"));

   --  Help with command (Show_Help callback is called)
   Check ("test_parse_commands write --help",
          Run_Test ("test_parse_commands", "write --help"));

   --  Wrong-command flag: -y is write-only, used with check
   Check ("test_parse_commands check -y (command mismatch)",
          Run_Test ("test_parse_commands", "check -y"));

   --  Scoped flag without any command
   Check ("test_parse_commands -y src/ (no command, scoped flag)",
          Run_Test ("test_parse_commands", "-y src/"));

   --  Long scoped option with wrong command
   Check ("test_parse_commands check --yes (command mismatch long)",
          Run_Test ("test_parse_commands", "check --yes"));

   --  No command, just positionals (global flags only)
   Check ("test_parse_commands -v src/",
          Run_Test ("test_parse_commands", "-v src/"));

   --  =========================================================================
   --  Multi-Value Option Tests
   --  =========================================================================

   Put_Line ("");
   Put_Line ("=== Multi-Value Option Tests ===");
   Put_Line ("");

   --  Single repeatable option + positional
   Check ("test_multi_option --exclude-path=/foo src/",
          Run_Test ("test_multi_option", "--exclude-path=/foo src/"));

   --  Two repeatable options (long form)
   Check ("test_multi_option --exclude-path=/foo --exclude-path=/bar src/",
          Run_Test ("test_multi_option",
                    "--exclude-path=/foo --exclude-path=/bar src/"));

   --  Two repeatable options (short form with space)
   Check ("test_multi_option -e /foo -e /bar src/",
          Run_Test ("test_multi_option", "-e /foo -e /bar src/"));

   --  Two repeatable options (short form attached)
   Check ("test_multi_option -e/foo -e/bar src/",
          Run_Test ("test_multi_option", "-e/foo -e/bar src/"));

   --  No excludes, just positional
   Check ("test_multi_option src/ (no excludes)",
          Run_Test ("test_multi_option", "src/"));

   --  Help triggers help exit
   Check ("test_multi_option --help",
          Run_Test ("test_multi_option", "--help"));

   --  =========================================================================
   --  Summary
   --  =========================================================================

   Test_Framework.Register_Results (Total, Passed);

   Put_Line ("");
   Put_Line ("========================================");
   Put_Line ("        INTEGRATION TESTS COMPLETE");
   Put_Line ("========================================");
   Put_Line ("Total tests:  " & Total'Image);
   Put_Line ("Passed:       " & Passed'Image);
   Put_Line ("Failed:       " & Natural'Image (Total - Passed));

   declare
      Exit_Code : constant Integer :=
        Test_Framework.Print_Category_Summary
          ("INTEGRATION TESTS", Total, Passed);
   begin
      Set_Exit_Status (if Exit_Code = 0 then Success else Failure);
   end;

end Integration_Runner;
