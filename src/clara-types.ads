pragma Ada_2022;
--  ===========================================================================
--  Clara.Types - Core Type Definitions
--  ===========================================================================
--  Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
--  SPDX-License-Identifier: BSD-3-Clause
--
--  Purpose:
--    Defines core types used throughout CLARA for argument parsing.
--    All types are bounded for SPARK compatibility and embedded use.
--
--  Design Notes:
--    - Bounded strings avoid heap allocation
--    - Subtypes enforce maximum lengths at compile time
--    - Compatible with SPARK formal verification
--
--  ===========================================================================

with Ada.Strings.Bounded;

package Clara.Types
  with Preelaborate, SPARK_Mode => On
is

   --  ==========================================================================
   --  Length Constraints
   --  ==========================================================================
   --  Maximum lengths for various string types. These bounds ensure
   --  predictable memory usage and SPARK compatibility.

   Max_Name_Length        : constant := 32;    --  App/command names
   Max_Long_Switch_Length : constant := 64;    --  Long switch names
   Max_Value_Name_Length  : constant := 16;    --  Value placeholder (e.g., FILE)
   Max_Help_Length        : constant := 256;   --  Help text
   Max_Value_Length       : constant := 4096;  --  Argument values
   Max_Message_Length     : constant := 512;   --  Error messages

   --  Maximum number of arguments we can handle
   Max_Arguments : constant := 256;

   --  Maximum number of values for a multi-value positional
   --  Increased to 4096 to support large codebases (e.g., src/**/*.ads)
   Max_Positional_Values : constant := 4096;

   --  ==========================================================================
   --  Bounded String Packages
   --  ==========================================================================

   package Name_Strings is new Ada.Strings.Bounded.Generic_Bounded_Length
     (Max => Max_Name_Length);
   subtype Name_String is Name_Strings.Bounded_String;

   package Long_Switch_Strings is new Ada.Strings.Bounded.Generic_Bounded_Length
     (Max => Max_Long_Switch_Length);
   subtype Long_Switch_String is Long_Switch_Strings.Bounded_String;

   package Value_Name_Strings is new Ada.Strings.Bounded.Generic_Bounded_Length
     (Max => Max_Value_Name_Length);
   subtype Value_Name_String is Value_Name_Strings.Bounded_String;

   package Help_Strings is new Ada.Strings.Bounded.Generic_Bounded_Length
     (Max => Max_Help_Length);
   subtype Help_String is Help_Strings.Bounded_String;

   package Value_Strings is new Ada.Strings.Bounded.Generic_Bounded_Length
     (Max => Max_Value_Length);
   subtype Value_String is Value_Strings.Bounded_String;

   package Message_Strings is new Ada.Strings.Bounded.Generic_Bounded_Length
     (Max => Max_Message_Length);
   subtype Message_String is Message_Strings.Bounded_String;

   --  ==========================================================================
   --  Convenience Functions
   --  ==========================================================================

   function To_Name (S : String) return Name_String
     is (Name_Strings.To_Bounded_String (S));

   function To_Long_Switch (S : String) return Long_Switch_String
     is (Long_Switch_Strings.To_Bounded_String (S));

   function To_Value_Name (S : String) return Value_Name_String
     is (Value_Name_Strings.To_Bounded_String (S));

   function To_Help (S : String) return Help_String
     is (Help_Strings.To_Bounded_String (S));

   function To_Value (S : String) return Value_String
     is (Value_Strings.To_Bounded_String (S));

   function To_Message (S : String) return Message_String
     is (Message_Strings.To_Bounded_String (S));

   --  ==========================================================================
   --  Argument Kind Enumeration
   --  ==========================================================================

   type Argument_Kind is
     (Flag_Argument,        --  Boolean switch (e.g., -v, --verbose)
      Option_Argument,      --  Switch with value (e.g., -o file, --output=file)
      Positional_Argument); --  Non-switch argument (e.g., file paths)

   --  ==========================================================================
   --  Value Vector for Positional Arguments
   --  ==========================================================================
   --  Simple bounded array for storing multiple positional values.

   type Value_Array is array (Positive range <>) of Value_String;

   type Value_Vector (Capacity : Positive) is record
      Items : Value_Array (1 .. Capacity);
      Count : Natural := 0;
   end record;

   --  Vector operations
   function Is_Empty (V : Value_Vector) return Boolean
     is (V.Count = 0);

   function Length (V : Value_Vector) return Natural
     is (V.Count);

   function Is_Full (V : Value_Vector) return Boolean
     is (V.Count >= V.Capacity);

end Clara.Types;
