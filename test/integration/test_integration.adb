pragma Ada_2022;
--  ===========================================================================
--  Integration Tests for Clara.CLI
--  ===========================================================================
--  Tests realistic CLI configurations similar to what adafmt uses.
--  Exercises multi-command, multi-option, multi-positional scenarios.

with Ada.Text_IO;           use Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Clara.Types;           use Clara.Types;
with Clara.Errors;          use Clara.Errors;
with Clara.CLI;

package body Test_Integration is

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

   function A (S : String) return Value_String
     renames To_Unbounded_String;

   --  ======================================================================
   --  Realistic adafmt-like CLI configuration
   --  ======================================================================

   type Cmd is (Write, Check, Dry_Run);
   type Flg is (Yes);
   type Opt is
     (Workers, Indent_Width, End_Of_Line, Encoding_In,
      Exclude_Path, Backup_Path, Format_Path);
   type Pos is (Paths);

   package CLI is new Clara.CLI
     (Command_Id      => Cmd,
      Flag_Id         => Flg,
      Option_Id       => Opt,
      Positional_Id   => Pos,
      App_Name        => "adafmt",
      App_Description => "Ada source code formatter");

   Config : constant CLI.CLI_Config :=
     (Commands =>
        [Write   => CLI.Cmd ("write", "Format in place"),
         Check   => CLI.Cmd ("check", "Verify compliance"),
         Dry_Run => CLI.Cmd ("dry-run", "Preview changes")],
      Flags =>
        [Yes => CLI.Flag ('y', "yes", "Skip confirmation",
                          Scope => Write)],
      Options =>
        [Workers      => CLI.Opt ('j', "workers", "N",
                                  "Worker threads"),
         Indent_Width => CLI.Opt (Long => "indent-width",
                                  Value_Name => "N",
                                  Help => "Indent width (3)"),
         End_Of_Line  => CLI.Opt (Long => "end-of-line",
                                  Value_Name => "EOL",
                                  Help => "Line ending"),
         Encoding_In  => CLI.Opt (Long => "encoding-in",
                                  Value_Name => "ENC",
                                  Help => "Input encoding"),
         Exclude_Path => CLI.Opt (Long => "exclude-path",
                                  Value_Name => "GLOB",
                                  Help => "Exclude pattern",
                                  Multiple => True),
         Backup_Path  => CLI.Opt ('b', "backup-path", "PATH",
                                  "Backup directory",
                                  Scope => Write),
         Format_Path  => CLI.Opt (Long => "format-path",
                                  Value_Name => "PATH",
                                  Help => "Format config file")],
      Positionals =>
        [Paths => CLI.Pos ("PATHS", "Source paths",
                           Multiple => True)]);

   --  ======================================================================
   --  Tests
   --  ======================================================================

   procedure Run (Total : out Natural; Passed : out Natural) is
   begin
      Total_Count := 0;
      Passed_Count := 0;
      Put_Line ("--- Test_Integration ---");

      --  ===== Realistic write command =====
      declare
         Args : constant CLI.Argument_Array :=
           [A ("write"),
            A ("-y"),
            A ("-j"), A ("4"),
            A ("--indent-width=3"),
            A ("--end-of-line=lf"),
            A ("--exclude-path=*.bak"),
            A ("--exclude-path=obj/"),
            A ("--backup-path=/tmp/backup"),
            A ("src/main.adb"),
            A ("src/util.adb"),
            A ("src/config.ads")];
         R : constant CLI.Parse_Outcome.Result :=
           CLI.Parse (Config, Args);
      begin
         Assert (R.Is_Ok, "Realistic write command ok");
         if R.Is_Ok then
            declare
               V : constant CLI.Parse_Results := R.Ok_Value;
            begin
               Assert
                 (CLI.Is_Active (V, Write),
                  "Write command active");
               Assert
                 (CLI.Is_Set (V, Yes),
                  "Yes flag set");
               Assert
                 (CLI.Get_Option (V, Workers) = "4",
                  "Workers is 4");
               Assert
                 (CLI.Get_Option (V, Indent_Width) = "3",
                  "Indent_Width is 3");
               Assert
                 (CLI.Get_Option (V, End_Of_Line) = "lf",
                  "End_Of_Line is lf");
               Assert
                 (CLI.Option_Count (V, Exclude_Path) = 2,
                  "Exclude_Path has 2 values");
               Assert
                 (CLI.Get_Option (V, Backup_Path) = "/tmp/backup",
                  "Backup_Path is /tmp/backup");
               Assert
                 (CLI.Positional_Count (V, Paths) = 3,
                  "Paths has 3 values");
            end;
         end if;
      end;

      --  ===== Realistic check command =====
      declare
         Args : constant CLI.Argument_Array :=
           [A ("check"),
            A ("--indent-width=3"),
            A ("--format-path=adafmt.toml"),
            A (".")];
         R : constant CLI.Parse_Outcome.Result :=
           CLI.Parse (Config, Args);
      begin
         Assert (R.Is_Ok, "Realistic check command ok");
         if R.Is_Ok then
            Assert
              (CLI.Is_Active (R.Ok_Value, Check),
               "Check command active");
            Assert
              (not CLI.Is_Set (R.Ok_Value, Yes),
               "Yes flag not set for check");
            Assert
              (CLI.Get_Option (R.Ok_Value, Format_Path)
               = "adafmt.toml",
               "Format_Path is adafmt.toml");
         end if;
      end;

      --  ===== Realistic dry-run command =====
      declare
         Args : constant CLI.Argument_Array :=
           [A ("dry-run"), A ("src/")];
         R : constant CLI.Parse_Outcome.Result :=
           CLI.Parse (Config, Args);
      begin
         Assert (R.Is_Ok, "Realistic dry-run ok");
         if R.Is_Ok then
            Assert
              (CLI.Is_Active (R.Ok_Value, Dry_Run),
               "Dry_Run active");
            Assert
              (CLI.Positional_Count (R.Ok_Value, Paths) = 1,
               "One positional path");
         end if;
      end;

      --  ===== Scoped option -b with wrong command =====
      declare
         Args : constant CLI.Argument_Array :=
           [A ("check"), A ("--backup-path=/tmp"), A ("src/")];
         R : constant CLI.Parse_Outcome.Result :=
           CLI.Parse (Config, Args);
      begin
         Assert
           (not R.Is_Ok,
            "Scoped backup-path with check fails");
         if not R.Is_Ok then
            Assert
              (R.Error_Value.Kind = Command_Mismatch,
               "Command_Mismatch for backup-path with check");
         end if;
      end;

      --  ===== Multiple exclude paths with values =====
      declare
         Args : constant CLI.Argument_Array :=
           [A ("--exclude-path=*.o"),
            A ("--exclude-path=*.ali"),
            A ("--exclude-path=obj/**"),
            A ("--exclude-path=lib/**"),
            A ("--exclude-path=test/bin/**"),
            A ("check"), A (".")];
         R : constant CLI.Parse_Outcome.Result :=
           CLI.Parse (Config, Args);
      begin
         Assert (R.Is_Ok, "Five exclude paths ok");
         if R.Is_Ok then
            Assert
              (CLI.Option_Count (R.Ok_Value, Exclude_Path) = 5,
               "Exclude_Path has 5 values");
            --  Verify values are accessible from vector
            declare
               VL : constant Value_List :=
                 R.Ok_Value.Options (Exclude_Path).Values;
            begin
               Assert
                 (To_String (VL.First_Element) = "*.o",
                  "First exclude is *.o");
               Assert
                 (To_String (VL.Last_Element) = "test/bin/**",
                  "Last exclude is test/bin/**");
            end;
         end if;
      end;

      --  ===== Many positional paths =====
      declare
         Args : CLI.Argument_Array (1 .. 102);
      begin
         Args (1) := A ("write");
         Args (2) := A ("-y");
         for I in 3 .. 102 loop
            Args (I) := A ("file" & Integer'Image (I) & ".adb");
         end loop;
         declare
            R : constant CLI.Parse_Outcome.Result :=
              CLI.Parse (Config, Args);
         begin
            Assert (R.Is_Ok, "100 positional paths ok");
            if R.Is_Ok then
               Assert
                 (CLI.Positional_Count (R.Ok_Value, Paths) = 100,
                  "100 positional paths counted");
            end if;
         end;
      end;

      --  ===== Command anywhere in args (not just first) =====
      declare
         Args : constant CLI.Argument_Array :=
           [A ("--indent-width=4"), A ("write"), A ("-y"), A ("src/")];
         R : constant CLI.Parse_Outcome.Result :=
           CLI.Parse (Config, Args);
      begin
         Assert (R.Is_Ok, "Command after global option ok");
         if R.Is_Ok then
            Assert
              (CLI.Is_Active (R.Ok_Value, Write),
               "Write active when after global opt");
            Assert
              (CLI.Is_Set (R.Ok_Value, Yes),
               "Yes set when command after global opt");
         end if;
      end;

      --  ===== Default values via Get_Option_Or =====
      declare
         Args : constant CLI.Argument_Array :=
           [A ("check"), A ("src/")];
         R : constant CLI.Parse_Outcome.Result :=
           CLI.Parse (Config, Args);
      begin
         Assert (R.Is_Ok, "Minimal check ok");
         if R.Is_Ok then
            Assert
              (CLI.Get_Option_Or (R.Ok_Value, Workers, "1") = "1",
               "Workers defaults to 1");
            Assert
              (CLI.Get_Option_Or (R.Ok_Value, Indent_Width, "3") = "3",
               "Indent_Width defaults to 3");
            Assert
              (CLI.Get_Option_Or (R.Ok_Value, End_Of_Line, "lf") = "lf",
               "End_Of_Line defaults to lf");
            Assert
              (CLI.Get_Option_Or
                 (R.Ok_Value, Encoding_In, "utf-8") = "utf-8",
               "Encoding_In defaults to utf-8");
         end if;
      end;

      --  ===== No command, no positionals =====
      declare
         Args : constant CLI.Argument_Array (1 .. 0) :=
           [others => Null_Unbounded_String];
         R : constant CLI.Parse_Outcome.Result :=
           CLI.Parse (Config, Args);
      begin
         Assert (R.Is_Ok, "Empty args ok (no required opts)");
         if R.Is_Ok then
            Assert
              (not R.Ok_Value.Has_Active_Command,
               "No active command with empty args");
            Assert
              (not CLI.Has_Positional (R.Ok_Value, Paths),
               "No positionals with empty args");
         end if;
      end;

      Total := Total_Count;
      Passed := Passed_Count;
   end Run;

end Test_Integration;
