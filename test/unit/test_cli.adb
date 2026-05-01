pragma Ada_2022;

with Ada.Text_IO;           use Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Clara.Types;           use Clara.Types;
with Clara.Errors;          use Clara.Errors;
with Clara.CLI;

package body Test_CLI is

   Total_Count  : Natural := 0;
   Passed_Count : Natural := 0;

   procedure Assert (Condition : Boolean; Name : String) is
   begin
      Total_Count := Total_Count + 1;
      if Condition then
         Passed_Count := Passed_Count + 1;
         Put_Line ("  [PASS] " & Name);
      else
         Put_Line ("  [FAIL] " & Name);
      end if;
   end Assert;

   --  ======================================================================
   --  Test CLI with commands, flags, options, positionals
   --  ======================================================================

   type Test_Cmd is (Write, Check, Dry_Run);
   type Test_Flag is (Yes, Verbose);
   type Test_Opt is (Workers, Output, Config, Exclude);
   type Test_Pos is (Paths);

   package CLI is new Clara.CLI
     (Command_Id      => Test_Cmd,
      Flag_Id         => Test_Flag,
      Option_Id       => Test_Opt,
      Positional_Id   => Test_Pos,
      App_Name        => "testapp",
      App_Description => "Test application");

   Test_Config : constant CLI.CLI_Config :=
     (Commands =>
        [Write   => CLI.Cmd ("write", "Format in place"),
         Check   => CLI.Cmd ("check", "Verify compliance"),
         Dry_Run => CLI.Cmd ("dry-run", "Preview changes")],
      Flags =>
        [Yes     => CLI.Flag ('y', "yes", "Skip confirm",
                              Scope => Write),
         Verbose => CLI.Flag ('v', "verbose", "Verbose output")],
      Options =>
        [Workers => CLI.Opt ('j', "workers", "N", "Worker count"),
         Output  => CLI.Opt ('o', "output", "FILE", "Output file"),
         Config  => CLI.Opt (Long => "config", Value_Name => "PATH",
                             Help => "Config file", Required => True),
         Exclude => CLI.Opt (Long => "exclude", Value_Name => "GLOB",
                             Help => "Exclude pattern",
                             Multiple => True)],
      Positionals =>
        [Paths => CLI.Pos ("PATHS", "Source paths", Multiple => True)]);

   function A (S : String) return Value_String
     renames To_Unbounded_String;

   --  ======================================================================
   --  Test CLI without commands (single-command app)
   --  ======================================================================

   type No_Cmd is (Default_Cmd);
   type Simple_Flag is (Verbose);
   type Simple_Opt is (Output);
   type Simple_Pos is (Input_File);

   package Simple_CLI is new Clara.CLI
     (Command_Id      => No_Cmd,
      Flag_Id         => Simple_Flag,
      Option_Id       => Simple_Opt,
      Positional_Id   => Simple_Pos,
      App_Name        => "simple",
      App_Description => "Simple app");

   Simple_Config : constant Simple_CLI.CLI_Config :=
     (Commands =>
        [Default_Cmd => Simple_CLI.Cmd ("default")],
      Flags =>
        [Verbose => Simple_CLI.Flag ('v', "verbose", "Verbose")],
      Options =>
        [Output => Simple_CLI.Opt ('o', "output", "FILE", "Output")],
      Positionals =>
        [Input_File =>
           Simple_CLI.Pos ("FILE", "Input file")]);

   --  ======================================================================
   --  Tests
   --  ======================================================================

   procedure Run (Total : out Natural; Passed : out Natural) is
   begin
      Total_Count := 0;
      Passed_Count := 0;
      Put_Line ("--- Test_CLI ---");

      --  ===== Empty args =====
      declare
         Empty : constant CLI.Argument_Array (1 .. 0) :=
           [others => Null_Unbounded_String];
         R : constant CLI.Parse_Outcome.Result :=
           CLI.Parse (Test_Config, Empty);
      begin
         --  Required option "config" is global, should fail
         Assert (not R.Is_Ok, "Empty args fails (missing required)");
         if not R.Is_Ok then
            Assert
              (R.Error_Value.Kind = Missing_Required,
               "Empty args: Missing_Required error");
         end if;
      end;

      --  ===== Command detection =====
      declare
         Args : constant CLI.Argument_Array :=
           [A ("write"), A ("--config=test.toml")];
         R : constant CLI.Parse_Outcome.Result :=
           CLI.Parse (Test_Config, Args);
      begin
         Assert (R.Is_Ok, "Command 'write' parsed ok");
         if R.Is_Ok then
            Assert
              (R.Ok_Value.Has_Active_Command,
               "Has_Active_Command is True");
            Assert
              (R.Ok_Value.Active_Cmd = Write,
               "Active_Cmd is Write");
            Assert
              (CLI.Is_Active (R.Ok_Value, Write),
               "Write Is_Active");
            Assert
              (not CLI.Is_Active (R.Ok_Value, Check),
               "Check is not active");
         end if;
      end;

      --  ===== Hyphenated command =====
      declare
         Args : constant CLI.Argument_Array :=
           [A ("dry-run"), A ("--config=test.toml")];
         R : constant CLI.Parse_Outcome.Result :=
           CLI.Parse (Test_Config, Args);
      begin
         Assert (R.Is_Ok, "Command 'dry-run' parsed ok");
         if R.Is_Ok then
            Assert
              (CLI.Is_Active (R.Ok_Value, Dry_Run),
               "Dry_Run Is_Active");
         end if;
      end;

      --  ===== Global flag (long) =====
      declare
         Args : constant CLI.Argument_Array :=
           [A ("--verbose"), A ("--config=x")];
         R : constant CLI.Parse_Outcome.Result :=
           CLI.Parse (Test_Config, Args);
      begin
         Assert (R.Is_Ok, "Global flag --verbose ok");
         if R.Is_Ok then
            Assert
              (CLI.Is_Set (R.Ok_Value, Verbose),
               "--verbose Is_Set");
            Assert
              (CLI.Flag_Count (R.Ok_Value, Verbose) = 1,
               "--verbose count is 1");
         end if;
      end;

      --  ===== Global flag (short) =====
      declare
         Args : constant CLI.Argument_Array :=
           [A ("-v"), A ("--config=x")];
         R : constant CLI.Parse_Outcome.Result :=
           CLI.Parse (Test_Config, Args);
      begin
         Assert (R.Is_Ok, "Short flag -v ok");
         if R.Is_Ok then
            Assert
              (CLI.Is_Set (R.Ok_Value, Verbose),
               "-v Is_Set");
         end if;
      end;

      --  ===== Command-scoped flag =====
      declare
         Args : constant CLI.Argument_Array :=
           [A ("write"), A ("-y"), A ("--config=x")];
         R : constant CLI.Parse_Outcome.Result :=
           CLI.Parse (Test_Config, Args);
      begin
         Assert (R.Is_Ok, "Scoped flag -y with write ok");
         if R.Is_Ok then
            Assert
              (CLI.Is_Set (R.Ok_Value, Yes),
               "-y Is_Set with write command");
         end if;
      end;

      --  ===== Scoped flag without correct command =====
      declare
         Args : constant CLI.Argument_Array :=
           [A ("check"), A ("-y"), A ("--config=x")];
         R : constant CLI.Parse_Outcome.Result :=
           CLI.Parse (Test_Config, Args);
      begin
         Assert
           (not R.Is_Ok,
            "Scoped flag -y with check fails");
         if not R.Is_Ok then
            Assert
              (R.Error_Value.Kind = Command_Mismatch,
               "Scoped flag mismatch: Command_Mismatch");
         end if;
      end;

      --  ===== Option with = syntax (long) =====
      declare
         Args : constant CLI.Argument_Array :=
           [A ("--workers=4"), A ("--config=x")];
         R : constant CLI.Parse_Outcome.Result :=
           CLI.Parse (Test_Config, Args);
      begin
         Assert (R.Is_Ok, "Option --workers=4 ok");
         if R.Is_Ok then
            Assert
              (CLI.Has_Option (R.Ok_Value, Workers),
               "--workers Has_Option");
            Assert
              (CLI.Get_Option (R.Ok_Value, Workers) = "4",
               "--workers value is 4");
         end if;
      end;

      --  ===== Option with short and space =====
      declare
         Args : constant CLI.Argument_Array :=
           [A ("-j"), A ("8"), A ("--config=x")];
         R : constant CLI.Parse_Outcome.Result :=
           CLI.Parse (Test_Config, Args);
      begin
         Assert (R.Is_Ok, "Short option -j 8 ok");
         if R.Is_Ok then
            Assert
              (CLI.Get_Option (R.Ok_Value, Workers) = "8",
               "-j 8 value is 8");
         end if;
      end;

      --  ===== Option with short attached value =====
      declare
         Args : constant CLI.Argument_Array :=
           [A ("-j4"), A ("--config=x")];
         R : constant CLI.Parse_Outcome.Result :=
           CLI.Parse (Test_Config, Args);
      begin
         Assert (R.Is_Ok, "Short option -j4 ok");
         if R.Is_Ok then
            Assert
              (CLI.Get_Option (R.Ok_Value, Workers) = "4",
               "-j4 value is 4");
         end if;
      end;

      --  ===== Get_Option_Or with default =====
      declare
         Args : constant CLI.Argument_Array :=
           [A ("--config=x")];
         R : constant CLI.Parse_Outcome.Result :=
           CLI.Parse (Test_Config, Args);
      begin
         Assert (R.Is_Ok, "Parse without workers ok");
         if R.Is_Ok then
            Assert
              (CLI.Get_Option_Or (R.Ok_Value, Workers, "1") = "1",
               "Get_Option_Or returns default when unset");
         end if;
      end;

      --  ===== Multiple option (repeatable) =====
      declare
         Args : constant CLI.Argument_Array :=
           [A ("--exclude=*.bak"),
            A ("--exclude=tmp/"),
            A ("--config=x")];
         R : constant CLI.Parse_Outcome.Result :=
           CLI.Parse (Test_Config, Args);
      begin
         Assert (R.Is_Ok, "Multiple --exclude ok");
         if R.Is_Ok then
            Assert
              (CLI.Option_Count (R.Ok_Value, Exclude) = 2,
               "Exclude count is 2");
            Assert
              (CLI.Has_Option (R.Ok_Value, Exclude),
               "Exclude Has_Option");
            --  Last value wins for .Value
            Assert
              (CLI.Get_Option (R.Ok_Value, Exclude) = "tmp/",
               "Exclude last value is tmp/");
         end if;
      end;

      --  ===== Required option missing =====
      declare
         Args : constant CLI.Argument_Array :=
           [A ("--workers=4")];
         R : constant CLI.Parse_Outcome.Result :=
           CLI.Parse (Test_Config, Args);
      begin
         Assert
           (not R.Is_Ok,
            "Missing required config fails");
         if not R.Is_Ok then
            Assert
              (R.Error_Value.Kind = Missing_Required,
               "Missing_Required for config");
         end if;
      end;

      --  ===== Positional arguments =====
      declare
         Args : constant CLI.Argument_Array :=
           [A ("--config=x"), A ("src/main.adb"), A ("src/util.adb")];
         R : constant CLI.Parse_Outcome.Result :=
           CLI.Parse (Test_Config, Args);
      begin
         Assert (R.Is_Ok, "Positionals parsed ok");
         if R.Is_Ok then
            Assert
              (CLI.Has_Positional (R.Ok_Value, Paths),
               "Paths Has_Positional");
            Assert
              (CLI.Positional_Count (R.Ok_Value, Paths) = 2,
               "Paths count is 2");
         end if;
      end;

      --  ===== Positional after -- =====
      declare
         Args : constant CLI.Argument_Array :=
           [A ("--config=x"), A ("--"), A ("--not-a-flag")];
         R : constant CLI.Parse_Outcome.Result :=
           CLI.Parse (Test_Config, Args);
      begin
         Assert (R.Is_Ok, "Positional after -- ok");
         if R.Is_Ok then
            Assert
              (CLI.Positional_Count (R.Ok_Value, Paths) = 1,
               "One positional after --");
            declare
               V : constant Value_List :=
                 R.Ok_Value.Positionals (Paths).Values;
            begin
               Assert
                 (To_String (V.First_Element) = "--not-a-flag",
                  "Positional after -- preserves value");
            end;
         end if;
      end;

      --  ===== Unknown switch =====
      declare
         Args : constant CLI.Argument_Array :=
           [A ("--unknown"), A ("--config=x")];
         R : constant CLI.Parse_Outcome.Result :=
           CLI.Parse (Test_Config, Args);
      begin
         Assert (not R.Is_Ok, "Unknown switch fails");
         if not R.Is_Ok then
            Assert
              (R.Error_Value.Kind = Unknown_Switch,
               "Unknown_Switch error for --unknown");
         end if;
      end;

      --  ===== Unknown short switch =====
      declare
         Args : constant CLI.Argument_Array :=
           [A ("-z"), A ("--config=x")];
         R : constant CLI.Parse_Outcome.Result :=
           CLI.Parse (Test_Config, Args);
      begin
         Assert (not R.Is_Ok, "Unknown short -z fails");
         if not R.Is_Ok then
            Assert
              (R.Error_Value.Kind = Unknown_Switch,
               "Unknown_Switch for -z");
         end if;
      end;

      --  ===== Long option missing = value =====
      declare
         Args : constant CLI.Argument_Array :=
           [A ("--workers"), A ("--config=x")];
         R : constant CLI.Parse_Outcome.Result :=
           CLI.Parse (Test_Config, Args);
      begin
         Assert
           (not R.Is_Ok,
            "Long option without = fails");
         if not R.Is_Ok then
            Assert
              (R.Error_Value.Kind = Missing_Value,
               "Missing_Value for --workers without =");
         end if;
      end;

      --  ===== Short option missing value (at end) =====
      declare
         Args : constant CLI.Argument_Array :=
           [A ("-j")];
         R : constant CLI.Parse_Outcome.Result :=
           CLI.Parse (Test_Config, Args);
      begin
         Assert (not R.Is_Ok, "Short option -j at end fails");
         if not R.Is_Ok then
            Assert
              (R.Error_Value.Kind = Missing_Value,
               "Missing_Value for -j at end");
         end if;
      end;

      --  ===== Help request (long) =====
      --  Show_Help mid-parse callback was removed; help is now a pure
      --  outcome signal via Help_Requested error kind.
      declare
         Args : constant CLI.Argument_Array := [1 => A ("--help")];
         R : constant CLI.Parse_Outcome.Result :=
           CLI.Parse (Test_Config, Args);
      begin
         Assert (not R.Is_Ok, "--help returns error");
         if not R.Is_Ok then
            Assert
              (R.Error_Value.Kind = Help_Requested,
               "--help: Help_Requested");
         end if;
      end;

      --  ===== Help request (short) =====
      declare
         Args : constant CLI.Argument_Array := [1 => A ("-h")];
         R : constant CLI.Parse_Outcome.Result :=
           CLI.Parse (Test_Config, Args);
      begin
         Assert (not R.Is_Ok, "-h returns error");
         if not R.Is_Ok then
            Assert
              (R.Error_Value.Kind = Help_Requested,
               "-h: Help_Requested");
         end if;
      end;

      --  ===== Version request =====
      declare
         Args : constant CLI.Argument_Array :=
           [1 => A ("--version")];
         R : constant CLI.Parse_Outcome.Result :=
           CLI.Parse (Test_Config, Args);
      begin
         Assert (not R.Is_Ok, "--version returns error");
         if not R.Is_Ok then
            Assert
              (R.Error_Value.Kind = Version_Requested,
               "--version: Version_Requested");
         end if;
      end;

      --  ===== Combined flags: -vy =====
      declare
         Args : constant CLI.Argument_Array :=
           [A ("write"), A ("-vy"), A ("--config=x")];
         R : constant CLI.Parse_Outcome.Result :=
           CLI.Parse (Test_Config, Args);
      begin
         Assert (R.Is_Ok, "Combined -vy with write ok");
         if R.Is_Ok then
            Assert
              (CLI.Is_Set (R.Ok_Value, Verbose),
               "-vy sets verbose");
            Assert
              (CLI.Is_Set (R.Ok_Value, Yes),
               "-vy sets yes");
         end if;
      end;

      --  ===== Command with all components =====
      declare
         Args : constant CLI.Argument_Array :=
           [A ("write"),
            A ("-y"),
            A ("--verbose"),
            A ("--workers=4"),
            A ("--config=fmt.toml"),
            A ("--exclude=*.bak"),
            A ("--exclude=obj/"),
            A ("src/main.adb"),
            A ("src/util.adb")];
         R : constant CLI.Parse_Outcome.Result :=
           CLI.Parse (Test_Config, Args);
      begin
         Assert (R.Is_Ok, "Full command line parsed ok");
         if R.Is_Ok then
            declare
               V : constant CLI.Parse_Results := R.Ok_Value;
            begin
               Assert
                 (CLI.Is_Active (V, Write), "Write is active");
               Assert (CLI.Is_Set (V, Yes), "Yes is set");
               Assert (CLI.Is_Set (V, Verbose), "Verbose is set");
               Assert
                 (CLI.Get_Option (V, Workers) = "4",
                  "Workers is 4");
               Assert
                 (CLI.Get_Option (V, Config) = "fmt.toml",
                  "Config is fmt.toml");
               Assert
                 (CLI.Option_Count (V, Exclude) = 2,
                  "Exclude has 2 values");
               Assert
                 (CLI.Positional_Count (V, Paths) = 2,
                  "Paths has 2 values");
            end;
         end if;
      end;

      --  ===== Simple CLI (no commands) =====
      declare
         use Simple_CLI;
         Args : constant Simple_CLI.Argument_Array :=
           [A ("-v"), A ("-o"), A ("out.txt"), A ("in.adb")];
         R : constant Simple_CLI.Parse_Outcome.Result :=
           Simple_CLI.Parse (Simple_Config, Args);
      begin
         Assert (R.Is_Ok, "Simple CLI parsed ok");
         if R.Is_Ok then
            Assert
              (Simple_CLI.Is_Set (R.Ok_Value, Verbose),
               "Simple: verbose is set");
            Assert
              (Simple_CLI.Get_Option (R.Ok_Value, Output) = "out.txt",
               "Simple: output is out.txt");
            Assert
              (Simple_CLI.Has_Positional (R.Ok_Value, Input_File),
               "Simple: has positional");
         end if;
      end;

      --  ===== Flag counting (-vvv) =====
      declare
         Args : constant CLI.Argument_Array :=
           [A ("-v"), A ("-v"), A ("-v"), A ("--config=x")];
         R : constant CLI.Parse_Outcome.Result :=
           CLI.Parse (Test_Config, Args);
      begin
         Assert (R.Is_Ok, "Triple -v parsed ok");
         if R.Is_Ok then
            Assert
              (CLI.Flag_Count (R.Ok_Value, Verbose) = 3,
               "Verbose count is 3");
         end if;
      end;

      --  ===== Option with empty value =====
      declare
         Args : constant CLI.Argument_Array :=
           [A ("--config="), A ("--workers=")];
         R : constant CLI.Parse_Outcome.Result :=
           CLI.Parse (Test_Config, Args);
      begin
         Assert (R.Is_Ok, "Empty option values parsed ok");
         if R.Is_Ok then
            Assert
              (CLI.Get_Option (R.Ok_Value, Config) = "",
               "Config empty value");
            Assert
              (CLI.Get_Option (R.Ok_Value, Workers) = "",
               "Workers empty value");
         end if;
      end;

      --  ===== Is_Graceful_Exit predicate on parse errors =====
      declare
         Args : constant CLI.Argument_Array := [1 => A ("--help")];
         R : constant CLI.Parse_Outcome.Result :=
           CLI.Parse (Test_Config, Args);
      begin
         if not R.Is_Ok then
            Assert
              (Is_Graceful_Exit (R.Error_Value),
               "Help error Is_Graceful_Exit");
         end if;
      end;

      Total := Total_Count;
      Passed := Passed_Count;
   end Run;

end Test_CLI;
