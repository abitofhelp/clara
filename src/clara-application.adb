pragma Ada_2022;
--  ===========================================================================
--  Clara.Application - Generic CLI Application Definition (Body)
--  ===========================================================================
--  Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
--  SPDX-License-Identifier: BSD-3-Clause
--  ===========================================================================

with Ada.Command_Line;
with Ada.Text_IO;
with Clara.Version;

package body Clara.Application is

   --  ==========================================================================
   --  Internal Constants
   --  ==========================================================================

   Max_Commands : constant := 16;

   --  ==========================================================================
   --  Internal Types for Command Registration
   --  ==========================================================================

   type Command_Entry is record
      Name      : Long_Switch_String := Long_Switch_Strings.Null_Bounded_String;
      Help_Text : Help_String := Help_Strings.Null_Bounded_String;
      Is_Active : access Boolean := null;
   end record;

   type Command_Array is array (1 .. Max_Commands) of Command_Entry;

   --  ==========================================================================
   --  Internal Types for Argument Registration
   --  ==========================================================================

   type Argument_Entry is record
      Kind       : Argument_Kind := Flag_Argument;
      Short      : Character := ASCII.NUL;
      Long       : Long_Switch_String := Long_Switch_Strings.Null_Bounded_String;
      Value_Name : Value_Name_String := Value_Name_Strings.Null_Bounded_String;
      Help_Text  : Help_String := Help_Strings.Null_Bounded_String;
      Required   : Boolean := False;
      Multiple   : Boolean := False;
      Cmd_Scope  : Long_Switch_String := Long_Switch_Strings.Null_Bounded_String;
      --  State pointers (set by child generics)
      Flag_Set   : access Boolean := null;
      Flag_Count : access Natural := null;
      Opt_Value  : access Value_String := null;
      Opt_Has    : access Boolean := null;
      Opt_Values : access Value_Vector := null;
      Pos_Values : access Value_Vector := null;
   end record;

   type Argument_Array is array (1 .. Max_Arguments) of Argument_Entry;

   --  ==========================================================================
   --  Package State
   --  ==========================================================================

   Arguments        : Argument_Array;
   Registered_Count : Natural := 0;
   Parsed           : Boolean := False;

   --  Index of the first positional argument definition
   First_Positional_Index : Natural := 0;

   --  Command state
   Commands             : Command_Array;
   Registered_Cmd_Count : Natural := 0;
   Active_Cmd_Index     : Natural := 0;
   Command_Arg_Position : Natural := 0;

   --  ==========================================================================
   --  Internal: Register a command
   --  ==========================================================================

   procedure Register_Command
     (Name       : String;
      Help_Text  : String;
      Active_Ptr : access Boolean)
   is
   begin
      if Registered_Cmd_Count < Max_Commands then
         Registered_Cmd_Count := Registered_Cmd_Count + 1;
         Commands (Registered_Cmd_Count) :=
           (Name      => To_Long_Switch (Name),
            Help_Text => To_Help (Help_Text),
            Is_Active => Active_Ptr);
      end if;
   end Register_Command;

   --  ==========================================================================
   --  Internal: Register an argument
   --  ==========================================================================

   procedure Register_Flag
     (Short      : Character;
      Long       : String;
      Help_Text  : String;
      Cmd_Scope  : String;
      Set_Ptr    : access Boolean;
      Count_Ptr  : access Natural)
   is
   begin
      if Registered_Count < Max_Arguments then
         Registered_Count := Registered_Count + 1;
         Arguments (Registered_Count) :=
           (Kind       => Flag_Argument,
            Short      => Short,
            Long       => To_Long_Switch (Long),
            Value_Name => Value_Name_Strings.Null_Bounded_String,
            Help_Text  => To_Help (Help_Text),
            Required   => False,
            Multiple   => False,
            Cmd_Scope  => To_Long_Switch (Cmd_Scope),
            Flag_Set   => Set_Ptr,
            Flag_Count => Count_Ptr,
            Opt_Value  => null,
            Opt_Has    => null,
            Opt_Values => null,
            Pos_Values => null);
      end if;
   end Register_Flag;

   procedure Register_Option
     (Short      : Character;
      Long       : String;
      Value_Name : String;
      Help_Text  : String;
      Required   : Boolean;
      Cmd_Scope  : String;
      Multiple   : Boolean;
      Has_Ptr    : access Boolean;
      Value_Ptr  : access Value_String;
      Values_Ptr : access Value_Vector)
   is
   begin
      if Registered_Count < Max_Arguments then
         Registered_Count := Registered_Count + 1;
         Arguments (Registered_Count) :=
           (Kind       => Option_Argument,
            Short      => Short,
            Long       => To_Long_Switch (Long),
            Value_Name => To_Value_Name (Value_Name),
            Help_Text  => To_Help (Help_Text),
            Required   => Required,
            Multiple   => Multiple,
            Cmd_Scope  => To_Long_Switch (Cmd_Scope),
            Flag_Set   => null,
            Flag_Count => null,
            Opt_Value  => Value_Ptr,
            Opt_Has    => Has_Ptr,
            Opt_Values => Values_Ptr,
            Pos_Values => null);
      end if;
   end Register_Option;

   procedure Register_Positional
     (Name       : String;
      Help_Text  : String;
      Multiple   : Boolean;
      Values_Ptr : access Value_Vector)
   is
   begin
      if Registered_Count < Max_Arguments then
         Registered_Count := Registered_Count + 1;
         if First_Positional_Index = 0 then
            First_Positional_Index := Registered_Count;
         end if;
         Arguments (Registered_Count) :=
           (Kind       => Positional_Argument,
            Short      => ASCII.NUL,
            Long       => To_Long_Switch (Name),  --  Reuse for display name
            Value_Name => Value_Name_Strings.Null_Bounded_String,
            Help_Text  => To_Help (Help_Text),
            Required   => False,
            Multiple   => Multiple,
            Cmd_Scope  => Long_Switch_Strings.Null_Bounded_String,
            Flag_Set   => null,
            Flag_Count => null,
            Opt_Value  => null,
            Opt_Has    => null,
            Opt_Values => null,
            Pos_Values => Values_Ptr);
      end if;
   end Register_Positional;

   --  ==========================================================================
   --  Internal: Find argument by switch
   --  ==========================================================================

   function Find_By_Short (C : Character) return Natural is
   begin
      for I in 1 .. Registered_Count loop
         if Arguments (I).Short = C then
            return I;
         end if;
      end loop;
      return 0;
   end Find_By_Short;

   function Find_By_Long (S : String) return Natural is
      use Long_Switch_Strings;
   begin
      for I in 1 .. Registered_Count loop
         if To_String (Arguments (I).Long) = S then
            return I;
         end if;
      end loop;
      return 0;
   end Find_By_Long;

   --  ==========================================================================
   --  Internal: Check command scope
   --  ==========================================================================
   --  Returns True if the argument at Idx is allowed given the currently
   --  active command. Global arguments (empty Cmd_Scope) are always allowed.

   function Check_Scope (Idx : Positive) return Boolean is
      use Long_Switch_Strings;
   begin
      if Registered_Cmd_Count = 0 then
         return True;  --  No commands registered; everything is global
      end if;

      if Length (Arguments (Idx).Cmd_Scope) = 0 then
         return True;  --  Global argument
      end if;

      if Active_Cmd_Index = 0 then
         return False;  --  Scoped arg but no command active
      end if;

      return To_String (Arguments (Idx).Cmd_Scope) =
             To_String (Commands (Active_Cmd_Index).Name);
   end Check_Scope;

   --  ==========================================================================
   --  Internal: Phase 1 - Find command word
   --  ==========================================================================
   --  Scans arguments left-to-right. Skips switches (and their values).
   --  The first non-switch argument matching a registered command name
   --  becomes the active command.

   procedure Find_Command is
      use Ada.Command_Line;
      use Long_Switch_Strings;

      I : Positive := 1;
   begin
      Active_Cmd_Index := 0;
      Command_Arg_Position := 0;

      while I <= Argument_Count loop
         declare
            Arg : constant String := Argument (I);
         begin
            if Arg = "--" then
               --  End of switches; no command found
               return;

            elsif Arg'Length >= 2
              and then Arg (Arg'First .. Arg'First + 1) = "--"
            then
               --  Long switch. Under '=' convention, value is always
               --  in the same token. Just skip this argument.
               I := I + 1;

            elsif Arg'Length >= 2 and then Arg (Arg'First) = '-' then
               --  Short switch(es). Check if any maps to an option
               --  that consumes the next argument as its value.
               declare
                  Consumed_Next : Boolean := False;
               begin
                  for J in Arg'First + 1 .. Arg'Last loop
                     declare
                        C   : constant Character := Arg (J);
                        Idx : constant Natural := Find_By_Short (C);
                     begin
                        if Idx > 0
                          and then Arguments (Idx).Kind = Option_Argument
                        then
                           --  Option found. If this char is the last in the
                           --  token, the value is the next argument.
                           if J = Arg'Last then
                              Consumed_Next := True;
                           end if;
                           exit;  --  Rest of token is value (or end)
                        end if;
                     end;
                  end loop;

                  I := I + 1;
                  if Consumed_Next and then I <= Argument_Count then
                     I := I + 1;  --  Skip value argument
                  end if;
               end;

            else
               --  Non-switch. Check against registered commands.
               for K in 1 .. Registered_Cmd_Count loop
                  if Arg = To_String (Commands (K).Name) then
                     Active_Cmd_Index := K;
                     Command_Arg_Position := I;
                     if Commands (K).Is_Active /= null then
                        Commands (K).Is_Active.all := True;
                     end if;
                     return;
                  end if;
               end loop;

               --  Not a command; continue scanning
               I := I + 1;
            end if;
         end;
      end loop;
   end Find_Command;

   --  ==========================================================================
   --  Parse Implementation
   --  ==========================================================================

   function Parse return Parse_Result.Result is
      use Ada.Command_Line;
      use Long_Switch_Strings;

      Arg_Index        : Positive := 1;
      Current_Pos_Arg  : Natural := First_Positional_Index;
      Has_Commands     : constant Boolean := Registered_Cmd_Count > 0;
   begin
      --  Reset state from any previous parse
      Parsed := False;
      Active_Cmd_Index := 0;
      Command_Arg_Position := 0;

      for I in 1 .. Registered_Count loop
         case Arguments (I).Kind is
            when Flag_Argument =>
               if Arguments (I).Flag_Set /= null then
                  Arguments (I).Flag_Set.all := False;
               end if;
               if Arguments (I).Flag_Count /= null then
                  Arguments (I).Flag_Count.all := 0;
               end if;
            when Option_Argument =>
               if Arguments (I).Opt_Has /= null then
                  Arguments (I).Opt_Has.all := False;
               end if;
               if Arguments (I).Opt_Values /= null then
                  Arguments (I).Opt_Values.Count := 0;
               end if;
            when Positional_Argument =>
               if Arguments (I).Pos_Values /= null then
                  Arguments (I).Pos_Values.Count := 0;
               end if;
         end case;
      end loop;

      for I in 1 .. Registered_Cmd_Count loop
         if Commands (I).Is_Active /= null then
            Commands (I).Is_Active.all := False;
         end if;
      end loop;

      --  Phase 1: Find active command (if commands are registered)
      if Has_Commands then
         Find_Command;
      end if;

      --  Phase 2: Parse all arguments
      while Arg_Index <= Argument_Count loop
         declare
            Arg             : constant String := Argument (Arg_Index);
            Is_Command_Word : constant Boolean :=
              Has_Commands
              and then Command_Arg_Position > 0
              and then Arg_Index = Command_Arg_Position;
         begin
            if Is_Command_Word then
               --  Skip command word (already processed in Phase 1)
               null;

            elsif Arg'Length = 0 then
               --  Empty argument, skip
               null;

            elsif Arg'Length >= 2
              and then Arg (Arg'First .. Arg'First + 1) = "--"
            then
               --  Long switch
               if Arg = "--" then
                  --  "--" means rest are positional
                  Arg_Index := Arg_Index + 1;
                  exit;  --  Handle remaining as positional below
               end if;

               declare
                  Rest        : constant String :=
                    Arg (Arg'First + 2 .. Arg'Last);
                  Equals_Pos  : Natural := 0;
                  Switch_Name : Long_Switch_String;
                  Switch_Value : Value_String;
                  Idx : Natural;
               begin
                  --  Check for --switch=value format
                  for I in Rest'Range loop
                     if Rest (I) = '=' then
                        Equals_Pos := I;
                        exit;
                     end if;
                  end loop;

                  if Equals_Pos > 0 then
                     Switch_Name := To_Long_Switch
                       (Rest (Rest'First .. Equals_Pos - 1));
                     Switch_Value := To_Value
                       (Rest (Equals_Pos + 1 .. Rest'Last));
                  else
                     Switch_Name := To_Long_Switch (Rest);
                  end if;

                  --  Check for help/version
                  if To_String (Switch_Name) = "help" then
                     Show_Help;
                     return Parse_Result.New_Error (Help_Requested_Error);
                  elsif To_String (Switch_Name) = "version" then
                     return Parse_Result.New_Error
                       (Version_Requested_Error);
                  end if;

                  Idx := Find_By_Long (To_String (Switch_Name));
                  if Idx = 0 then
                     return Parse_Result.New_Error
                       (Unknown_Switch_Error (Arg));
                  end if;

                  --  Check command scope
                  if not Check_Scope (Idx) then
                     return Parse_Result.New_Error
                       (Command_Mismatch_Error
                          (Arg,
                           To_String (Arguments (Idx).Cmd_Scope)));
                  end if;

                  case Arguments (Idx).Kind is
                     when Flag_Argument =>
                        if Arguments (Idx).Flag_Set /= null then
                           Arguments (Idx).Flag_Set.all := True;
                        end if;
                        if Arguments (Idx).Flag_Count /= null then
                           Arguments (Idx).Flag_Count.all :=
                             Arguments (Idx).Flag_Count.all + 1;
                        end if;

                     when Option_Argument =>
                        --  Long options REQUIRE '=' syntax
                        if Equals_Pos = 0 then
                           return Parse_Result.New_Error
                             (Make_Error
                                (Missing_Value,
                                 "Long option requires '=' syntax"
                                 & " (e.g., --"
                                 & To_String (Switch_Name) & "=VALUE)",
                                 Arg));
                        end if;
                        if Arguments (Idx).Opt_Has /= null then
                           Arguments (Idx).Opt_Has.all := True;
                        end if;
                        if Arguments (Idx).Multiple
                          and then Arguments (Idx).Opt_Values /= null
                        then
                           declare
                              OV : constant access Value_Vector :=
                                Arguments (Idx).Opt_Values;
                           begin
                              if OV.Count < OV.Capacity then
                                 OV.Count := OV.Count + 1;
                                 OV.Items (OV.Count) := Switch_Value;
                              else
                                 return Parse_Result.New_Error
                                   (Too_Many_Values_Error
                                      (Max_Option_Values));
                              end if;
                           end;
                        elsif Arguments (Idx).Opt_Value /= null then
                           Arguments (Idx).Opt_Value.all := Switch_Value;
                        end if;

                     when Positional_Argument =>
                        --  Long switches cannot be positional
                        return Parse_Result.New_Error
                          (Unknown_Switch_Error (Arg));
                  end case;
               end;

            elsif Arg (Arg'First) = '-' and then Arg'Length >= 2 then
               --  Short switch(es)
               for I in Arg'First + 1 .. Arg'Last loop
                  declare
                     C   : constant Character := Arg (I);
                     Idx : constant Natural := Find_By_Short (C);
                  begin
                     if C = 'h' then
                        --  Built-in help short form
                        Show_Help;
                        return Parse_Result.New_Error
                          (Help_Requested_Error);
                     end if;

                     if Idx = 0 then
                        return Parse_Result.New_Error
                          (Unknown_Switch_Error ("-" & C));
                     end if;

                     --  Check command scope
                     if not Check_Scope (Idx) then
                        return Parse_Result.New_Error
                          (Command_Mismatch_Error
                             ("-" & C,
                              To_String (Arguments (Idx).Cmd_Scope)));
                     end if;

                     case Arguments (Idx).Kind is
                        when Flag_Argument =>
                           if Arguments (Idx).Flag_Set /= null then
                              Arguments (Idx).Flag_Set.all := True;
                           end if;
                           if Arguments (Idx).Flag_Count /= null then
                              Arguments (Idx).Flag_Count.all :=
                                Arguments (Idx).Flag_Count.all + 1;
                           end if;

                        when Option_Argument =>
                           --  Rest of arg or next arg is value
                           declare
                              Val : Value_String;
                           begin
                              if I < Arg'Last then
                                 --  Rest of this arg is the value
                                 Val := To_Value
                                   (Arg (I + 1 .. Arg'Last));
                              elsif Arg_Index
                                < Argument_Count
                              then
                                 --  Next arg is the value
                                 Arg_Index := Arg_Index + 1;
                                 Val := To_Value
                                   (Argument (Arg_Index));
                              else
                                 return Parse_Result.New_Error
                                   (Missing_Value_Error ("-" & C));
                              end if;

                              if Arguments (Idx).Opt_Has /= null then
                                 Arguments (Idx).Opt_Has.all := True;
                              end if;
                              if Arguments (Idx).Multiple
                                and then Arguments (Idx).Opt_Values /= null
                              then
                                 declare
                                    OV : constant access Value_Vector :=
                                      Arguments (Idx).Opt_Values;
                                 begin
                                    if OV.Count < OV.Capacity then
                                       OV.Count := OV.Count + 1;
                                       OV.Items (OV.Count) := Val;
                                    else
                                       return Parse_Result.New_Error
                                         (Too_Many_Values_Error
                                            (Max_Option_Values));
                                    end if;
                                 end;
                              elsif Arguments (Idx).Opt_Value /= null then
                                 Arguments (Idx).Opt_Value.all := Val;
                              end if;
                              exit;  --  Consumed rest of arg for value
                           end;

                        when Positional_Argument =>
                           return Parse_Result.New_Error
                             (Unknown_Switch_Error ("-" & C));
                     end case;
                  end;
               end loop;

            else
               --  Positional argument
               if Current_Pos_Arg > 0 and then
                  Current_Pos_Arg <= Registered_Count and then
                  Arguments (Current_Pos_Arg).Kind = Positional_Argument
               then
                  declare
                     PV : constant access Value_Vector :=
                       Arguments (Current_Pos_Arg).Pos_Values;
                  begin
                     if PV /= null and then PV.Count < PV.Capacity then
                        PV.Count := PV.Count + 1;
                        PV.Items (PV.Count) := To_Value (Arg);

                        --  Move to next positional if not Multiple
                        if not Arguments (Current_Pos_Arg).Multiple then
                           for J in Current_Pos_Arg + 1 ..
                             Registered_Count
                           loop
                              if Arguments (J).Kind =
                                Positional_Argument
                              then
                                 Current_Pos_Arg := J;
                                 exit;
                              end if;
                           end loop;
                        end if;
                     else
                        return Parse_Result.New_Error
                          (Too_Many_Values_Error
                             (Max_Positional_Values));
                     end if;
                  end;
               else
                  --  No positional argument registered
                  return Parse_Result.New_Error
                    (Unknown_Switch_Error (Arg));
               end if;
            end if;
         end;

         Arg_Index := Arg_Index + 1;
      end loop;

      --  Handle remaining arguments after "--" as positional
      while Arg_Index <= Argument_Count loop
         if Current_Pos_Arg > 0 and then
            Arguments (Current_Pos_Arg).Pos_Values /= null
         then
            declare
               PV : constant access Value_Vector :=
                 Arguments (Current_Pos_Arg).Pos_Values;
            begin
               if PV.Count < PV.Capacity then
                  PV.Count := PV.Count + 1;
                  PV.Items (PV.Count) :=
                    To_Value (Argument (Arg_Index));
               end if;
            end;
         end if;
         Arg_Index := Arg_Index + 1;
      end loop;

      --  Check required options (only global + active command)
      for I in 1 .. Registered_Count loop
         if Arguments (I).Kind = Option_Argument
           and then Arguments (I).Required
         then
            declare
               Is_Global : constant Boolean :=
                 Length (Arguments (I).Cmd_Scope) = 0;
               Is_Active_Cmd : constant Boolean :=
                 Active_Cmd_Index > 0
                 and then To_String (Arguments (I).Cmd_Scope) =
                          To_String (Commands (Active_Cmd_Index).Name);
            begin
               if (Is_Global or Is_Active_Cmd)
                 and then (Arguments (I).Opt_Has = null
                           or else not Arguments (I).Opt_Has.all)
               then
                  return Parse_Result.New_Error
                    (Missing_Required_Error
                       (To_String (Arguments (I).Long)));
               end if;
            end;
         end if;
      end loop;

      Parsed := True;
      return Parse_Result.Ok ((null record));
   end Parse;

   --  ==========================================================================
   --  Is_Parsed
   --  ==========================================================================

   function Is_Parsed return Boolean is
   begin
      return Parsed;
   end Is_Parsed;

   --  ==========================================================================
   --  Active_Command
   --  ==========================================================================

   function Active_Command return String is
      use Long_Switch_Strings;
   begin
      if Active_Cmd_Index > 0 then
         return To_String (Commands (Active_Cmd_Index).Name);
      else
         return "";
      end if;
   end Active_Command;

   --  ==========================================================================
   --  Print_Help
   --  ==========================================================================

   procedure Print_Help is
      use Ada.Text_IO;
      use Long_Switch_Strings;
      use Value_Name_Strings;
      use Help_Strings;
   begin
      --  Header
      Put_Line (App_Name & " - " & App_Description);
      New_Line;

      --  Usage line
      Put ("Usage: " & App_Name);
      if Registered_Cmd_Count > 0 then
         Put (" <COMMAND>");
      end if;
      Put (" [OPTIONS]");
      for I in 1 .. Registered_Count loop
         if Arguments (I).Kind = Positional_Argument then
            Put (" ");
            if Arguments (I).Multiple then
               Put ("[" & To_String (Arguments (I).Long) & "...]");
            else
               Put ("<" & To_String (Arguments (I).Long) & ">");
            end if;
         end if;
      end loop;
      New_Line;
      New_Line;

      --  Commands section
      if Registered_Cmd_Count > 0 then
         Put_Line ("Commands:");
         for I in 1 .. Registered_Cmd_Count loop
            Put ("  " & To_String (Commands (I).Name));
            if Length (Commands (I).Help_Text) > 0 then
               Put ("  " & To_String (Commands (I).Help_Text));
            end if;
            New_Line;
         end loop;
         New_Line;
      end if;

      --  Options section
      Put_Line ("Options:");
      Put_Line ("  -h, --help     Show this help message");
      Put_Line ("      --version  Show version information");

      for I in 1 .. Registered_Count loop
         case Arguments (I).Kind is
            when Flag_Argument =>
               Put ("  ");
               if Arguments (I).Short /= ASCII.NUL then
                  Put ("-" & Arguments (I).Short & ", ");
               else
                  Put ("    ");
               end if;
               Put ("--" & To_String (Arguments (I).Long));
               if Length (Arguments (I).Help_Text) > 0 then
                  Put ("  " & To_String (Arguments (I).Help_Text));
               end if;
               if Length (Arguments (I).Cmd_Scope) > 0 then
                  Put (" [" & To_String (Arguments (I).Cmd_Scope)
                       & " only]");
               end if;
               New_Line;

            when Option_Argument =>
               Put ("  ");
               if Arguments (I).Short /= ASCII.NUL then
                  Put ("-" & Arguments (I).Short & ", ");
               else
                  Put ("    ");
               end if;
               Put ("--" & To_String (Arguments (I).Long));
               Put ("=<" & To_String (Arguments (I).Value_Name) & ">");
               if Length (Arguments (I).Help_Text) > 0 then
                  Put ("  " & To_String (Arguments (I).Help_Text));
               end if;
               if Arguments (I).Required then
                  Put (" (required)");
               end if;
               if Arguments (I).Multiple then
                  Put (" (repeatable)");
               end if;
               if Length (Arguments (I).Cmd_Scope) > 0 then
                  Put (" [" & To_String (Arguments (I).Cmd_Scope)
                       & " only]");
               end if;
               New_Line;

            when Positional_Argument =>
               null;  --  Handled in Arguments section
         end case;
      end loop;

      --  Arguments section (positionals)
      declare
         Has_Positional : Boolean := False;
      begin
         for I in 1 .. Registered_Count loop
            if Arguments (I).Kind = Positional_Argument then
               Has_Positional := True;
               exit;
            end if;
         end loop;

         if Has_Positional then
            New_Line;
            Put_Line ("Arguments:");
            for I in 1 .. Registered_Count loop
               if Arguments (I).Kind = Positional_Argument then
                  Put ("  " & To_String (Arguments (I).Long));
                  if Length (Arguments (I).Help_Text) > 0 then
                     Put ("  " & To_String (Arguments (I).Help_Text));
                  end if;
                  New_Line;
               end if;
            end loop;
         end if;
      end;
   end Print_Help;

   --  ==========================================================================
   --  Print_Version
   --  ==========================================================================

   procedure Print_Version is
      use Ada.Text_IO;
   begin
      Put_Line (App_Name & " " & Clara.Version.Version);
   end Print_Version;

   --  ==========================================================================
   --  Command Child Generic Body
   --  ==========================================================================

   package body Command is

      --  Package state
      Is_Active_State : aliased Boolean := False;

      function Is_Active return Boolean is
      begin
         return Is_Active_State;
      end Is_Active;

   begin
      --  Register this command at elaboration
      Register_Command
        (Name       => Name,
         Help_Text  => Help,
         Active_Ptr => Is_Active_State'Access);
   end Command;

   --  ==========================================================================
   --  Flag Child Generic Body
   --  ==========================================================================

   package body Flag is

      --  Package state
      Is_Flag_Set   : aliased Boolean := False;
      Flag_Counter  : aliased Natural := 0;

      function Is_Set return Boolean is
      begin
         return Is_Flag_Set;
      end Is_Set;

      function Count return Natural is
      begin
         return Flag_Counter;
      end Count;

   begin
      --  Register this flag at elaboration
      Register_Flag
        (Short      => Short,
         Long       => Long,
         Help_Text  => Help,
         Cmd_Scope  => Command,
         Set_Ptr    => Is_Flag_Set'Access,
         Count_Ptr  => Flag_Counter'Access);
   end Flag;

   --  ==========================================================================
   --  Option Child Generic Body
   --  ==========================================================================

   package body Option is

      --  Package state
      Has_Val       : aliased Boolean := False;
      Stored_Val    : aliased Value_String := Value_Strings.Null_Bounded_String;
      Stored_Values : aliased Value_Vector
        ((if Multiple then Max_Option_Values else 1));

      function Has_Value return Boolean is
      begin
         return Has_Val;
      end Has_Value;

      function Has_Values return Boolean is
      begin
         return Has_Val;
      end Has_Values;

      function Value return String_Option.Option is
      begin
         if not Has_Val then
            return String_Option.None;
         end if;
         if Multiple then
            return String_Option.New_Some (Stored_Values.Items (1));
         else
            return String_Option.New_Some (Stored_Val);
         end if;
      end Value;

      function Value_Or (Default : String) return String is
         use Value_Strings;
      begin
         if not Has_Val then
            return Default;
         end if;
         if Multiple then
            return To_String (Stored_Values.Items (1));
         else
            return To_String (Stored_Val);
         end if;
      end Value_Or;

      function Count return Natural is
      begin
         if Multiple then
            return Stored_Values.Count;
         else
            return (if Has_Val then 1 else 0);
         end if;
      end Count;

      function First return Value_String is
      begin
         if Multiple then
            return Stored_Values.Items (1);
         else
            return Stored_Val;
         end if;
      end First;

      function Values return Value_Vector is
      begin
         if Multiple then
            return Stored_Values;
         else
            declare
               V : Value_Vector (1);
            begin
               if Has_Val then
                  V.Count := 1;
                  V.Items (1) := Stored_Val;
               end if;
               return V;
            end;
         end if;
      end Values;

   begin
      --  Register this option at elaboration
      Register_Option
        (Short      => Short,
         Long       => Long,
         Value_Name => Value_Name,
         Help_Text  => Help,
         Required   => Required,
         Cmd_Scope  => Command,
         Multiple   => Multiple,
         Has_Ptr    => Has_Val'Access,
         Value_Ptr  => (if Multiple then null else Stored_Val'Access),
         Values_Ptr => (if Multiple then Stored_Values'Access else null));
   end Option;

   --  ==========================================================================
   --  Positional Child Generic Body
   --  ==========================================================================

   package body Positional is

      --  Package state
      Stored_Values : aliased Value_Vector (Max_Positional_Values);

      function Has_Values return Boolean is
      begin
         return Stored_Values.Count > 0;
      end Has_Values;

      function Count return Natural is
      begin
         return Stored_Values.Count;
      end Count;

      function First return Value_String is
      begin
         return Stored_Values.Items (1);
      end First;

      function Values return Value_Vector is
      begin
         return Stored_Values;
      end Values;

   begin
      --  Register this positional at elaboration
      Register_Positional
        (Name       => Name,
         Help_Text  => Help,
         Multiple   => Multiple,
         Values_Ptr => Stored_Values'Access);
   end Positional;

end Clara.Application;
