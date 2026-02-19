pragma Ada_2022;
--  ===========================================================================
--  Clara.Application - Generic CLI Application Definition
--  ===========================================================================
--  Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
--  SPDX-License-Identifier: BSD-3-Clause
--
--  Purpose:
--    Main generic package for defining command-line interfaces.
--    Users instantiate this with their application name and description,
--    then use child generics (Command, Flag, Option, Positional) to define
--    arguments. Supports subcommands with command-scoped flags/options.
--
--  Usage (without commands):
--    package My_CLI is new Clara.Application ("myapp", "My application");
--    package Verbose is new My_CLI.Flag ('v', "verbose", "Enable verbose");
--    package Output is new My_CLI.Option ('o', "output", "FILE", "Output");
--    package Files is new My_CLI.Positional ("FILES", "Input files", True);
--
--    Result := My_CLI.Parse;
--    if Verbose.Is_Set then ...
--    Path := Output.Value_Or ("default.txt");
--
--  Usage (with commands and repeatable option):
--    procedure My_Help;
--    package CLI is new Clara.Application
--      ("adafmt", "Ada formatter", Show_Help => My_Help);
--    package Write_Cmd is new CLI.Command ("write", "Format files");
--    package Check_Cmd is new CLI.Command ("check", "Verify compliance");
--    package Workers is new CLI.Option
--      ('j', "workers", "N", "Worker count");
--    package Exclude is new CLI.Option
--      (Long => "exclude-path", Value_Name => "PATH",
--       Help => "Exclude path", Multiple => True);
--    package Yes is new CLI.Flag
--      ('y', "yes", "Skip confirmation", Command => "write");
--    package Paths is new CLI.Positional ("PATHS", "Source paths", True);
--
--    Result := CLI.Parse;
--    if Write_Cmd.Is_Active then ...
--    for I in 1 .. Exclude.Count loop ... end loop;
--
--  Value Syntax Convention:
--    Long options require '=' syntax:  --workers=4
--    Short options use space or attached: -j 4  or  -j4
--
--  Design Notes:
--    - Each child generic instance registers itself at elaboration
--    - Parse reads Ada.Command_Line and populates registered arguments
--    - State is package-level, shared across child instances
--    - SPARK_Mode is Off due to package-level state initialization
--    - Commands enable two-phase parse: detect command, then process flags
--
--  ===========================================================================

with Clara.Types;  use Clara.Types;
with Clara.Errors; use Clara.Errors;
with Functional.Result;
with Functional.Option;

generic
   App_Name        : String;  --  Application name (shown in help/errors)
   App_Description : String;  --  Application description (shown in help)
   with procedure Show_Help is null;
   --  User-provided help callback. Called when --help/-h is detected.
   --  If not provided, the caller should handle Help_Requested error.
package Clara.Application is

   --  ==========================================================================
   --  Result Type for Parse
   --  ==========================================================================
   --  Parse returns Result[Unit, Parse_Error] following Functional patterns.

   type Unit is null record;
   --  Unit type for Result success value when no data to return

   package Parse_Result is new Functional.Result (T => Unit, E => Parse_Error);

   --  ==========================================================================
   --  Core Functions
   --  ==========================================================================

   function Parse return Parse_Result.Result;
   --  Parse command line arguments.
   --  Returns Ok(Unit) on success, Error(Parse_Error) on failure.
   --  When commands are registered, performs two-phase parse:
   --    Phase 1: Identify active command from first non-switch argument.
   --    Phase 2: Process global and command-scoped flags/options.
   --  Must be called before querying flags/options/positionals.

   function Is_Parsed return Boolean;
   --  True if Parse has been called successfully.

   function Active_Command return String;
   --  Returns the name of the active command, or "" if none is active.

   procedure Print_Help;
   --  Print auto-generated help text to standard output.
   --  Shows: name, description, usage, commands, all flags/options/positionals.

   procedure Print_Version;
   --  Print version information to standard output.

   --  ==========================================================================
   --  Command Child Generic
   --  ==========================================================================
   --  Subcommand definition (e.g., write, check, dry-run).
   --  The first non-switch argument matching a registered command name
   --  becomes the active command. Command-scoped flags/options are only
   --  accepted when their command is active.

   generic
      Name : String;        --  Command name (e.g., "write", "check")
      Help : String := "";  --  Command description for help text
   package Command is

      function Is_Active return Boolean;
      --  True if this command was specified on the command line.

   end Command;

   --  ==========================================================================
   --  Flag Child Generic
   --  ==========================================================================
   --  Boolean switch: -v, --verbose
   --  Can appear multiple times for counting (e.g., -vvv for verbosity level 3)

   generic
      Short   : Character := ASCII.NUL;  --  Short form, e.g., 'v' for -v
      Long    : String;                   --  Long form, e.g., "verbose"
      Help    : String := "";             --  Help text description
      Command : String := "";             --  "" = global, "write" = scoped
   package Flag is

      function Is_Set return Boolean;
      --  True if flag was specified at least once.

      function Count return Natural;
      --  Number of times flag was specified (for -vvv style).

   end Flag;

   --  ==========================================================================
   --  Option Child Generic
   --  ==========================================================================
   --  Switch with value: --output=file, -o file
   --  Long options require '=' syntax. Short options use space or attached.

   generic
      Short      : Character := ASCII.NUL;  --  Short form, e.g., 'o' for -o
      Long       : String;                   --  Long form, e.g., "output"
      Value_Name : String := "VALUE";        --  Shown in help, e.g., "FILE"
      Help       : String := "";             --  Help text description
      Required   : Boolean := False;         --  If true, parse fails when missing
      Command    : String := "";             --  "" = global, "write" = scoped
      Multiple   : Boolean := False;         --  If true, collects multiple values
   package Option is

      --  Option type for return value
      package String_Option is new Functional.Option (T => Value_String);

      function Has_Value return Boolean;
      --  True if option was specified with a value.

      function Value return String_Option.Option;
      --  Returns Some(first value) if specified, None otherwise.

      function Value_Or (Default : String) return String;
      --  Returns first value if specified, otherwise default.
      --  Convenience function equivalent to: Value or To_Value(Default)

      --  Multi-value API (mirrors Positional)
      function Has_Values return Boolean;
      --  True if at least one value was provided.

      function Count return Natural;
      --  Number of values collected.

      function First return Value_String
        with Pre => Has_Value;
      --  First value. Precondition: Has_Value = True.

      function Values return Value_Vector
        with Post => (if not Multiple then Values'Result.Count <= 1);
      --  All values. If Multiple = False, at most one value.

   end Option;

   --  ==========================================================================
   --  Positional Child Generic
   --  ==========================================================================
   --  Non-switch arguments (file paths, etc.)

   generic
      Name     : String;           --  Argument name for help, e.g., "FILES"
      Help     : String := "";     --  Help text description
      Multiple : Boolean := False; --  If true, collects multiple values
   package Positional is

      function Has_Values return Boolean;
      --  True if at least one positional value was provided.

      function Count return Natural;
      --  Number of positional values collected.

      function First return Value_String
        with Pre => Has_Values;
      --  First positional value. Precondition: Has_Values = True.

      function Values return Value_Vector
        with Post => (if not Multiple then Values'Result.Count <= 1);
      --  All positional values. If Multiple = False, at most one value.

   end Positional;

end Clara.Application;
