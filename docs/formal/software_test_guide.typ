// ============================================================================
// File: software_test_guide.typ
// Purpose: Software Test Guide for the CLARA library.
// Scope: Project-specific STG content plus invocation of shared formal-document
//   functionality from core.typ.
// Usage: This is an authoritative Typst source document. The generated PDF is
//   the distribution artifact.
// Modification Policy:
//   - Edit this file for project-specific STG content.
//   - Keep shared presentation logic in core.typ.
// Table Ordering:
//   Sort any table whose rows a reader might scan to locate a specific
//   entry — definitions, acronyms, constraints, packages, interfaces,
//   and similar reference tables.  Sort alphabetically by the first
//   column.  Tables with an inherent sequence (requirement IDs within
//   a section, change history, workflow steps) retain their logical order.
// SPDX-License-Identifier: BSD-3-Clause
// ============================================================================

#import "core.typ": formal_doc

#let doc = (
  title: "Software Test Guide",
  project_name: "CLARA",
  authors: ("Michael Gardner",),
  version: "0.1.0",
  applies_to: "^1.0",
  status: "Draft",
  status_date: "2026-04-26",
  spdx_license: "BSD-3-Clause",
  license_file: "See the LICENSE file in the project root",
  copyright: "© 2026 Michael Gardner, A Bit of Help, Inc.",
)

#let profile = (
  variant: "library",
  library_role: "utility",
  app_role: none,
  assurance: "spark-targeted",
  execution: "sequential",
  parallelism: "none",
  platform: ("desktop", "server", "embedded"),
  execution_environment: ("linux", "macos", "windows", "ada-runtime"),
  processor_architecture: ("amd64", "arm64", "arm32"),
  deployment: "native",
)

#let change_history = (
  (
    version: "0.1.0",
    date: "2025-12-19",
    author: "Michael Gardner",
    changes: "Initial test strategy. Migrate to Typst format.",
  ),
)

#show: formal_doc.with(doc, profile, change_history)

= Introduction

== Purpose

This Software Test Guide (STG) defines the testing strategy, test cases, and verification approach for *CLARA* (Command Line Arguments for Reliable Applications), a type-safe command-line argument parsing library for Ada 2022.

== Scope

This document covers:
- test strategy and approach,
- unit test specifications,
- integration test specifications,
- SPARK verification,
- coverage requirements, and
- traceability.

== References

- Software Requirements Specification (SRS).
- Software Design Specification (SDS).

= Test Strategy

== Test Categories

#table(
  columns: (auto, auto, 1fr, auto),
  table.header([*Category*], [*Location*], [*Purpose*], [*Target*]),
  [Unit Tests], [`test/unit/`], [Verify individual packages.], [≥ 90% line],
  [Integration Tests], [`test/integration/`], [Verify full parse scenarios.], [Key workflows],
  [SPARK Tests], [`test/spark/`], [Formal verification.], [100% proof],
)

== Testing Philosophy

- Test behavior, not implementation.
- Each test validates one logical concept.
- Use descriptive test names.
- No mocking — test against real Ada.Command_Line behavior.
- SPARK verification complements dynamic testing.

== Coverage Requirements

// Sort rows alphabetically by the first column.
#table(
  columns: (auto, auto),
  table.header([*Metric*], [*Target*]),
  [Branch Coverage], [≥ 85%],
  [Line Coverage], [≥ 90%],
  [MC/DC Coverage], [≥ 80% (SPARK packages)],
)

= Test Organization

== Directory Structure

```text
test/
├── common/               # Shared test framework
│   ├── test_framework.ads
│   └── test_framework.adb
├── unit/                 # Unit tests
│   ├── unit_tests.gpr
│   ├── unit_runner.adb
│   ├── test_flag.adb
│   ├── test_option.adb
│   └── test_positional.adb
├── integration/          # Integration tests
│   ├── integration_tests.gpr
│   └── test_full_parse.adb
└── spark/                # SPARK instantiation tests
    └── spark_instantiations.ads
```

== Build/Test Projects

// Sort rows alphabetically by the first column.
#table(
  columns: (auto, 1fr),
  table.header([*Project*], [*Purpose*]),
  [`test/integration/integration_tests.gpr`], [Builds integration test executables.],
  [`test/unit/unit_tests.gpr`], [Builds unit test executables.],
)

= Test Execution

== Running All Tests

```bash
make test-all
```

== Running Specific Suites

```bash
make test-unit
make test-integration
make spark-prove
```

= Test Details

== Unit Tests

=== Flag Tests

#table(
  columns: (auto, 1fr, 1fr),
  table.header([*Test Case*], [*Description*], [*Expected Result*]),
  [TC-FLAG-001], [Flag not present.], [Is_Set returns False, Count = 0.],
  [TC-FLAG-002], [Short flag present (`-v`).], [Is_Set returns True, Count = 1.],
  [TC-FLAG-003], [Long flag present (`--verbose`).], [Is_Set returns True, Count = 1.],
  [TC-FLAG-004], [Multiple short flags (`-vvv`).], [Count = 3.],
  [TC-FLAG-005], [Combined short flags (`-vh`).], [Both flags set.],
)

=== Option Tests

#table(
  columns: (auto, 1fr, 1fr),
  table.header([*Test Case*], [*Description*], [*Expected Result*]),
  [TC-OPT-001], [Option not present.], [Has_Value False, Value returns None.],
  [TC-OPT-002], [Short option with space (`-o file`).], [Value = "file".],
  [TC-OPT-003], [Long option with equals (`--output=file`).], [Value = "file".],
  [TC-OPT-004], [Long option with space (`--output file`).], [Value = "file".],
  [TC-OPT-005], [Option with "or" default.], [Returns default when None.],
  [TC-OPT-006], [Required option missing.], [Parse returns Error.],
)

=== Positional Tests

#table(
  columns: (auto, 1fr, 1fr),
  table.header([*Test Case*], [*Description*], [*Expected Result*]),
  [TC-POS-001], [No positional arguments.], [Values is empty.],
  [TC-POS-002], [Single positional argument.], [Values contains 1 element.],
  [TC-POS-003], [Multiple positional arguments.], [Values contains all elements.],
  [TC-POS-004], [Positional after flags.], [Correctly separated.],
  [TC-POS-005], [Positional with `--` separator.], [Arguments after `--` are positional.],
)

=== Parse Error Tests

#table(
  columns: (auto, 1fr, 1fr),
  table.header([*Test Case*], [*Description*], [*Expected Result*]),
  [TC-ERR-001], [Unknown switch.], [Error with Unknown_Switch kind.],
  [TC-ERR-002], [Missing option value.], [Error with Missing_Value kind.],
  [TC-ERR-003], [Valid parse.], [Ok(Unit) returned.],
  [TC-ERR-004], [Help flag (`--help`).], [Error with Help_Requested kind.],
)

=== Help Generation Tests

#table(
  columns: (auto, 1fr, 1fr),
  table.header([*Test Case*], [*Description*], [*Expected Result*]),
  [TC-HELP-001], [Help contains application name.], [Name appears in output.],
  [TC-HELP-002], [Help contains description.], [Description appears.],
  [TC-HELP-003], [Help lists all flags.], [All flags shown with help text.],
  [TC-HELP-004], [Help lists all options.], [All options shown with value names.],
)

== Integration Tests

=== Full Parse Scenarios

#table(
  columns: (auto, 1fr, 1fr),
  table.header([*Test Case*], [*Command Line*], [*Expected Result*]),
  [TC-INT-001], [`app`], [No flags set, no positionals.],
  [TC-INT-002], [`app -v file.txt`], [Verbose set, 1 positional.],
  [TC-INT-003], [`app --output=out.txt file1 file2`], [Output = "out.txt", 2 positionals.],
  [TC-INT-004], [`app -vh --output file.txt input.ada`], [Multiple flags, option, positional.],
  [TC-INT-005], [`app --help`], [Help_Requested error (graceful exit).],
  [TC-INT-006], [`app --unknown`], [Unknown_Switch error.],
)

=== Edge Cases

#table(
  columns: (auto, 1fr, 1fr),
  table.header([*Test Case*], [*Description*], [*Expected Result*]),
  [TC-EDGE-001], [Empty string argument.], [Handled gracefully.],
  [TC-EDGE-002], [Argument with spaces (quoted).], [Preserved correctly.],
  [TC-EDGE-003], [Very long argument.], [Within bounds or error.],
  [TC-EDGE-004], [Unicode in arguments.], [Handled correctly.],
  [TC-EDGE-005], [Argument starting with `-` after `--`.], [Treated as positional.],
)

== SPARK Verification

=== Packages Under SPARK

// Sort rows alphabetically by the first column.
#table(
  columns: (auto, auto, 1fr),
  table.header([*Package*], [*SPARK_Mode*], [*Proof Level*]),
  [Clara], [On], [Full.],
  [Clara.Application (core)], [On], [Full.],
  [Clara.Errors], [On], [Full.],
  [Clara.Types], [On], [Full.],
  [Clara.Version], [On], [Full.],
)

=== Proof Objectives

// Sort rows alphabetically by the first column.
#table(
  columns: (auto, 1fr),
  table.header([*Objective*], [*Verification*]),
  [Array bounds], [Index checks proven.],
  [Bounded string access], [Range checks proven.],
  [No runtime errors], [GNATprove level 2.],
  [No uninitialized reads], [Flow analysis.],
)

= Traceability

== Requirements to Tests

#table(
  columns: (auto, 1fr),
  table.header([*Requirement*], [*Test Coverage*]),
  [REQ-APP-001..004], [TC-INT-001..006],
  [REQ-FLAG-001..006], [TC-FLAG-001..005],
  [REQ-OPT-001..007], [TC-OPT-001..006],
  [REQ-POS-001..004], [TC-POS-001..005],
  [REQ-ERR-001..004], [TC-ERR-001..004],
  [REQ-HELP-001..005], [TC-HELP-001..004],
)

= Test Maintenance

== When to Update

- Add tests when new argument types or features are introduced.
- Add regression tests when defects are fixed.
- Update tests when parsing behavior changes.
- Revise SPARK expectations when verification scope evolves.

== Quality Guidelines

- Each public operation should have at least one test.
- Test both valid and invalid inputs.
- Test edge cases (empty, boundary values, long strings).
- Keep tests independent (no shared mutable state).

== Continuous Integration

Tests run automatically on pull request creation, push to main, and release tag creation.
