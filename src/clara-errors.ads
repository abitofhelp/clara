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
--  Usage:
--    Parse_Result : Clara.Parse_Result.Result := Clara.Parse;
--    if Parse_Result.Is_Error then
--       case Parse_Result.Error.Kind is
--          when Unknown_Switch => ...
--          when Missing_Value => ...
--       end case;
--    end if;
--
--  ===========================================================================

with Clara.Types; use Clara.Types;

package Clara.Errors
  with Preelaborate, SPARK_Mode => On
is

   --  ==========================================================================
   --  Error Kind Enumeration
   --  ==========================================================================

   type Error_Kind is
     (None,              --  No error (for default initialization)
      Unknown_Switch,    --  Unrecognized switch (e.g., --unknown)
      Missing_Value,     --  Option requires value but none provided
      Invalid_Value,     --  Value failed validation
      Duplicate_Switch,  --  Switch specified multiple times when not allowed
      Missing_Required,  --  Required option not provided
      Too_Many_Values,   --  Exceeded maximum positional arguments
      Help_Requested,    --  --help was specified (graceful exit)
      Version_Requested, --  --version was specified (graceful exit)
      Internal_Error);   --  Unexpected internal error

   --  ==========================================================================
   --  Parse Error Record
   --  ==========================================================================
   --
   --  A structured error containing:
   --    - Kind: The category of error
   --    - Message: Human-readable description
   --    - Context: The problematic argument or value
   --
   --  Example:
   --    (Kind => Unknown_Switch,
   --     Message => "Unknown switch",
   --     Context => "--foobar")

   type Parse_Error is record
      Kind    : Error_Kind := None;
      Message : Message_String := Message_Strings.Null_Bounded_String;
      Context : Value_String := Value_Strings.Null_Bounded_String;
   end record;

   --  ==========================================================================
   --  Error Constructors
   --  ==========================================================================
   --  Factory functions for creating errors with proper context.

   function Make_Error
     (Kind    : Error_Kind;
      Message : String;
      Context : String := "") return Parse_Error
   with
     Pre => Kind /= None,
     Post => Make_Error'Result.Kind = Kind;

   function Unknown_Switch_Error (Switch : String) return Parse_Error
   with Post => Unknown_Switch_Error'Result.Kind = Unknown_Switch;

   function Missing_Value_Error (Switch : String) return Parse_Error
   with Post => Missing_Value_Error'Result.Kind = Missing_Value;

   function Missing_Required_Error (Name : String) return Parse_Error
   with Post => Missing_Required_Error'Result.Kind = Missing_Required;

   function Too_Many_Values_Error (Max : Natural) return Parse_Error
   with Post => Too_Many_Values_Error'Result.Kind = Too_Many_Values;

   function Help_Requested_Error return Parse_Error
   with Post => Help_Requested_Error'Result.Kind = Help_Requested;

   function Version_Requested_Error return Parse_Error
   with Post => Version_Requested_Error'Result.Kind = Version_Requested;

   --  ==========================================================================
   --  Error Predicates
   --  ==========================================================================

   function Is_Graceful_Exit (E : Parse_Error) return Boolean
     is (E.Kind in Help_Requested | Version_Requested);
   --  True if error represents user-requested exit (not a real error)

   function Is_User_Error (E : Parse_Error) return Boolean
     is (E.Kind in Unknown_Switch | Missing_Value | Invalid_Value |
                   Duplicate_Switch | Missing_Required | Too_Many_Values);
   --  True if error is due to user input

   --  ==========================================================================
   --  Error Formatting
   --  ==========================================================================

   function Format (E : Parse_Error) return String;
   --  Format error for display to user

end Clara.Errors;
