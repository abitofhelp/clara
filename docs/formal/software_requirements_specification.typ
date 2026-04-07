// ============================================================================
// File: software_requirements_specification.typ
// Purpose: Software Requirements Specification for the CLARA library.
// Scope: Project-specific SRS content plus invocation of shared formal-document
//   functionality from core.typ.
// Usage: This is an authoritative Typst source document. The generated PDF is
//   the distribution artifact.
// Modification Policy:
//   - Edit this file for project-specific SRS content.
//   - Keep shared presentation logic in core.typ.
// SPDX-License-Identifier: BSD-3-Clause
// ============================================================================

#import "core.typ": change_history_table, formal_doc

#let doc = (
  authors: ("Michael Gardner",),
  copyright: "© 2025 Michael Gardner, A Bit of Help, Inc.",
  license_file: "See the LICENSE file in the project root",
  project_name: "CLARA",
  spdx_license: "BSD-3-Clause",
  status: "Draft",
  status_date: "2025-12-29",
  title: "Software Requirements Specification",
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
    changes: "Initial requirements from design discussion. Migrate to Typst format.",
  ),
)

#show: formal_doc.with(doc, profile, change_history)

= Introduction

== Purpose

This Software Requirements Specification (SRS) defines the functional and non-functional requirements for *CLARA* (Command Line Arguments for Reliable Applications), a type-safe command-line argument parsing library for Ada 2022.

== Scope

*CLARA* provides:

- Type-safe CLI argument definition via generic instantiation.
- Integration with the Functional library's Result and Option monads.
- Railway-oriented argument processing.
- SPARK-compatible design (no heap allocation).
- Stateless parsing via Ada.Command_Line.

== Definitions and Acronyms

#table(
  columns: (auto, 1fr),
  table.header([*Term*], [*Definition*]),
  [CLARA], [Command Line Arguments for Reliable Applications.],
  [Flag], [Boolean switch (e.g., `-v`, `--verbose`).],
  [Option], [Switch with a value (e.g., `-o file`, `--output=file`).],
  [Positional], [Non-switch arguments (e.g., file paths).],
  [Result Monad], [Functional pattern for error handling without exceptions.],
  [Option Monad], [Functional pattern for optional values.],
  [Generic Instantiation], [Ada compile-time polymorphism mechanism.],
)

== References

- Ada 2022 Reference Manual (ISO/IEC 8652:2023).
- SPARK 2014 Reference Manual.
- Functional Library — Result/Option monads.

= Overall Description

== Product Perspective

*CLARA* is a utility library designed to be imported by Ada applications needing command-line argument parsing. It follows the same generic instantiation pattern as the Functional library.

#table(
  columns: (1fr,),
  align: center + horizon,
  inset: 10pt,
  stroke: 0.8pt,
  [
    *Client Application* \
    `package My_CLI is new Clara.Application (...);` \
    `package Verbose is new My_CLI.Flag (...);` \
    `Result := My_CLI.Parse;`
  ],
  [*↓*],
  [
    *CLARA* \
    Clara.Application (generic) \
    Flag | Option | Positional (child generics) \
    Uses: Ada.Command_Line, Functional.Result/Option
  ],
)

== Product Features

1. *Flag Definition*: Boolean switches with short/long forms.
2. *Option Definition*: Switches with required/optional values.
3. *Positional Arguments*: File paths and other non-switch arguments.
4. *Type-Safe Access*: Each flag/option is its own package (no string lookups).
5. *Functional Integration*: Parse returns Result; options return Option.
6. *Help Generation*: Automatic help text from definitions.
7. *SPARK Compatible*: No heap allocation, stateless design.

== User Classes

#table(
  columns: (auto, 1fr),
  table.header([*User Class*], [*Description*]),
  [Application Developers], [Ada developers building CLI applications.],
  [Embedded Developers], [Developers requiring heap-free, SPARK-compatible patterns.],
  [Library Authors], [Developers creating tools with CLI interfaces.],
)

== Operating Environment

#table(
  columns: (auto, 1fr),
  table.header([*Requirement*], [*Specification*]),
  [Platforms], [#profile.platform.join(", ")],
  [Execution Environment], [#profile.execution_environment.join(", ")],
  [Processor Architecture], [#profile.processor_architecture.join(", ")],
  [Ada Version], [Ada 2022],
  [Compiler], [GNAT FSF 13+ or GNAT Pro],
  [Dependencies], [Functional >= 4.0.0],
)

== Constraints

#table(
  columns: (auto, 1fr),
  table.header([*Constraint*], [*Rationale*]),
  [No Heap Allocation], [SPARK compatibility and embedded system safety.],
  [Stateless Parsing], [Avoids GNAT.Command_Line state isolation issues in standalone libraries.],
  [Generic Instantiation], [Compile-time type safety, consistent with Functional library.],
  [No String Lookups], [Typos caught at compile time, not runtime.],
)

= Interface Requirements

== User Interfaces

None. This is a library, not an application.

== Software Interfaces

The library exposes a stable Ada API via generic instantiation:

```ada
with Clara.Application;

package My_CLI is new Clara.Application
  (Name => "myapp", Description => "My application");

package Verbose is new My_CLI.Flag
  (Short => 'v', Long => "verbose", Help => "Enable verbose output");

package Output is new My_CLI.Option
  (Short => 'o', Long => "output", Value_Name => "FILE",
   Help => "Output file path");
```

== Hardware Interfaces

None. The library is hardware-agnostic.

= Functional Requirements

== Application Definition (REQ-APP)

*Priority:* Must
*Description:* Provide a generic package for defining CLI applications.

#table(
  columns: (auto, 1fr, auto),
  table.header([*ID*], [*Requirement*], [*Priority*]),
  [REQ-APP-001], [Provide Clara.Application generic for CLI definition.], [Must],
  [REQ-APP-002], [Application shall have name and description parameters.], [Must],
  [REQ-APP-003], [Application shall provide Parse function returning Result.], [Must],
  [REQ-APP-004], [Application shall provide Print_Help procedure.], [Must],
)

== Flag Definition (REQ-FLAG)

*Priority:* Must
*Description:* Provide boolean switch arguments.

#table(
  columns: (auto, 1fr, auto),
  table.header([*ID*], [*Requirement*], [*Priority*]),
  [REQ-FLAG-001], [Provide Flag child generic of Application.], [Must],
  [REQ-FLAG-002], [Flag shall support short form (single character, e.g., `-v`).], [Must],
  [REQ-FLAG-003], [Flag shall support long form (e.g., `--verbose`).], [Must],
  [REQ-FLAG-004], [Flag shall support help text parameter.], [Must],
  [REQ-FLAG-005], [Flag shall provide Is_Set function returning Boolean.], [Must],
  [REQ-FLAG-006], [Flag shall provide Count function for multiple occurrences.], [Should],
)

== Option Definition (REQ-OPT)

*Priority:* Must
*Description:* Provide switches with associated values.

#table(
  columns: (auto, 1fr, auto),
  table.header([*ID*], [*Requirement*], [*Priority*]),
  [REQ-OPT-001], [Provide Option child generic of Application.], [Must],
  [REQ-OPT-002], [Option shall support short form with value (e.g., `-o file`).], [Must],
  [REQ-OPT-003], [Option shall support long form with value (e.g., `--output=file`).], [Must],
  [REQ-OPT-004], [Option shall support value name for help text (e.g., "FILE").], [Must],
  [REQ-OPT-005], [Option shall provide Value function returning Option\[String\].], [Must],
  [REQ-OPT-006], [Option shall provide Has_Value function returning Boolean.], [Must],
  [REQ-OPT-007], [Option shall support "or" operator for default values.], [Must],
)

== Positional Arguments (REQ-POS)

*Priority:* Must
*Description:* Provide non-switch argument handling.

#table(
  columns: (auto, 1fr, auto),
  table.header([*ID*], [*Requirement*], [*Priority*]),
  [REQ-POS-001], [Provide Positional child generic of Application.], [Must],
  [REQ-POS-002], [Positional shall support name and help text.], [Must],
  [REQ-POS-003], [Positional shall support Multiple flag for 0..N values.], [Must],
  [REQ-POS-004], [Positional shall provide Values function returning a bounded vector.], [Must],
)

== Error Handling (REQ-ERR)

*Priority:* Must
*Description:* Provide Result-based parse error reporting.

#table(
  columns: (auto, 1fr, auto),
  table.header([*ID*], [*Requirement*], [*Priority*]),
  [REQ-ERR-001], [Parse shall return Result\[Unit, Parse_Error\].], [Must],
  [REQ-ERR-002], [Parse_Error shall include error kind and message.], [Must],
  [REQ-ERR-003], [Error kinds shall include: Unknown_Switch, Missing_Value, Invalid_Value.], [Must],
  [REQ-ERR-004], [Errors shall be composable with And_Then and Map_Error.], [Must],
)

== Help Generation (REQ-HELP)

*Priority:* Must
*Description:* Provide automatic help text generation from definitions.

#table(
  columns: (auto, 1fr, auto),
  table.header([*ID*], [*Requirement*], [*Priority*]),
  [REQ-HELP-001], [Generate help text from argument definitions.], [Must],
  [REQ-HELP-002], [Help shall show application name and description.], [Must],
  [REQ-HELP-003], [Help shall list all flags with short/long forms and help text.], [Must],
  [REQ-HELP-004], [Help shall list all options with value names.], [Must],
  [REQ-HELP-005], [Help shall list positional arguments.], [Must],
)

== Future: Subcommand Support (REQ-CMD)

*Priority:* Future
*Description:* Support subcommands (e.g., `app cmd --flag`).

#table(
  columns: (auto, 1fr, auto),
  table.header([*ID*], [*Requirement*], [*Priority*]),
  [REQ-CMD-001], [Support subcommands with their own flags and options.], [Future],
  [REQ-CMD-002], [Application shall route to the appropriate subcommand.], [Future],
)

= Quality and Cross-Cutting Requirements

== Performance (NFR-PERF)

#table(
  columns: (auto, 1fr),
  table.header([*ID*], [*Requirement*]),
  [NFR-PERF-001], [Parsing shall complete in O(n) where n is the argument count.],
  [NFR-PERF-002], [No dynamic memory allocation during parsing.],
)

== Portability (NFR-PORT)

#table(
  columns: (auto, 1fr),
  table.header([*ID*], [*Requirement*]),
  [NFR-PORT-001], [The library shall work on POSIX and Windows platforms.],
  [NFR-PORT-002], [The library shall use only Ada.Command_Line (standard library).],
  [NFR-PORT-003], [No GNAT-specific runtime dependencies.],
)

== SPARK Formal Verification (NFR-SPARK)

#table(
  columns: (auto, 1fr),
  table.header([*ID*], [*Requirement*]),
  [NFR-SPARK-001], [Core packages shall be SPARK_Mode On compatible.],
  [NFR-SPARK-002], [No controlled types in core packages.],
  [NFR-SPARK-003], [Use bounded data structures only.],
)

#table(
  columns: (auto, auto, 1fr),
  table.header([*Package*], [*SPARK_Mode*], [*Rationale*]),
  [Clara], [On], [Root package, pure.],
  [Clara.Types], [On], [Core type definitions, bounded strings.],
  [Clara.Errors], [On], [Error types, pure.],
  [Clara.Version], [On], [Constants only.],
  [Clara.Application (core)], [On], [Generic parsing logic.],
)

== Maintainability (NFR-MAINT)

#table(
  columns: (auto, 1fr),
  table.header([*ID*], [*Requirement*]),
  [NFR-MAINT-001], [Code coverage shall be at least 90%.],
  [NFR-MAINT-002], [All public APIs shall be documented.],
  [NFR-MAINT-003], [Design shall be consistent with Functional library patterns.],
)

= Design and Implementation Constraints

== System Requirements

=== Hardware Requirements

No specific hardware requirements. The library operates within standard Ada runtime constraints.

=== Software Requirements

#table(
  columns: (auto, 1fr),
  table.header([*Category*], [*Requirement*]),
  [Compiler], [GNAT FSF 13+ or GNAT Pro (Ada 2022 support).],
  [Package Manager], [Alire 2.0+.],
  [Dependencies], [Functional >= 4.0.0.],
  [SPARK Prover], [GNATprove 14+ (optional, for formal verification).],
)

= Verification and Traceability

== Verification Methods

#table(
  columns: (auto, 1fr),
  table.header([*Method*], [*Description*]),
  [Unit Testing], [Individual packages: Types, Errors, Flag, Option, Positional.],
  [Integration Testing], [Full parsing with multiple argument combinations.],
  [SPARK Proof], [Formal verification of core packages.],
  [Code Review], [All changes reviewed before merge.],
)

== Traceability Matrix

#table(
  columns: (auto, 1fr, 1fr),
  table.header([*Requirement*], [*Design*], [*Test*]),
  [REQ-APP-001], [Clara.Application], [TC-INT-001..006],
  [REQ-FLAG-001], [Clara.Application.Flag], [TC-FLAG-001..005],
  [REQ-OPT-001], [Clara.Application.Option], [TC-OPT-001..006],
  [REQ-POS-001], [Clara.Application.Positional], [TC-POS-001..005],
  [REQ-ERR-001], [Clara.Errors], [TC-ERR-001..004],
  [REQ-HELP-001], [Clara.Application.Print_Help], [TC-HELP-001..004],
)
