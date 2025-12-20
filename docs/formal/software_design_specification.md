# Software Design Specification (SDS)

**Project:** CLARA - Command Line Arguments for Reliable Applications
**Version:** 0.1.0
**Date:** 2025-12-19
**SPDX-License-Identifier:** BSD-3-Clause
**Copyright:** (c) 2025 Michael Gardner, A Bit of Help, Inc.
**Status:** In Development

---

## 1. Introduction

### 1.1 Purpose

This Software Design Specification (SDS) documents the architectural and detailed design decisions for **CLARA**, a type-safe command-line argument parsing library for Ada 2022.

### 1.2 Scope

This document covers:
- Package architecture and hierarchy
- Generic instantiation design pattern
- Integration with Functional library
- Key design decisions and rationale

### 1.3 References

- [CLARA SRS](software_requirements_specification.md)
- [Functional Library](https://github.com/abitofhelp/functional)
- Ada 2022 Reference Manual

---

## 2. Architectural Design

### 2.1 Package Hierarchy

```
Clara (root package)
├── Clara.Version           -- Library version information
├── Clara.Types             -- Core type definitions
├── Clara.Errors            -- Parse error types
└── Clara.Application       -- Generic CLI application definition
    ├── Clara.Application.Flag       -- Child generic for boolean flags
    ├── Clara.Application.Option     -- Child generic for value options
    └── Clara.Application.Positional -- Child generic for positional args
```

### 2.2 Design Pattern: Generic Instantiation

CLARA uses Ada's generic instantiation pattern (consistent with Functional library) rather than a builder pattern.

**Rationale:**

| Aspect | Builder Pattern | Generic Instantiation |
|--------|-----------------|----------------------|
| Type Safety | Runtime (string lookups) | Compile-time (packages) |
| Error Detection | Runtime errors | Compile-time errors |
| SPARK Compatibility | Poor (heap allocation) | Good (no heap) |
| Ada Idiom | Borrowed from OOP | Native Ada pattern |
| Consistency | Different from Functional | Same as Functional |

**Decision:** Use generic instantiation to maintain consistency with Functional library and provide compile-time type safety.

### 2.3 Integration with Functional Library

CLARA depends on and integrates with the Functional library:

| CLARA Operation | Functional Type | Purpose |
|-----------------|-----------------|---------|
| `Parse` | `Result[Unit, Parse_Error]` | Parse success/failure |
| `Option.Value` | `Option[String]` | Optional value |
| `"or"` operator | From Option | Default values |
| `And_Then`, `Map_Error` | From Result | Railway-oriented chaining |

**Usage Example:**

```ada
My_CLI.Parse
   .And_Then (Validate_Args'Access)
   .And_Then (Build_Config'Access)
   .Map_Error (To_User_Error'Access);

Output_Path : constant String := Output.Value or "./default.txt";
```

---

## 3. Detailed Design

### 3.1 Clara (Root Package)

```ada
package Clara with Pure is
   Library_Name : constant String := "CLARA";
   Acronym : constant String := "Command Line Arguments for Reliable Applications";
end Clara;
```

### 3.2 Clara.Types

Core type definitions for argument parsing:

```ada
package Clara.Types with Pure is

   --  Maximum lengths (SPARK-compatible bounds)
   Max_Short_Length : constant := 1;
   Max_Long_Length  : constant := 64;
   Max_Help_Length  : constant := 256;
   Max_Value_Length : constant := 1024;

   --  Bounded string types
   subtype Short_String is String (1 .. Max_Short_Length);
   subtype Long_String is String (1 .. Max_Long_Length);
   subtype Help_String is String (1 .. Max_Help_Length);
   subtype Value_String is String (1 .. Max_Value_Length);

end Clara.Types;
```

### 3.3 Clara.Errors

Parse error types compatible with Functional.Result:

```ada
package Clara.Errors with Pure is

   type Error_Kind is
     (Unknown_Switch,     -- Unrecognized switch
      Missing_Value,      -- Option requires value but none given
      Invalid_Value,      -- Value failed validation
      Duplicate_Switch,   -- Switch specified multiple times (if disallowed)
      Help_Requested);    -- --help was specified (not really an error)

   type Parse_Error is record
      Kind    : Error_Kind;
      Message : Bounded_String;  -- Description
      Context : Bounded_String;  -- The problematic argument
   end record;

end Clara.Errors;
```

### 3.4 Clara.Application (Generic)

The main generic package for defining a CLI application:

```ada
generic
   Name        : String;  -- Application name (e.g., "myapp")
   Description : String;  -- Application description for help text
package Clara.Application is

   --  Parse command line arguments
   --  Returns Ok(Unit) on success, Error(Parse_Error) on failure
   function Parse return Parse_Result.Result;

   --  Print help text to standard output
   procedure Print_Help;

   --  Child generic for boolean flags
   generic
      Short : Character := ASCII.NUL;  -- Optional short form (e.g., 'v')
      Long  : String;                   -- Required long form (e.g., "verbose")
      Help  : String;                   -- Help text
   package Flag is
      function Is_Set return Boolean;
      function Count return Natural;  -- For -vvv style
   end Flag;

   --  Child generic for options with values
   generic
      Short      : Character := ASCII.NUL;
      Long       : String;
      Value_Name : String;               -- Shown in help (e.g., "FILE")
      Help       : String;
      Required   : Boolean := False;
   package Option is
      function Has_Value return Boolean;
      function Value return String_Option.Option;
      function "or" (Self : String_Option.Option; Default : String) return String;
   end Option;

   --  Child generic for positional arguments
   generic
      Name     : String;    -- Argument name for help (e.g., "FILES")
      Help     : String;
      Multiple : Boolean := False;  -- Allow multiple values
   package Positional is
      function Values return String_Vector;
      function Is_Empty return Boolean;
   end Positional;

end Clara.Application;
```

### 3.5 Parsing Backend: Ada.Command_Line

**Decision:** Use `Ada.Command_Line` instead of `GNAT.Command_Line`.

**Rationale:**

| Aspect | GNAT.Command_Line | Ada.Command_Line |
|--------|-------------------|------------------|
| State | Mutable, elaboration-time | Stateless |
| Standalone Libraries | State isolation issues on macOS | Works correctly |
| Standard | GNAT-specific | Standard Ada |
| SPARK | Not compatible | Compatible |

**Issue Encountered:** `GNAT.Command_Line` with `Library_Standalone use "standard"` causes command line state to be isolated in a separate elaboration context on macOS. Arguments are not visible to code inside standalone libraries.

**Solution:** Use `Ada.Command_Line.Argument_Count` and `Ada.Command_Line.Argument(N)` directly. These are stateless calls that work correctly in any library configuration.

---

## 4. Data Structures

### 4.1 Internal Argument Registry

During parsing, CLARA maintains internal state for registered arguments:

```ada
--  Internal types (not exposed in public API)
type Argument_Kind is (Flag_Kind, Option_Kind, Positional_Kind);

type Argument_Def is record
   Kind       : Argument_Kind;
   Short      : Character;
   Long       : Bounded_String;
   Help       : Bounded_String;
   Value_Name : Bounded_String;  -- For options
   Required   : Boolean;
   Multiple   : Boolean;         -- For positionals
end record;

type Argument_Def_Array is array (Positive range <>) of Argument_Def;
```

### 4.2 Parse Results

After parsing, each argument stores its parsed state:

```ada
--  Flag state
type Flag_State is record
   Is_Set : Boolean := False;
   Count  : Natural := 0;
end record;

--  Option state
type Option_State is record
   Has_Value : Boolean := False;
   Value     : Bounded_String;
end record;

--  Positional state
type Positional_State is record
   Values : String_Vector;  -- Bounded vector
end record;
```

---

## 5. Algorithm Design

### 5.1 Parsing Algorithm

```
PROCEDURE Parse:
  FOR i IN 1 .. Argument_Count LOOP
    arg := Argument(i)

    IF arg starts with "--" THEN
      -- Long switch
      IF arg contains "=" THEN
        (name, value) := split on "="
        Find option with Long = name
        Store value
      ELSE
        Find flag/option with Long = arg[3..]
        IF option requiring value THEN
          value := Argument(i + 1)
          i := i + 1
        END IF
      END IF

    ELSIF arg starts with "-" THEN
      -- Short switch(es)
      FOR each char in arg[2..] LOOP
        Find flag/option with Short = char
        IF option requiring value THEN
          -- Rest of arg or next arg is value
        END IF
      END LOOP

    ELSE
      -- Positional argument
      Add to positional arguments list
    END IF
  END LOOP

  RETURN Ok(Unit) or Error(Parse_Error)
END PROCEDURE
```

### 5.2 Help Generation Algorithm

```
PROCEDURE Print_Help:
  Print: Name " - " Description
  Print: ""
  Print: "Usage: " Name " [OPTIONS] " positional_names
  Print: ""
  Print: "Options:"
  FOR each flag/option LOOP
    Print: "  " short_form ", " long_form "  " help_text
  END LOOP
  Print: ""
  Print: "Arguments:"
  FOR each positional LOOP
    Print: "  " name "  " help_text
  END LOOP
END PROCEDURE
```

---

## 6. Future Extensibility

### 6.1 Subcommand Support

The design accommodates future subcommand support:

```ada
--  Future: Clara.Application with commands
package My_CLI is new Clara.Application ("git", "Version control");

package Commit is new My_CLI.Command ("commit", "Record changes");
package Message is new Commit.Option ('m', "message", "MSG", "Commit message");

package Push is new My_CLI.Command ("push", "Update remote");
package Force is new Push.Flag ('f', "force", "Force push");
```

The generic hierarchy naturally supports this - `Command` becomes a child generic of `Application`, and `Flag`/`Option`/`Positional` become child generics of `Command`.

### 6.2 Extension Points

| Extension | Mechanism |
|-----------|-----------|
| Custom validators | Generic formal function parameter |
| Value transformers | Generic formal function parameter |
| Help formatters | Abstract interface + implementations |
| Shell completions | Additional generic procedures |

---

## 7. Design Decisions Log

| ID | Decision | Rationale | Date |
|----|----------|-----------|------|
| DD-001 | Generic instantiation over builder pattern | Compile-time type safety, SPARK compatible, consistent with Functional | 2025-12-19 |
| DD-002 | Ada.Command_Line over GNAT.Command_Line | Stateless, no isolation issues in standalone libraries | 2025-12-19 |
| DD-003 | Depend on Functional library | Reuse Result/Option, railway-oriented processing | 2025-12-19 |
| DD-004 | Child generics for Flag/Option/Positional | Type-safe access, compile-time error detection | 2025-12-19 |
| DD-005 | Bounded strings for SPARK compatibility | No heap allocation, embedded-safe | 2025-12-19 |

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1.0 | 2025-12-19 | Michael Gardner | Initial design from discussion |
