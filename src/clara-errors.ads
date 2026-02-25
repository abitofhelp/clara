pragma Ada_2022;
--  ===========================================================================
--  Clara.Errors - Parse Error Types
--  ===========================================================================
--  Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
--  SPDX-License-Identifier: BSD-3-Clause
--
--  Purpose:
--    Defines error types for command-line argument parsing.
--    Designed for use with Functional.Result monad.
--
--  ===========================================================================

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package Clara.Errors
  with Preelaborate
is

   --  ==========================================================================
   --  Error Kind Enumeration
   --  ==========================================================================

   type Error_Kind is
     (None,              --  No error (for default initialization)
      Unknown_Switch,    --  Unrecognized switch (e.g., --unknown)
      Missing_Value,     --  Option requires value but none was provided
      Invalid_Value,     --  Value failed validation
      Duplicate_Switch,  --  Switch specified multiple times when not allowed
      Missing_Required,  --  Required option was not provided
      Too_Many_Values,   --  Exceeded maximum positional arguments
      Command_Mismatch,  --  Flag/option used with wrong command
      Help_Requested,    --  --help was specified (graceful exit)
      Version_Requested, --  --version was specified (graceful exit)
      Internal_Error);   --  Unexpected internal error

   --  ==========================================================================
   --  Parse Error Record
   --  ==========================================================================

   type Parse_Error is record
      Kind    : Error_Kind       := None;
      Message : Unbounded_String := Null_Unbounded_String;
      Context : Unbounded_String := Null_Unbounded_String;
   end record;

   --  ==========================================================================
   --  Error Constructors
   --  ==========================================================================

   function Make_Error
     (Kind    : Error_Kind;
      Message : String;
      Context : String := "") return Parse_Error
   with
     Pre  => Kind /= None,
     Post => Make_Error'Result.Kind = Kind;

   function Unknown_Switch_Error (Switch : String) return Parse_Error
   with Post => Unknown_Switch_Error'Result.Kind = Unknown_Switch;

   function Missing_Value_Error (Switch : String) return Parse_Error
   with Post => Missing_Value_Error'Result.Kind = Missing_Value;

   function Missing_Required_Error (Name : String) return Parse_Error
   with Post => Missing_Required_Error'Result.Kind = Missing_Required;

   function Too_Many_Values_Error (Max : Natural) return Parse_Error
   with Post => Too_Many_Values_Error'Result.Kind = Too_Many_Values;

   function Command_Mismatch_Error
     (Switch : String; Command : String) return Parse_Error
   with Post => Command_Mismatch_Error'Result.Kind = Command_Mismatch;

   function Help_Requested_Error return Parse_Error
   with Post => Help_Requested_Error'Result.Kind = Help_Requested;

   function Version_Requested_Error return Parse_Error
   with Post => Version_Requested_Error'Result.Kind = Version_Requested;

   --  ==========================================================================
   --  Error Predicates
   --  ==========================================================================

   function Is_Graceful_Exit (E : Parse_Error) return Boolean
     is (E.Kind in Help_Requested | Version_Requested);

   function Is_User_Error (E : Parse_Error) return Boolean
     is (E.Kind in Unknown_Switch | Missing_Value | Invalid_Value |
                   Duplicate_Switch | Missing_Required | Too_Many_Values |
                   Command_Mismatch);

   --  ==========================================================================
   --  Error Formatting
   --  ==========================================================================

   function Format (E : Parse_Error) return String;

end Clara.Errors;
