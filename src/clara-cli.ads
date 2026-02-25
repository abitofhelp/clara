pragma Ada_2022;
--  ===========================================================================
--  Clara.CLI - Generic Command-Line Parser
--  ===========================================================================
--  Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
--  SPDX-License-Identifier: BSD-3-Clause
--
--  Purpose:
--    The core of Clara: a generic CLI parser parameterized by enum types
--    for commands, flags, options, and positionals. Configuration is
--    declared as an aggregate (the Ada-idiomatic "builder pattern").
--    Parse returns a typed result record indexed by the same enums.
--
--  Usage:
--    type My_Cmd  is (Write, Check, Dry_Run);
--    type My_Flag is (Yes, Verbose);
--    type My_Opt  is (Workers, Indent_Width, Exclude_Path);
--    type My_Pos  is (Paths);
--
--    package CLI is new Clara.CLI
--      (Command_Id      => My_Cmd,
--       Flag_Id         => My_Flag,
--       Option_Id       => My_Opt,
--       Positional_Id   => My_Pos,
--       App_Name        => "myapp",
--       App_Description => "My application");
--
--    Config : constant CLI.CLI_Config := ( ... );
--    Result : constant CLI.Parse_Outcome.Result := CLI.Parse (Config);
--
--  ===========================================================================

with Clara.Types;  use Clara.Types;
with Clara.Errors; use Clara.Errors;
with Functional.Result;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

generic
   type Command_Id    is (<>);
   type Flag_Id       is (<>);
   type Option_Id     is (<>);
   type Positional_Id is (<>);
   App_Name        : String;  --  Used by consumer's Show_Help
   App_Description : String;  --  Used by consumer's Show_Help
   pragma Unreferenced (App_Name, App_Description);
   with procedure Show_Help is null;
package Clara.CLI is

   --  ==========================================================================
   --  Definition Types (for CLI_Config aggregate)
   --  ==========================================================================

   type Command_Def is record
      Name : Switch_String := Switch_Strings.Null_Bounded_String;
      Help : Help_String   := Help_Strings.Null_Bounded_String;
   end record;

   type Flag_Def is record
      Short     : Character     := ASCII.NUL;
      Long      : Switch_String := Switch_Strings.Null_Bounded_String;
      Help      : Help_String   := Help_Strings.Null_Bounded_String;
      Is_Scoped : Boolean       := False;
      Scope     : Command_Id    := Command_Id'First;
   end record;

   type Option_Def is record
      Short      : Character     := ASCII.NUL;
      Long       : Switch_String := Switch_Strings.Null_Bounded_String;
      Value_Name : VName_String  := VName_Strings.Null_Bounded_String;
      Help       : Help_String   := Help_Strings.Null_Bounded_String;
      Required   : Boolean       := False;
      Multiple   : Boolean       := False;
      Is_Scoped  : Boolean       := False;
      Scope      : Command_Id    := Command_Id'First;
   end record;

   type Positional_Def is record
      Name     : Switch_String := Switch_Strings.Null_Bounded_String;
      Help     : Help_String   := Help_Strings.Null_Bounded_String;
      Multiple : Boolean       := False;
   end record;

   --  Enum-indexed arrays of definitions
   type Command_Defs    is array (Command_Id)    of Command_Def;
   type Flag_Defs       is array (Flag_Id)       of Flag_Def;
   type Option_Defs     is array (Option_Id)     of Option_Def;
   type Positional_Defs is array (Positional_Id) of Positional_Def;

   type CLI_Config is record
      Commands    : Command_Defs;
      Flags       : Flag_Defs;
      Options     : Option_Defs;
      Positionals : Positional_Defs;
   end record;

   --  ==========================================================================
   --  Convenience Constructors
   --  ==========================================================================

   function Cmd
     (Name : String;
      Help : String := "") return Command_Def;

   --  Global flag (no command scope)
   function Flag
     (Short : Character := ASCII.NUL;
      Long  : String;
      Help  : String := "") return Flag_Def;

   --  Command-scoped flag
   function Flag
     (Short : Character := ASCII.NUL;
      Long  : String;
      Help  : String := "";
      Scope : Command_Id) return Flag_Def;

   --  Global option (no command scope)
   function Opt
     (Short      : Character := ASCII.NUL;
      Long       : String;
      Value_Name : String  := "VALUE";
      Help       : String  := "";
      Required   : Boolean := False;
      Multiple   : Boolean := False) return Option_Def;

   --  Command-scoped option
   function Opt
     (Short      : Character := ASCII.NUL;
      Long       : String;
      Value_Name : String     := "VALUE";
      Help       : String     := "";
      Required   : Boolean    := False;
      Multiple   : Boolean    := False;
      Scope      : Command_Id) return Option_Def;

   function Pos
     (Name     : String;
      Help     : String  := "";
      Multiple : Boolean := False) return Positional_Def;

   --  ==========================================================================
   --  Parse Result Types
   --  ==========================================================================

   type Flag_Result is record
      Is_Set : Boolean := False;
      Count  : Natural := 0;
   end record;

   type Option_Result is record
      Has_Value : Boolean      := False;
      Value     : Value_String := Null_Unbounded_String;
      Values    : Value_List;
   end record;

   type Positional_Result is record
      Values : Value_List;
   end record;

   type Flag_Results       is array (Flag_Id)       of Flag_Result;
   type Option_Results     is array (Option_Id)     of Option_Result;
   type Positional_Results is array (Positional_Id) of Positional_Result;
   type Command_Active     is array (Command_Id)    of Boolean;

   type Parse_Results is record
      Flags              : Flag_Results;
      Options            : Option_Results;
      Positionals        : Positional_Results;
      Commands           : Command_Active     := [others => False];
      Has_Active_Command : Boolean            := False;
      Active_Cmd         : Command_Id         := Command_Id'First;
   end record;

   --  ==========================================================================
   --  Parse Outcome (Result Monad)
   --  ==========================================================================

   package Parse_Outcome is new Functional.Result
     (T => Parse_Results,
      E => Parse_Error);

   --  ==========================================================================
   --  Argument Array (for testable parsing)
   --  ==========================================================================

   type Argument_Array is array (Positive range <>) of Value_String;

   function From_Command_Line return Argument_Array;

   function Parse
     (Config : CLI_Config;
      Args   : Argument_Array) return Parse_Outcome.Result;

   function Parse (Config : CLI_Config) return Parse_Outcome.Result;

   --  ==========================================================================
   --  Query API (Expression Functions)
   --  ==========================================================================

   function Is_Active
     (R : Parse_Results;
      C : Command_Id) return Boolean
     is (R.Commands (C));

   function Is_Set
     (R : Parse_Results;
      F : Flag_Id) return Boolean
     is (R.Flags (F).Is_Set);

   function Flag_Count
     (R : Parse_Results;
      F : Flag_Id) return Natural
     is (R.Flags (F).Count);

   function Has_Option
     (R : Parse_Results;
      O : Option_Id) return Boolean
     is (R.Options (O).Has_Value);

   function Get_Option
     (R : Parse_Results;
      O : Option_Id) return String
     is (To_String (R.Options (O).Value));

   function Get_Option_Or
     (R       : Parse_Results;
      O       : Option_Id;
      Default : String) return String
     is (if R.Options (O).Has_Value
         then To_String (R.Options (O).Value)
         else Default);

   function Option_Count
     (R : Parse_Results;
      O : Option_Id) return Natural
     is (Natural (R.Options (O).Values.Length));

   function Has_Positional
     (R : Parse_Results;
      P : Positional_Id) return Boolean
     is (not R.Positionals (P).Values.Is_Empty);

   function Positional_Count
     (R : Parse_Results;
      P : Positional_Id) return Natural
     is (Natural (R.Positionals (P).Values.Length));

end Clara.CLI;
