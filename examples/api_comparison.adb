pragma Ada_2022;
--  ===========================================================================
--  API Comparison - Clara.Application vs Clara.Static
--  ===========================================================================
--  Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
--  SPDX-License-Identifier: BSD-3-Clause
--
--  Purpose:
--    Side-by-side comparison of the two Clara API styles.
--    This file won't compile - it's documentation showing both approaches.
--
--  ===========================================================================

--  ============================================================================
--  CURRENT API: Clara.Application (Self-Registering Generics)
--  ============================================================================
--
--  Pros:
--    - Most ergonomic syntax
--    - Each flag/option is its own package (namespace isolation)
--    - Compile-time type safety per argument
--    - Natural "dot notation" access: Verbose.Is_Set
--
--  Cons:
--    - Uses access types internally (not SPARK-provable)
--    - Package-level mutable state
--    - Registration happens at elaboration time
--
--  Example:
--
--    with Clara.Application;
--    with Ada.Text_IO; use Ada.Text_IO;
--
--    procedure Current_API_Example is
--
--       --  Define CLI application
--       package CLI is new Clara.Application
--         (App_Name        => "myapp",
--          App_Description => "Example application");
--
--       --  Define flags as packages
--       package Verbose is new CLI.Flag
--         (Short => 'v', Long => "verbose", Help => "Enable verbose output");
--
--       package Debug is new CLI.Flag
--         (Short => 'd', Long => "debug", Help => "Enable debug mode");
--
--       --  Define options as packages
--       package Output is new CLI.Option
--         (Short      => 'o',
--          Long       => "output",
--          Value_Name => "FILE",
--          Help       => "Output file path");
--
--       package Format is new CLI.Option
--         (Short      => 'f',
--          Long       => "format",
--          Value_Name => "FMT",
--          Help       => "Output format");
--
--       --  Define positionals as packages
--       package Files is new CLI.Positional
--         (Name     => "FILES",
--          Help     => "Input files",
--          Multiple => True);
--
--       Result : CLI.Parse_Result.Result;
--
--    begin
--       Result := CLI.Parse;
--
--       if Result.Is_Ok then
--          --  Access via package names - very clean!
--          if Verbose.Is_Set then
--             Put_Line ("Verbose mode enabled");
--          end if;
--
--          if Debug.Is_Set then
--             Put_Line ("Debug count: " & Debug.Count'Image);
--          end if;
--
--          --  Options return Functional.Option
--          Put_Line ("Output: " & Output.Value_Or ("stdout"));
--          Put_Line ("Format: " & Format.Value_Or ("text"));
--
--          --  Positionals
--          if Files.Has_Values then
--             Put_Line ("Processing " & Files.Count'Image & " files");
--          end if;
--       else
--          Put_Line ("Error: " & CLI.Parse_Result.Error (Result).Message);
--       end if;
--    end Current_API_Example;


--  ============================================================================
--  NEW API: Clara.Static (SPARK-Provable)
--  ============================================================================
--
--  Pros:
--    - Fully SPARK-provable (no access types, no mutable state)
--    - Pure functional design (Parse is a pure function)
--    - Enumeration-indexed arrays prevent index errors
--    - Configuration is a first-class value (can be tested, serialized)
--
--  Cons:
--    - Must define enumerations upfront
--    - Slightly more verbose configuration
--    - Access via Results record, not package names
--
--  Example:

with Clara.Static;
with Ada.Text_IO; use Ada.Text_IO;

procedure API_Comparison is

   --  Step 1: Define enumerations for your CLI components
   type My_Flags is (Verbose, Debug);
   type My_Options is (Output, Format);
   type My_Positionals is (Files);

   --  Step 2: Instantiate Clara.Static with your enumerations
   package CLI is new Clara.Static
     (Flag_Names       => My_Flags,
      Option_Names     => My_Options,
      Positional_Names => My_Positionals,
      App_Name         => "myapp",
      App_Description  => "Example application");

   --  Step 3: Define configuration as a constant
   --  Note: Using the builder helpers (Flag, Opt, Pos) for cleaner syntax
   Config : constant CLI.CLI_Config :=
     (Flags =>
        [Verbose => CLI.Flag ('v', "verbose", "Enable verbose output"),
         Debug   => CLI.Flag ('d', "debug", "Enable debug mode")],

      Options =>
        [Output => CLI.Opt ('o', "output", "FILE", "Output file path"),
         Format => CLI.Opt ('f', "format", "FMT", "Output format")],

      Positionals =>
        [Files => CLI.Pos ("FILES", "Input files", Multiple => True)]);

   --  Step 4: Parse and handle results
   Result : CLI.Parse_Result.Result;

begin
   Result := CLI.Parse (Config);

   if CLI.Parse_Result.Is_Ok (Result) then
      declare
         R : constant CLI.Parse_Results := CLI.Parse_Result.Value (Result);
      begin
         --  Handle --help and --version
         if R.Help_Requested then
            Put_Line (CLI.Help_Text (Config));
            return;
         end if;

         if R.Version_Requested then
            Put_Line (CLI.Version_Text);
            return;
         end if;

         --  Access via enumeration index - still type-safe!
         if CLI.Is_Set (R, Verbose) then
            Put_Line ("Verbose mode enabled");
         end if;

         if CLI.Is_Set (R, Debug) then
            Put_Line ("Debug count: " & CLI.Flag_Count (R, Debug)'Image);
         end if;

         --  Options - using convenience functions
         declare
            Out_Val : constant Clara.Types.Value_String :=
              CLI.Get_Option_Or (R, Output, "stdout");
            Fmt_Val : constant Clara.Types.Value_String :=
              CLI.Get_Option_Or (R, Format, "text");
         begin
            Put_Line ("Output: " &
                      Clara.Types.Value_Strings.To_String (Out_Val));
            Put_Line ("Format: " &
                      Clara.Types.Value_Strings.To_String (Fmt_Val));
         end;

         --  Positionals
         if CLI.Has_Positional (R, Files) then
            Put_Line ("Processing " &
                      CLI.Positional_Count (R, Files)'Image & " files");
         end if;
      end;
   else
      declare
         Err : constant Clara.Errors.Parse_Error :=
           CLI.Parse_Result.Error (Result);
      begin
         Put_Line ("Error: " &
                   Clara.Types.Message_Strings.To_String (Err.Message));
      end;
   end if;
end API_Comparison;


--  ============================================================================
--  COMPARISON SUMMARY
--  ============================================================================
--
--  | Aspect              | Clara.Application      | Clara.Static           |
--  |---------------------|------------------------|------------------------|
--  | SPARK Provable      | No (access types)      | Yes                    |
--  | Definition Style    | Nested packages        | Enum + record          |
--  | Access Pattern      | Package.Is_Set         | Is_Set(Results, Enum)  |
--  | Configuration       | Implicit (elaboration) | Explicit (value)       |
--  | Type Safety         | Per-package            | Per-enumeration        |
--  | Lines of Code       | ~20 for definition     | ~25 for definition     |
--  | Runtime Overhead    | Registration + lookup  | Direct array index     |
--  | Testability         | Harder (pkg state)     | Easy (pure function)   |
--
--  RECOMMENDATION:
--    - For SPARK-required projects: Use Clara.Static
--    - For maximum ergonomics: Use Clara.Application
--    - For new projects: Prefer Clara.Static (future-proof)
--
--  ============================================================================
