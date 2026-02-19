pragma Ada_2022;
--  ===========================================================================
--  Clara.Errors - Parse Error Types (Body)
--  ===========================================================================
--  Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
--  SPDX-License-Identifier: BSD-3-Clause
--  ===========================================================================

package body Clara.Errors
  with SPARK_Mode => On
is

   --  ==========================================================================
   --  Error Constructors
   --  ==========================================================================

   function Make_Error
     (Kind    : Error_Kind;
      Message : String;
      Context : String := "") return Parse_Error
   is
   begin
      return
        (Kind    => Kind,
         Message => To_Message (Message),
         Context => To_Value (Context));
   end Make_Error;

   function Unknown_Switch_Error (Switch : String) return Parse_Error is
   begin
      return Make_Error
        (Kind    => Unknown_Switch,
         Message => "Unknown switch",
         Context => Switch);
   end Unknown_Switch_Error;

   function Missing_Value_Error (Switch : String) return Parse_Error is
   begin
      return Make_Error
        (Kind    => Missing_Value,
         Message => "Option requires a value",
         Context => Switch);
   end Missing_Value_Error;

   function Missing_Required_Error (Name : String) return Parse_Error is
   begin
      return Make_Error
        (Kind    => Missing_Required,
         Message => "Required option not provided",
         Context => Name);
   end Missing_Required_Error;

   function Too_Many_Values_Error (Max : Natural) return Parse_Error is
      Max_Str : constant String := Natural'Image (Max);
   begin
      return Make_Error
        (Kind    => Too_Many_Values,
         Message => "Too many arguments (max:" & Max_Str & ")",
         Context => "");
   end Too_Many_Values_Error;

   function Command_Mismatch_Error
     (Switch : String; Command : String) return Parse_Error
   is
   begin
      return Make_Error
        (Kind    => Command_Mismatch,
         Message =>
           "This option is only available with the '"
           & Command & "' command",
         Context => Switch);
   end Command_Mismatch_Error;

   function Help_Requested_Error return Parse_Error is
   begin
      return
        (Kind    => Help_Requested,
         Message => Message_Strings.Null_Bounded_String,
         Context => Value_Strings.Null_Bounded_String);
   end Help_Requested_Error;

   function Version_Requested_Error return Parse_Error is
   begin
      return
        (Kind    => Version_Requested,
         Message => Message_Strings.Null_Bounded_String,
         Context => Value_Strings.Null_Bounded_String);
   end Version_Requested_Error;

   --  ==========================================================================
   --  Error Formatting
   --  ==========================================================================

   function Format (E : Parse_Error) return String is
      use Message_Strings;
      use Value_Strings;
   begin
      if E.Kind = None then
         return "";
      elsif Length (E.Context) = 0 then
         return To_String (E.Message);
      else
         return To_String (E.Message) & ": " & To_String (E.Context);
      end if;
   end Format;

end Clara.Errors;
