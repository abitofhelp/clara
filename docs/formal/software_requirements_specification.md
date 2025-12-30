# Software Requirements Specification (SRS)

**Project:** CLARA - Command Line Arguments for Reliable Applications
**Version:** 1.0.0<br>
**Date:** 2025-12-29<br>
**SPDX-License-Identifier:** BSD-3-Clause<br>
**License File:** See the LICENSE file in the project root<br>
**Copyright:** © 2025 Michael Gardner, A Bit of Help, Inc.<br>
**Status:** Released

---

## 1. Introduction

### 1.1 Purpose

This Software Requirements Specification (SRS) defines the functional and non-functional requirements for **CLARA**, a type-safe command-line argument parsing library for Ada 2022.

### 1.2 Scope

CLARA provides:
- Type-safe CLI argument definition via generic instantiation
- Integration with Functional library's Result and Option monads
- Railway-oriented argument processing
- SPARK-compatible design (no heap allocation)
- Stateless parsing via Ada.Command_Line

### 1.3 Definitions and Acronyms

| Term | Definition |
|------|------------|
| CLARA | Command Line Arguments for Reliable Applications |
| Flag | Boolean switch (e.g., `-v`, `--verbose`) |
| Option | Switch with value (e.g., `-o file`, `--output=file`) |
| Positional | Non-switch arguments (e.g., file paths) |
| Result Monad | Functional pattern for error handling without exceptions |
| Option Monad | Functional pattern for optional values |
| Generic Instantiation | Ada compile-time polymorphism mechanism |

### 1.4 References

- Ada 2022 Reference Manual (ISO/IEC 8652:2023)
- SPARK 2014 Reference Manual
- [Functional Library](https://github.com/abitofhelp/functional) - Result/Option monads
- [Clap](https://github.com/clap-rs/clap) - Rust CLI parser (design inspiration)

---

## 2. Overall Description

### 2.1 Product Perspective

CLARA is a utility library designed to be imported by Ada applications needing command-line argument parsing. It follows the same generic instantiation pattern as the Functional library.

```
┌─────────────────────────────────────────────────────────┐
│                   Client Application                     │
│                                                          │
│   package My_CLI is new Clara.Application (...);        │
│   package Verbose is new My_CLI.Flag (...);             │
│   Result := My_CLI.Parse;                               │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                        CLARA                             │
│                                                          │
│   Clara.Application (generic)                            │
│      ├── Clara.Flag (child generic)                     │
│      ├── Clara.Option (child generic)                   │
│      └── Clara.Positional (child generic)               │
│                                                          │
│   Uses: Ada.Command_Line, Functional.Result/Option      │
└─────────────────────────────────────────────────────────┘
```

### 2.2 Product Features

1. **Flag Definition**: Boolean switches with short/long forms
2. **Option Definition**: Switches with required/optional values
3. **Positional Arguments**: File paths and other non-switch args
4. **Type-Safe Access**: Each flag/option is its own package (no string lookups)
5. **Functional Integration**: Parse returns Result, options return Option
6. **Help Generation**: Automatic help text from definitions
7. **SPARK Compatible**: No heap allocation, stateless design

### 2.3 User Classes

| User Class | Description |
|------------|-------------|
| Application Developers | Ada developers building CLI applications |
| Embedded Developers | Requiring heap-free, SPARK-compatible patterns |
| Library Authors | Creating tools with CLI interfaces |

### 2.4 Operating Environment

| Requirement | Specification |
|-------------|---------------|
| Platforms | POSIX (Linux, macOS, BSD), Windows 11, Embedded |
| Ada Compiler | GNAT FSF 13+ or GNAT Pro |
| Ada Version | Ada 2022 |
| Dependencies | Functional >= 4.0.0 |

### 2.5 Design Constraints

| Constraint | Rationale |
|------------|-----------|
| No heap allocation | SPARK compatibility, embedded systems |
| Stateless parsing | Avoids GNAT.Command_Line state isolation in standalone libraries |
| Generic instantiation | Compile-time type safety, consistent with Functional library |
| No string lookups | Typos caught at compile time, not runtime |

---

## 3. Functional Requirements

### 3.1 Application Definition

| ID | Requirement | Priority |
|----|-------------|----------|
| REQ-APP-001 | System shall provide Clara.Application generic for CLI definition | Must |
| REQ-APP-002 | Application shall have name and description parameters | Must |
| REQ-APP-003 | Application shall provide Parse function returning Result | Must |
| REQ-APP-004 | Application shall provide Print_Help procedure | Must |

### 3.2 Flag Definition

| ID | Requirement | Priority |
|----|-------------|----------|
| REQ-FLAG-001 | System shall provide Flag child generic of Application | Must |
| REQ-FLAG-002 | Flag shall support short form (single character, e.g., `-v`) | Must |
| REQ-FLAG-003 | Flag shall support long form (e.g., `--verbose`) | Must |
| REQ-FLAG-004 | Flag shall support help text parameter | Must |
| REQ-FLAG-005 | Flag shall provide Is_Set function returning Boolean | Must |
| REQ-FLAG-006 | Flag shall provide Count function for multiple occurrences | Should |

### 3.3 Option Definition

| ID | Requirement | Priority |
|----|-------------|----------|
| REQ-OPT-001 | System shall provide Option child generic of Application | Must |
| REQ-OPT-002 | Option shall support short form with value (e.g., `-o file`) | Must |
| REQ-OPT-003 | Option shall support long form with value (e.g., `--output=file`) | Must |
| REQ-OPT-004 | Option shall support value name for help (e.g., "FILE") | Must |
| REQ-OPT-005 | Option shall provide Value function returning Option[String] | Must |
| REQ-OPT-006 | Option shall provide Has_Value function returning Boolean | Must |
| REQ-OPT-007 | Option shall support "or" operator for defaults | Must |

### 3.4 Positional Arguments

| ID | Requirement | Priority |
|----|-------------|----------|
| REQ-POS-001 | System shall provide Positional child generic of Application | Must |
| REQ-POS-002 | Positional shall support name and help text | Must |
| REQ-POS-003 | Positional shall support Multiple flag for 0..N values | Must |
| REQ-POS-004 | Positional shall provide Values function returning vector | Must |

### 3.5 Error Handling

| ID | Requirement | Priority |
|----|-------------|----------|
| REQ-ERR-001 | Parse shall return Result[Unit, Parse_Error] | Must |
| REQ-ERR-002 | Parse_Error shall include error kind and message | Must |
| REQ-ERR-003 | Error kinds shall include: Unknown_Switch, Missing_Value, Invalid_Value | Must |
| REQ-ERR-004 | Errors shall be composable with And_Then, Map_Error | Must |

### 3.6 Help Generation

| ID | Requirement | Priority |
|----|-------------|----------|
| REQ-HELP-001 | System shall generate help text from definitions | Must |
| REQ-HELP-002 | Help shall show application name and description | Must |
| REQ-HELP-003 | Help shall list all flags with short/long forms and help text | Must |
| REQ-HELP-004 | Help shall list all options with value names | Must |
| REQ-HELP-005 | Help shall list positional arguments | Must |

### 3.7 Future: Command Support

| ID | Requirement | Priority |
|----|-------------|----------|
| REQ-CMD-001 | System shall support subcommands (e.g., `app cmd --flag`) | Future |
| REQ-CMD-002 | Command shall have its own flags, options, positionals | Future |
| REQ-CMD-003 | Application shall route to appropriate command | Future |

---

## 4. Non-Functional Requirements

### 4.1 Performance

| ID | Requirement |
|----|-------------|
| NFR-PERF-001 | Parsing shall complete in O(n) where n = argument count |
| NFR-PERF-002 | No dynamic memory allocation during parsing |

### 4.2 Portability

| ID | Requirement |
|----|-------------|
| NFR-PORT-001 | Library shall work on POSIX and Windows |
| NFR-PORT-002 | Library shall use only Ada.Command_Line (standard library) |
| NFR-PORT-003 | No GNAT-specific runtime dependencies |

### 4.3 SPARK Compatibility

| ID | Requirement |
|----|-------------|
| NFR-SPARK-001 | Core packages shall be SPARK_Mode => On compatible |
| NFR-SPARK-002 | No controlled types in core packages |
| NFR-SPARK-003 | Bounded data structures only |

### 4.4 Maintainability

| ID | Requirement |
|----|-------------|
| NFR-MAINT-001 | Code coverage >= 90% |
| NFR-MAINT-002 | All public APIs documented |
| NFR-MAINT-003 | Consistent with Functional library patterns |

---

## 5. Traceability Matrix

| Requirement | SDS Section | Test Case |
|-------------|-------------|-----------|
| REQ-APP-001 | Clara.Application | TC-APP-001 |
| REQ-FLAG-001 | Clara.Application.Flag | TC-FLAG-001 |
| REQ-OPT-001 | Clara.Application.Option | TC-OPT-001 |
| REQ-POS-001 | Clara.Application.Positional | TC-POS-001 |
| REQ-ERR-001 | Clara.Errors | TC-ERR-001 |

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1.0 | 2025-12-19 | Michael Gardner | Initial requirements from design discussion |
