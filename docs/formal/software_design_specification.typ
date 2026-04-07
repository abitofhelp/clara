// ============================================================================
// File: software_design_specification.typ
// Purpose: Software Design Specification for the CLARA library.
// Scope: Project-specific SDS content plus invocation of shared formal-document
//   functionality from core.typ.
// Usage: This is an authoritative Typst source document. The generated PDF is
//   the distribution artifact.
// Modification Policy:
//   - Edit this file for project-specific SDS content.
//   - Keep shared presentation logic in core.typ.
// SPDX-License-Identifier: BSD-3-Clause
// ============================================================================

#import "core.typ": formal_doc, change_history_table

#let doc = (
  authors: ("Michael Gardner",),
  copyright: "© 2025 Michael Gardner, A Bit of Help, Inc.",
  license_file: "See the LICENSE file in the project root",
  project_name: "CLARA",
  spdx_license: "BSD-3-Clause",
  status: "Draft",
  status_date: "2025-12-29",
  title: "Software Design Specification",
  version: "0.1.0",
)

#let profile = (
  app_role: none,
  assurance: "spark-targeted",
  deployment: "native",
  execution: "sequential",
  execution_environment: ("linux", "macos", "windows", "ada-runtime"),
  library_role: "utility",
  parallelism: "none",
  platform: ("desktop", "server", "embedded"),
  processor_architecture: ("amd64", "arm64", "arm32"),
  variant: "library",
)

#let change_history = (
  (
    version: "0.1.0",
    date: "2025-12-19",
    author: "Michael Gardner",
    changes: "Initial design from discussion. Migrate to Typst format.",
  ),
)

#show: formal_doc.with(doc, profile, change_history)

= Introduction

== Purpose

This Software Design Specification (SDS) documents the architectural and detailed design decisions for *CLARA* (Command Line Arguments for Reliable Applications), a type-safe command-line argument parsing library for Ada 2022.

== Scope

This document covers:
- package architecture and hierarchy,
- generic instantiation design pattern,
- integration with the Functional library,
- parsing backend design,
- data structures, and
- key design decisions and rationale.

== References

- Software Requirements Specification (SRS).
- Ada 2022 Reference Manual (ISO/IEC 8652:2023).
- Functional Library — Result/Option monads.

= Architectural Overview

== Architecture Style

*CLARA* is a flat utility library organized by module. It is not a layered DDD/Clean/Hexagonal project. The primary structural concern is the *generic hierarchy*: `Clara.Application` is the root generic, with `Flag`, `Option`, and `Positional` as child generics.

== Package Hierarchy

```text
Clara (root package)
├── Clara.Version             -- Library version information
├── Clara.Types               -- Core type definitions (bounded strings)
├── Clara.Errors              -- Parse error types
└── Clara.Application         -- Generic CLI application definition
    ├── Clara.Application.Flag       -- Child generic for boolean flags
    ├── Clara.Application.Option     -- Child generic for value options
    └── Clara.Application.Positional -- Child generic for positional args
```

== Design Pattern: Generic Instantiation

CLARA uses Ada generic instantiation rather than a builder pattern. This is consistent with the Functional library and provides compile-time type safety.

#table(
  columns: (auto, 1fr, 1fr),
  table.header([*Aspect*], [*Builder Pattern*], [*Generic Instantiation*]),
  [Type Safety], [Runtime (string lookups)], [Compile-time (packages)],
  [Error Detection], [Runtime errors], [Compile-time errors],
  [SPARK Compatibility], [Poor (heap allocation)], [Good (no heap)],
  [Ada Idiom], [Borrowed from OOP], [Native Ada pattern],
  [Consistency], [Different from Functional], [Same as Functional],
)

== Integration with Functional Library

#table(
  columns: (auto, 1fr, 1fr),
  table.header([*CLARA Operation*], [*Functional Type*], [*Purpose*]),
  [`Parse`], [`Result[Unit, Parse_Error]`], [Parse success/failure.],
  [`Option.Value`], [`Option[String]`], [Optional argument value.],
  [`"or"` operator], [From Option], [Default values.],
  [`And_Then`, `Map_Error`], [From Result], [Railway-oriented chaining.],
)

Usage example:

```ada
My_CLI.Parse
   .And_Then (Validate_Args'Access)
   .And_Then (Build_Config'Access)
   .Map_Error (To_User_Error'Access);

Output_Path : constant String := Output.Value or "./default.txt";
```

= Package Structure

== Clara (Root Package)

```ada
package Clara with Pure is
   Library_Name : constant String := "CLARA";
end Clara;
```

== Clara.Types

Core type definitions with SPARK-compatible bounds:

```ada
package Clara.Types with Pure is
   Max_Short_Length : constant := 1;
   Max_Long_Length  : constant := 64;
   Max_Help_Length  : constant := 256;
   Max_Value_Length : constant := 1024;

   subtype Short_String is String (1 .. Max_Short_Length);
   subtype Long_String is String (1 .. Max_Long_Length);
   subtype Help_String is String (1 .. Max_Help_Length);
   subtype Value_String is String (1 .. Max_Value_Length);
end Clara.Types;
```

== Clara.Errors

Parse error types compatible with Functional.Result:

```ada
package Clara.Errors with Pure is
   type Error_Kind is
     (Unknown_Switch,
      Missing_Value,
      Invalid_Value,
      Duplicate_Switch,
      Help_Requested);

   type Parse_Error is record
      Kind    : Error_Kind;
      Message : Bounded_String;
      Context : Bounded_String;
   end record;
end Clara.Errors;
```

== Clara.Application (Generic)

The main generic package for defining a CLI application:

```ada
generic
   Name        : String;
   Description : String;
package Clara.Application is
   function Parse return Parse_Result.Result;
   procedure Print_Help;

   generic
      Short : Character := ASCII.NUL;
      Long  : String;
      Help  : String;
   package Flag is
      function Is_Set return Boolean;
      function Count return Natural;
   end Flag;

   generic
      Short      : Character := ASCII.NUL;
      Long       : String;
      Value_Name : String;
      Help       : String;
      Required   : Boolean := False;
   package Option is
      function Has_Value return Boolean;
      function Value return String_Option.Option;
   end Option;

   generic
      Name     : String;
      Help     : String;
      Multiple : Boolean := False;
   package Positional is
      function Values return String_Vector;
      function Is_Empty return Boolean;
   end Positional;
end Clara.Application;
```

= Data Structures

== Internal Argument Registry

During parsing, CLARA tracks registered arguments:

```ada
type Argument_Kind is (Flag_Kind, Option_Kind, Positional_Kind);

type Argument_Def is record
   Kind       : Argument_Kind;
   Short      : Character;
   Long       : Bounded_String;
   Help       : Bounded_String;
   Value_Name : Bounded_String;
   Required   : Boolean;
   Multiple   : Boolean;
end record;
```

== Parse State

After parsing, each argument stores its result:

```ada
type Flag_State is record
   Is_Set : Boolean := False;
   Count  : Natural := 0;
end record;

type Option_State is record
   Has_Value : Boolean := False;
   Value     : Bounded_String;
end record;

type Positional_State is record
   Values : String_Vector;
end record;
```

= Component Design

== Parsing Algorithm

```text
FOR i IN 1 .. Argument_Count LOOP
  arg := Argument(i)

  IF arg starts with "--" THEN
    IF arg contains "=" THEN
      (name, value) := split on "="
      Store option value
    ELSE
      Find flag/option with matching Long name
      IF option requiring value THEN
        value := next argument
      END IF
    END IF
  ELSIF arg starts with "-" THEN
    FOR each char in arg[2..] LOOP
      Find flag/option with matching Short character
    END LOOP
  ELSE
    Add to positional arguments
  END IF
END LOOP
```

== Help Generation

```text
Print: Name " - " Description
Print: "Usage: " Name " [OPTIONS] " positional_names
Print: "Options:"
  FOR each flag/option: print short, long, help
Print: "Arguments:"
  FOR each positional: print name, help
```

= Design Patterns

== Parsing Backend: Ada.Command_Line

*Decision:* Use `Ada.Command_Line` instead of `GNAT.Command_Line`.

#table(
  columns: (auto, 1fr, 1fr),
  table.header([*Aspect*], [*GNAT.Command_Line*], [*Ada.Command_Line*]),
  [State], [Mutable, elaboration-time], [Stateless],
  [Standalone Libraries], [State isolation issues on macOS], [Works correctly],
  [Standard], [GNAT-specific], [Standard Ada],
  [SPARK], [Not compatible], [Compatible],
)

*Issue encountered:* `GNAT.Command_Line` with `Library_Standalone use "standard"` causes command-line state to be isolated in a separate elaboration context on macOS. Arguments are not visible to code inside standalone libraries.

*Solution:* Use `Ada.Command_Line.Argument_Count` and `Ada.Command_Line.Argument(N)` directly. These are stateless calls that work correctly in any library configuration.

== Error Handling Pattern

Parse returns `Result[Unit, Parse_Error]`, integrating with the Functional library's railway-oriented programming model. Consumers chain parse results with `And_Then` and `Map_Error` without manual error checking.

= Performance and Memory Design

== Zero-Overhead Abstractions

- Bounded strings for all internal storage (no heap).
- O(n) parsing complexity where n is the argument count.
- Static dispatch via generics (no tagged types).

== Memory Management

- All data structures are bounded and stack-allocated.
- No controlled types in core packages.
- Suitable for embedded and memory-constrained environments.

= SPARK Readiness Assessment

== Module Assessment

#table(
  columns: (auto, auto, 1fr),
  table.header([*Package*], [*SPARK*], [*Notes*]),
  [Clara], [On], [Root package, pure.],
  [Clara.Types], [On], [Bounded type definitions.],
  [Clara.Errors], [On], [Error type definitions.],
  [Clara.Version], [On], [Constants only.],
  [Clara.Application (core)], [On], [Generic parsing logic.],
)

= Future Extensibility

== Subcommand Support

The generic hierarchy naturally accommodates future subcommand support:

```ada
package My_CLI is new Clara.Application ("git", "Version control");
package Commit is new My_CLI.Command ("commit", "Record changes");
package Message is new Commit.Option ('m', "message", "MSG", "...");
```

`Command` would become a child generic of `Application`, with `Flag`, `Option`, and `Positional` as child generics of `Command`.

== Extension Points

#table(
  columns: (auto, 1fr),
  table.header([*Extension*], [*Mechanism*]),
  [Custom validators], [Generic formal function parameter.],
  [Value transformers], [Generic formal function parameter.],
  [Help formatters], [Abstract interface + implementations.],
  [Shell completions], [Additional generic procedures.],
)

= Design Decisions

#table(
  columns: (auto, 1fr, 1fr),
  table.header([*ID*], [*Decision*], [*Rationale*]),
  [DD-001], [Generic instantiation over builder pattern.], [Compile-time type safety, SPARK compatible, consistent with Functional.],
  [DD-002], [Ada.Command_Line over GNAT.Command_Line.], [Stateless, no isolation issues in standalone libraries.],
  [DD-003], [Depend on Functional library.], [Reuse Result/Option, railway-oriented processing.],
  [DD-004], [Child generics for Flag/Option/Positional.], [Type-safe access, compile-time error detection.],
  [DD-005], [Bounded strings for SPARK compatibility.], [No heap allocation, embedded-safe.],
)
