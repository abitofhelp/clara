pragma Ada_2022;
--  ======================================================================
--  Test_Parse_Commands - Integration test for subcommand parsing
--  ======================================================================
--  Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
--  SPDX-License-Identifier: BSD-3-Clause
--
--  Usage:
--    test_parse_commands write -y src/     # Command + scoped flag
--    test_parse_commands check src/        # Different command
--    test_parse_commands -j 4 write src/   # Global option before command
--    test_parse_commands --help            # Help requested
--    test_parse_commands write --help      # Help with command active
--    test_parse_commands check -y          # Wrong-command flag (error)
--    test_parse_commands -y src/           # Scoped flag without command
--
--  Exit codes:
--    0 - Test passed
--    1 - Test failed
--  ======================================================================

with Ada.Text_IO;
with Ada.Command_Line;
with Clara.Application;
with Clara.Errors;

procedure Test_Parse_Commands is

   use Ada.Text_IO;
   use Ada.Command_Line;
   use Clara.Errors;

   Help_Called : Boolean := False;

   procedure My_Show_Help is
   begin
      Help_Called := True;
   end My_Show_Help;

   --  Instantiate CLI application with Show_Help callback
   package CLI is new Clara.Application
     (App_Name        => "test_parse_commands",
      App_Description => "Integration test for subcommand parsing",
      Show_Help       => My_Show_Help);

   --  Define commands
   package Write_Cmd is new CLI.Command
     (Name => "write",
      Help => "Format with persistence");

   package Check_Cmd is new CLI.Command
     (Name => "check",
      Help => "Verify compliance");

   package Dry_Run_Cmd is new CLI.Command
     (Name => "dry-run",
      Help => "Format without persistence");

   --  Global options
   package Workers is new CLI.Option
     (Short      => 'j',
      Long       => "workers",
      Value_Name => "N",
      Help       => "Worker count");

   package Verbose is new CLI.Flag
     (Short => 'v',
      Long  => "verbose",
      Help  => "Enable verbose output");

   --  Write-scoped options
   package Yes is new CLI.Flag
     (Short   => 'y',
      Long    => "yes",
      Help    => "Skip confirmation",
      Command => "write");

   package Backup is new CLI.Option
     (Short   => 'b',
      Long    => "backup-path",
      Value_Name => "PATH",
      Help    => "Backup directory",
      Command => "write");

   --  Positional arguments
   package Paths is new CLI.Positional
     (Name     => "PATHS",
      Help     => "Source file/directory paths",
      Multiple => True);

   Result : CLI.Parse_Result.Result;

begin
   Result := CLI.Parse;

   if Result.Is_Ok then
      Put_Line ("parsed=true");
      Put_Line ("active_command=" & CLI.Active_Command);
      Put_Line ("write_active=" &
                Boolean'Image (Write_Cmd.Is_Active));
      Put_Line ("check_active=" &
                Boolean'Image (Check_Cmd.Is_Active));
      Put_Line ("dry_run_active=" &
                Boolean'Image (Dry_Run_Cmd.Is_Active));
      Put_Line ("verbose_set=" & Boolean'Image (Verbose.Is_Set));
      Put_Line ("yes_set=" & Boolean'Image (Yes.Is_Set));
      Put_Line ("workers_has=" &
                Boolean'Image (Workers.Has_Value));
      if Workers.Has_Value then
         Put_Line ("workers_value=" & Workers.Value_Or (""));
      end if;
      Put_Line ("backup_has=" & Boolean'Image (Backup.Has_Value));
      if Backup.Has_Value then
         Put_Line ("backup_value=" & Backup.Value_Or (""));
      end if;
      Put_Line ("paths_count=" & Natural'Image (Paths.Count));
      Put_Line ("help_called=" & Boolean'Image (Help_Called));
      Set_Exit_Status (Success);

   elsif CLI.Parse_Result.Error (Result).Kind in
           Clara.Errors.Help_Requested | Clara.Errors.Version_Requested
   then
      Put_Line ("parsed=false");
      Put_Line ("help_called=" & Boolean'Image (Help_Called));
      Put_Line ("active_command=" & CLI.Active_Command);
      Put_Line ("error_kind=" &
                Clara.Errors.Error_Kind'Image
                  (CLI.Parse_Result.Error (Result).Kind));
      Set_Exit_Status (Success);

   elsif CLI.Parse_Result.Error (Result).Kind =
           Clara.Errors.Command_Mismatch
   then
      Put_Line ("parsed=false");
      Put_Line ("error_kind=COMMAND_MISMATCH");
      Put_Line ("error=" &
                Clara.Errors.Format (CLI.Parse_Result.Error (Result)));
      Set_Exit_Status (Success);  --  Expected error in mismatch tests

   else
      Put_Line ("parsed=false");
      Put_Line ("error_kind=" &
                Clara.Errors.Error_Kind'Image
                  (CLI.Parse_Result.Error (Result).Kind));
      Put_Line ("error=" &
                Clara.Errors.Format (CLI.Parse_Result.Error (Result)));
      Set_Exit_Status (Failure);
   end if;

end Test_Parse_Commands;
