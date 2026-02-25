pragma Ada_2022;
--  ===========================================================================
--  Clara.Types - Core Type Definitions
--  ===========================================================================
--  Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
--  SPDX-License-Identifier: BSD-3-Clause
--
--  Purpose:
--    Defines core types used throughout CLARA for argument parsing.
--    Bounded strings for metadata (switch names, help text).
--    Unbounded strings for values (heap-allocated, finalized automatically).
--    Dynamic vectors for multi-value storage.
--
--  ===========================================================================

with Ada.Strings.Bounded;
with Ada.Strings.Unbounded;
with Ada.Containers.Vectors;

package Clara.Types
  with Preelaborate
is

   --  ==========================================================================
   --  Length Constraints for Metadata
   --  ==========================================================================
   --  Bounded sizes for CLI metadata: switch names, help text, value names.
   --  These are compile-time fixed and do not need heap allocation.

   Max_Long_Switch : constant := 64;   --  Long switch names (e.g., "exclude-path")
   Max_Help        : constant := 256;  --  Help text descriptions
   Max_Value_Name  : constant := 16;   --  Value placeholder (e.g., FILE, N)

   --  ==========================================================================
   --  Bounded String Packages (Metadata)
   --  ==========================================================================

   package Switch_Strings is new Ada.Strings.Bounded.Generic_Bounded_Length
     (Max => Max_Long_Switch);
   subtype Switch_String is Switch_Strings.Bounded_String;

   package Help_Strings is new Ada.Strings.Bounded.Generic_Bounded_Length
     (Max => Max_Help);
   subtype Help_String is Help_Strings.Bounded_String;

   package VName_Strings is new Ada.Strings.Bounded.Generic_Bounded_Length
     (Max => Max_Value_Name);
   subtype VName_String is VName_Strings.Bounded_String;

   --  ==========================================================================
   --  Convenience Constructors (Metadata)
   --  ==========================================================================

   function To_Switch (S : String) return Switch_String
     is (Switch_Strings.To_Bounded_String (S));

   function To_Help (S : String) return Help_String
     is (Help_Strings.To_Bounded_String (S));

   function To_VName (S : String) return VName_String
     is (VName_Strings.To_Bounded_String (S));

   --  ==========================================================================
   --  Value Types (Unbounded - Heap Allocated)
   --  ==========================================================================
   --  Values are user-provided and can be arbitrarily long (file paths,
   --  glob patterns, etc.). Unbounded_String is finalized automatically.

   subtype Value_String is Ada.Strings.Unbounded.Unbounded_String;

   function To_Value (S : String) return Value_String
     renames Ada.Strings.Unbounded.To_Unbounded_String;

   function Value_To_String (V : Value_String) return String
     renames Ada.Strings.Unbounded.To_String;

   Null_Value : Value_String
     renames Ada.Strings.Unbounded.Null_Unbounded_String;

   --  ==========================================================================
   --  Value List (Dynamic Vector)
   --  ==========================================================================
   --  For multi-value options (e.g., --exclude-path=*.bak --exclude-path=tmp/)
   --  and multi-value positionals (e.g., file1.adb file2.adb).

   package Value_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Value_String,
      "="          => Ada.Strings.Unbounded."=");

   subtype Value_List is Value_Vectors.Vector;

end Clara.Types;
