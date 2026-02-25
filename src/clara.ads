pragma Ada_2022;
--  ===========================================================================
--  Clara - Command Line Arguments for Reliable Applications
--  ===========================================================================
--  Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
--  SPDX-License-Identifier: BSD-3-Clause
--
--  Purpose:
--    Root package for the CLARA command-line argument parsing library.
--    Provides type-safe CLI parsing through a generic package (Clara.CLI)
--    with enum-indexed configuration and Functional.Result error handling.
--
--  Key Child Packages:
--    Clara.Types    - Bounded metadata strings, unbounded values, vectors
--    Clara.Errors   - Parse error types and factory functions
--    Clara.CLI      - Generic parser (the core of Clara)
--    Clara.Version  - Semantic version constants
--
--  Design Philosophy:
--    - Enum-indexed declarative configuration for compile-time safety
--    - Aggregate initialization as the Ada-idiomatic "builder pattern"
--    - Testable Parse (accepts argument array, not just Ada.Command_Line)
--    - Integrates with Functional.Result for railway-oriented error handling
--
--  ===========================================================================

package Clara
  with Pure
is
   Library_Name : constant String := "CLARA";

   Acronym : constant String :=
     "Command Line Arguments for Reliable Applications";

end Clara;
