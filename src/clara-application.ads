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
--    then use child generics (Flag, Option, Positional) to define arguments.
--
--  Usage:
--    package My_CLI is new Clara.Application ("myapp", "My application");
--    package Verbose is new My_CLI.Flag ('v', "verbose", "Enable verbose");
--    package Output is new My_CLI.Option ('o', "output", "FILE", "Output path");
--    package Files is new My_CLI.Positional ("FILES", "Input files", True);
--
--    Result := My_CLI.Parse;
--    if Verbose.Is_Set then ...
--    Path := Output.Value or "default.txt";
--
--  Design Notes:
--    - Each child generic instance registers itself at elaboration
--    - Parse reads Ada.Command_Line and populates registered arguments
--    - State is package-level, shared across child instances
--    - SPARK_Mode is Off due to package-level state initialization
--
--  ===========================================================================

with Clara.Types;  use Clara.Types;
with Clara.Errors; use Clara.Errors;
with Functional.Result;
with Functional.Option;

generic
   App_Name        : String;  --  Application name (shown in help/errors)
   App_Description : String;  --  Application description (shown in help)
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
   --  Must be called before querying flags/options/positionals.

   function Is_Parsed return Boolean;
   --  True if Parse has been called successfully.

   procedure Print_Help;
   --  Print help text to standard output.
   --  Shows: name, description, usage, all flags/options/positionals.

   procedure Print_Version;
   --  Print version information to standard output.

   --  ==========================================================================
   --  Flag Child Generic
   --  ==========================================================================
   --  Boolean switch: -v, --verbose
   --  Can appear multiple times for counting (e.g., -vvv for verbosity level 3)

   generic
      Short : Character := ASCII.NUL;  --  Short form, e.g., 'v' for -v
      Long  : String;                   --  Long form, e.g., "verbose" for --verbose
      Help  : String := "";             --  Help text description
   package Flag is

      function Is_Set return Boolean;
      --  True if flag was specified at least once.

      function Count return Natural;
      --  Number of times flag was specified (for -vvv style).

   end Flag;

   --  ==========================================================================
   --  Option Child Generic
   --  ==========================================================================
   --  Switch with value: -o file, --output=file, --output file

   generic
      Short      : Character := ASCII.NUL;  --  Short form, e.g., 'o' for -o
      Long       : String;                   --  Long form, e.g., "output"
      Value_Name : String := "VALUE";        --  Shown in help, e.g., "FILE"
      Help       : String := "";             --  Help text description
      Required   : Boolean := False;         --  If true, parse fails when missing
   package Option is

      --  Option type for return value
      package String_Option is new Functional.Option (T => Value_String);

      function Has_Value return Boolean;
      --  True if option was specified with a value.

      function Value return String_Option.Option;
      --  Returns Some(value) if specified, None otherwise.

      function Value_Or (Default : String) return String;
      --  Returns value if specified, otherwise default.
      --  Convenience function equivalent to: Value or To_Value(Default)

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
