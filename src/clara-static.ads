pragma Ada_2022;
--  ===========================================================================
--  Clara.Static - SPARK-Provable Static CLI Definition
--  ===========================================================================
--  Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
--  SPDX-License-Identifier: BSD-3-Clause
--
--  Purpose:
--    Fully SPARK-provable command-line argument parser using static
--    enumeration-indexed arrays instead of runtime registration.
--
--  Design Philosophy:
--    - No access types (SPARK requirement)
--    - No mutable package state (SPARK requirement)
--    - Pure functions for parsing (referential transparency)
--    - Enumeration-indexed arrays for type-safe lookups
--    - Returns Result types following functional patterns
--
--  Usage:
--    1. Define enumerations for your flags, options, and positionals
--    2. Instantiate Clara.Static with your enumerations
--    3. Define your CLI configuration as a constant record
--    4. Call Parse to get results
--
--  Example:
--    type My_Flags is (Verbose, Debug, Help);
--    type My_Options is (Output, Config);
--    type My_Positionals is (Input_File);
--
--    package CLI is new Clara.Static
--      (Flag_Names => My_Flags,
--       Option_Names => My_Options,
--       Positional_Names => My_Positionals);
--
--    Config : constant CLI.CLI_Config := (...);
--    Result : CLI.Parse_Result.Result := CLI.Parse (Config);
--
--  ===========================================================================

with Clara.Types;  use Clara.Types;
with Clara.Errors; use Clara.Errors;
with Functional.Result;
with Functional.Option;

generic
   --  User-defined enumerations for CLI components
   type Flag_Names is (<>);
   type Option_Names is (<>);
   type Positional_Names is (<>);

   --  Application metadata
   App_Name        : String;
   App_Description : String;
package Clara.Static
  with SPARK_Mode => On
is

   --  =========================================================================
   --  Flag Definition
   --  =========================================================================
   --  Defines a boolean flag like -v or --verbose

   type Flag_Definition is record
      Short : Character := ASCII.NUL;  --  Short form: 'v' for -v
      Long  : Long_Switch_String;       --  Long form: "verbose" for --verbose
      Help  : Help_String;              --  Help text description
   end record;

   --  Array of flag definitions indexed by user's enumeration
   type Flag_Definitions is array (Flag_Names) of Flag_Definition;

   --  =========================================================================
   --  Option Definition
   --  =========================================================================
   --  Defines a switch with value like -o file or --output=file

   type Option_Definition is record
      Short      : Character := ASCII.NUL;  --  Short form: 'o' for -o
      Long       : Long_Switch_String;       --  Long form: "output"
      Value_Name : Value_Name_String;        --  Placeholder: "FILE"
      Help       : Help_String;              --  Help text
      Required   : Boolean := False;         --  If true, parse fails when missing
   end record;

   --  Array of option definitions indexed by user's enumeration
   type Option_Definitions is array (Option_Names) of Option_Definition;

   --  =========================================================================
   --  Positional Definition
   --  =========================================================================
   --  Defines positional arguments (non-switch arguments)

   type Positional_Definition is record
      Name     : Name_String;      --  Name for help: "FILE", "COMMAND"
      Help     : Help_String;      --  Help text
      Multiple : Boolean := False; --  If true, collects multiple values
   end record;

   --  Array of positional definitions indexed by user's enumeration
   type Positional_Definitions is array (Positional_Names) of Positional_Definition;

   --  =========================================================================
   --  CLI Configuration (Input)
   --  =========================================================================
   --  Complete CLI definition - passed to Parse as input

   type CLI_Config is record
      Flags       : Flag_Definitions;
      Options     : Option_Definitions;
      Positionals : Positional_Definitions;
   end record;

   --  =========================================================================
   --  Parse Results (Output)
   --  =========================================================================
   --  Results from parsing - indexed by the same enumerations

   --  Flag results: Boolean per flag, plus count for -vvv style
   type Flag_Result is record
      Is_Set : Boolean := False;
      Count  : Natural := 0;
   end record;

   type Flag_Results is array (Flag_Names) of Flag_Result;

   --  Option results: Optional value per option
   package Option_Value is new Functional.Option (T => Value_String);
   type Option_Results is array (Option_Names) of Option_Value.Option;

   --  Positional results: Vector of values per positional
   subtype Positional_Values is Value_Vector (Max_Positional_Values);
   type Positional_Results is array (Positional_Names) of Positional_Values;

   --  Complete parse results
   type Parse_Results is record
      Flags       : Flag_Results;
      Options     : Option_Results;
      Positionals : Positional_Results;
      Help_Requested    : Boolean := False;
      Version_Requested : Boolean := False;
   end record;

   --  =========================================================================
   --  Result Type
   --  =========================================================================

   package Parse_Result is new Functional.Result
     (T => Parse_Results, E => Parse_Error);

   --  =========================================================================
   --  Core Functions
   --  =========================================================================

   function Parse (Config : CLI_Config) return Parse_Result.Result;
   --  Parse command line arguments against the given configuration.
   --  Returns Ok(Parse_Results) on success, Error(Parse_Error) on failure.
   --
   --  Pure function: reads from Ada.Command_Line, returns results.
   --  No side effects, no mutable state.

   function Help_Text (Config : CLI_Config) return String;
   --  Generate help text for the CLI configuration.
   --  Returns formatted help string suitable for display.

   function Version_Text return String;
   --  Generate version text.
   --  Returns formatted version string.

   --  =========================================================================
   --  Convenience Functions for Results
   --  =========================================================================

   function Is_Set
     (Results : Parse_Results;
      Flag    : Flag_Names) return Boolean
   is (Results.Flags (Flag).Is_Set);
   --  Check if a flag was set.

   function Flag_Count
     (Results : Parse_Results;
      Flag    : Flag_Names) return Natural
   is (Results.Flags (Flag).Count);
   --  Get the count for a flag (for -vvv style).

   function Has_Option
     (Results : Parse_Results;
      Opt     : Option_Names) return Boolean
   is (Option_Value.Is_Some (Results.Options (Opt)));
   --  Check if an option was provided.

   function Get_Option
     (Results : Parse_Results;
      Opt     : Option_Names) return Option_Value.Option
   is (Results.Options (Opt));
   --  Get option value as Option type.

   function Get_Option_Or
     (Results : Parse_Results;
      Opt     : Option_Names;
      Default : String) return Value_String;
   --  Get option value or default.

   function Has_Positional
     (Results : Parse_Results;
      Pos     : Positional_Names) return Boolean
   is (Results.Positionals (Pos).Count > 0);
   --  Check if positional has any values.

   function Positional_Count
     (Results : Parse_Results;
      Pos     : Positional_Names) return Natural
   is (Results.Positionals (Pos).Count);
   --  Get count of positional values.

   function Get_Positional
     (Results : Parse_Results;
      Pos     : Positional_Names) return Positional_Values
   is (Results.Positionals (Pos));
   --  Get all positional values.

   --  =========================================================================
   --  Builder Helpers (for cleaner configuration syntax)
   --  =========================================================================

   function Flag
     (Short : Character := ASCII.NUL;
      Long  : String;
      Help  : String := "") return Flag_Definition
   is (Short => Short,
       Long  => To_Long_Switch (Long),
       Help  => To_Help (Help));
   --  Create a flag definition with convenient String parameters.

   function Opt
     (Short      : Character := ASCII.NUL;
      Long       : String;
      Value_Name : String := "VALUE";
      Help       : String := "";
      Required   : Boolean := False) return Option_Definition
   is (Short      => Short,
       Long       => To_Long_Switch (Long),
       Value_Name => To_Value_Name (Value_Name),
       Help       => To_Help (Help),
       Required   => Required);
   --  Create an option definition with convenient String parameters.

   function Pos
     (Name     : String;
      Help     : String := "";
      Multiple : Boolean := False) return Positional_Definition
   is (Name     => To_Name (Name),
       Help     => To_Help (Help),
       Multiple => Multiple);
   --  Create a positional definition with convenient String parameters.

end Clara.Static;
