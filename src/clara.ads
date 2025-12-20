pragma Ada_2022;
--  ===========================================================================
--  Clara - Command Line Arguments for Reliable Applications
--  ===========================================================================
--  Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
--  SPDX-License-Identifier: BSD-3-Clause
--
--  Purpose:
--    Root package for the CLARA command-line argument parsing library.
--    Provides type-safe CLI parsing through generic instantiation,
--    integrating with Functional library's Result and Option monads.
--
--  Key Child Packages:
--    Clara.Application  - Generic CLI application definition
--    Clara.Types        - Core types for flags, options, positionals
--    Clara.Errors       - Parse error types
--
--  Design Philosophy:
--    - Generic instantiation for compile-time type safety
--    - No string lookups - each flag/option is its own package
--    - Stateless parsing via Ada.Command_Line
--    - SPARK compatible - no heap allocation
--    - Integrates with Functional.Result and Functional.Option
--
--  ===========================================================================

package Clara
  with Pure
is
   --  Library name constant
   Library_Name : constant String := "CLARA";

   --  Acronym expansion
   Acronym : constant String := "Command Line Arguments for Reliable Applications";

end Clara;
