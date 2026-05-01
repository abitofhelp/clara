pragma Ada_2022;
--  ===========================================================================
--  Clara.CLI - Generic Command-Line Parser (Body)
--  ===========================================================================
--  Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
--  SPDX-License-Identifier: BSD-3-Clause
--  ===========================================================================

with Ada.Command_Line;

package body Clara.CLI is

   --  ==========================================================================
   --  Convenience Constructors
   --  ==========================================================================

   function Cmd
     (Name : String;
      Help : String := "") return Command_Def
   is
   begin
      return
        (Name => To_Switch (Name),
         Help => To_Help (Help));
   end Cmd;

   function Flag
     (Short : Character := ASCII.NUL;
      Long  : String;
      Help  : String := "") return Flag_Def
   is
   begin
      return
        (Short     => Short,
         Long      => To_Switch (Long),
         Help      => To_Help (Help),
         Is_Scoped => False,
         Scope     => Command_Id'First);
   end Flag;

   function Flag
     (Short : Character := ASCII.NUL;
      Long  : String;
      Help  : String := "";
      Scope : Command_Id) return Flag_Def
   is
   begin
      return
        (Short     => Short,
         Long      => To_Switch (Long),
         Help      => To_Help (Help),
         Is_Scoped => True,
         Scope     => Scope);
   end Flag;

   function Opt
     (Short      : Character := ASCII.NUL;
      Long       : String;
      Value_Name : String  := "VALUE";
      Help       : String  := "";
      Required   : Boolean := False;
      Multiple   : Boolean := False) return Option_Def
   is
   begin
      return
        (Short      => Short,
         Long       => To_Switch (Long),
         Value_Name => To_VName (Value_Name),
         Help       => To_Help (Help),
         Required   => Required,
         Multiple   => Multiple,
         Is_Scoped  => False,
         Scope      => Command_Id'First);
   end Opt;

   function Opt
     (Short      : Character := ASCII.NUL;
      Long       : String;
      Value_Name : String     := "VALUE";
      Help       : String     := "";
      Required   : Boolean    := False;
      Multiple   : Boolean    := False;
      Scope      : Command_Id) return Option_Def
   is
   begin
      return
        (Short      => Short,
         Long       => To_Switch (Long),
         Value_Name => To_VName (Value_Name),
         Help       => To_Help (Help),
         Required   => Required,
         Multiple   => Multiple,
         Is_Scoped  => True,
         Scope      => Scope);
   end Opt;

   function Pos
     (Name     : String;
      Help     : String  := "";
      Multiple : Boolean := False) return Positional_Def
   is
   begin
      return
        (Name     => To_Switch (Name),
         Help     => To_Help (Help),
         Multiple => Multiple);
   end Pos;

   --  ==========================================================================
   --  Internal Helpers
   --  ==========================================================================

   function Switch_To_String (S : Switch_String) return String
     renames Switch_Strings.To_String;

   function Find_Flag_By_Short
     (Config : CLI_Config;
      C      : Character) return Flag_Id
   is
   begin
      for F in Flag_Id loop
         if Config.Flags (F).Short = C then
            return F;
         end if;
      end loop;
      return Flag_Id'First;  --  Sentinel; caller checks Short match
   end Find_Flag_By_Short;

   function Has_Flag_Short
     (Config : CLI_Config;
      C      : Character) return Boolean
   is
   begin
      for F in Flag_Id loop
         if Config.Flags (F).Short = C then
            return True;
         end if;
      end loop;
      return False;
   end Has_Flag_Short;

   function Find_Option_By_Short
     (Config : CLI_Config;
      C      : Character) return Option_Id
   is
   begin
      for O in Option_Id loop
         if Config.Options (O).Short = C then
            return O;
         end if;
      end loop;
      return Option_Id'First;  --  Sentinel; caller checks Short match
   end Find_Option_By_Short;

   function Has_Option_Short
     (Config : CLI_Config;
      C      : Character) return Boolean
   is
   begin
      for O in Option_Id loop
         if Config.Options (O).Short = C then
            return True;
         end if;
      end loop;
      return False;
   end Has_Option_Short;

   type Long_Match_Kind is (Match_Flag, Match_Option, Match_None);

   type Long_Match is record
      Kind      : Long_Match_Kind := Match_None;
      Flag_Idx  : Flag_Id         := Flag_Id'First;
      Opt_Idx   : Option_Id       := Option_Id'First;
   end record;

   function Find_By_Long
     (Config : CLI_Config;
      Name   : String) return Long_Match
   is
   begin
      for F in Flag_Id loop
         if Switch_To_String (Config.Flags (F).Long) = Name then
            return (Kind => Match_Flag, Flag_Idx => F,
                    Opt_Idx => Option_Id'First);
         end if;
      end loop;
      for O in Option_Id loop
         if Switch_To_String (Config.Options (O).Long) = Name then
            return (Kind => Match_Option, Flag_Idx => Flag_Id'First,
                    Opt_Idx => O);
         end if;
      end loop;
      return (Kind => Match_None, Flag_Idx => Flag_Id'First,
              Opt_Idx => Option_Id'First);
   end Find_By_Long;

   function Check_Flag_Scope
     (Config    : CLI_Config;
      F         : Flag_Id;
      Active    : Command_Id;
      Has_Cmd   : Boolean) return Boolean
   is
   begin
      if not Config.Flags (F).Is_Scoped then
         return True;  --  Global flag, always allowed
      end if;
      if not Has_Cmd then
         return False;  --  Scoped flag but no command is active
      end if;
      return Config.Flags (F).Scope = Active;
   end Check_Flag_Scope;

   function Check_Option_Scope
     (Config    : CLI_Config;
      O         : Option_Id;
      Active    : Command_Id;
      Has_Cmd   : Boolean) return Boolean
   is
   begin
      if not Config.Options (O).Is_Scoped then
         return True;  --  Global option, always allowed
      end if;
      if not Has_Cmd then
         return False;  --  Scoped option but no command is active
      end if;
      return Config.Options (O).Scope = Active;
   end Check_Option_Scope;

   --  ==========================================================================
   --  From_Command_Line
   --  ==========================================================================

   function From_Command_Line return Argument_Array is
      Count : constant Natural := Ada.Command_Line.Argument_Count;
   begin
      if Count = 0 then
         declare
            Empty : Argument_Array (1 .. 0);
         begin
            return Empty;
         end;
      end if;

      declare
         Result : Argument_Array (1 .. Count);
      begin
         for I in 1 .. Count loop
            Result (I) :=
              To_Unbounded_String (Ada.Command_Line.Argument (I));
         end loop;
         return Result;
      end;
   end From_Command_Line;

   --  ==========================================================================
   --  Phase 1: Find Command
   --  ==========================================================================

   procedure Find_Active_Command
     (Config   : CLI_Config;
      Args     : Argument_Array;
      R        : in out Parse_Results;
      Cmd_Pos  : out Natural)
   is
      I : Positive := Args'First;
   begin
      Cmd_Pos := 0;

      while I <= Args'Last loop
         declare
            Arg : constant String := To_String (Args (I));
         begin
            if Arg = "--" then
               return;  --  End of switches; no command found

            elsif Arg'Length >= 2
              and then Arg (Arg'First .. Arg'First + 1) = "--"
            then
               --  Long switch; value is always in same token (= syntax)
               I := I + 1;

            elsif Arg'Length >= 2 and then Arg (Arg'First) = '-' then
               --  Short switch(es). Check if last char is an option
               --  that would consume the next argument.
               declare
                  Consumed_Next : Boolean := False;
               begin
                  for J in Arg'First + 1 .. Arg'Last loop
                     if Has_Option_Short (Config, Arg (J)) then
                        if J = Arg'Last then
                           Consumed_Next := True;
                        end if;
                        exit;
                     end if;
                  end loop;

                  I := I + 1;
                  if Consumed_Next and then I <= Args'Last then
                     I := I + 1;
                  end if;
               end;

            else
               --  Non-switch. Check against registered commands.
               for C in Command_Id loop
                  if Arg = Switch_To_String (Config.Commands (C).Name) then
                     R.Has_Active_Command := True;
                     R.Active_Cmd := C;
                     R.Commands (C) := True;
                     Cmd_Pos := I;
                     return;
                  end if;
               end loop;

               --  Not a command; continue scanning
               I := I + 1;
            end if;
         end;
      end loop;
   end Find_Active_Command;

   --  ==========================================================================
   --  Parse (with explicit argument array)
   --  ==========================================================================

   function Parse
     (Config : CLI_Config;
      Args   : Argument_Array) return Parse_Outcome.Result
   is
      R       : Parse_Results;
      Cmd_Pos : Natural := 0;

      --  Positional tracking
      Cur_Pos : Positional_Id := Positional_Id'First;
      Pos_Exhausted : Boolean := False;

      procedure Advance_Positional is
      begin
         if Config.Positionals (Cur_Pos).Multiple then
            return;  --  Stay on same positional
         end if;
         if Cur_Pos < Positional_Id'Last then
            Cur_Pos := Positional_Id'Succ (Cur_Pos);
         else
            Pos_Exhausted := True;
         end if;
      end Advance_Positional;

      procedure Store_Positional (Val : String) is
      begin
         if Pos_Exhausted then
            return;  --  Caller should check and error
         end if;
         R.Positionals (Cur_Pos).Values.Append (To_Unbounded_String (Val));
         Advance_Positional;
      end Store_Positional;

      Arg_Index : Positive := Args'First;

   begin
      --  Phase 1: Find active command
      Find_Active_Command (Config, Args, R, Cmd_Pos);

      --  Phase 2: Parse all arguments
      while Arg_Index <= Args'Last loop
         declare
            Arg : constant String := To_String (Args (Arg_Index));
            Is_Command_Word : constant Boolean :=
              R.Has_Active_Command and then Arg_Index = Cmd_Pos;
         begin
            if Is_Command_Word then
               --  Skip command word (already processed in Phase 1)
               null;

            elsif Arg'Length = 0 then
               null;  --  Empty argument, skip

            elsif Arg = "--" then
               --  Rest are positional
               Arg_Index := Arg_Index + 1;
               exit;

            elsif Arg'Length >= 2
              and then Arg (Arg'First .. Arg'First + 1) = "--"
            then
               --  Long switch
               declare
                  Rest       : constant String :=
                    Arg (Arg'First + 2 .. Arg'Last);
                  Equals_Pos : Natural := 0;
               begin
                  for I in Rest'Range loop
                     if Rest (I) = '=' then
                        Equals_Pos := I;
                        exit;
                     end if;
                  end loop;

                  declare
                     Name : constant String :=
                       (if Equals_Pos > 0
                        then Rest (Rest'First .. Equals_Pos - 1)
                        else Rest);
                     Has_Eq : constant Boolean := Equals_Pos > 0;
                     Eq_Val : constant String :=
                       (if Has_Eq
                        then Rest (Equals_Pos + 1 .. Rest'Last)
                        else "");
                  begin
                     --  Built-in: --help, --version.  Both surface as
                     --  pure outcome signals; consumers render help /
                     --  version after Parse returns.  No mid-parse
                     --  callback (the Show_Help formal was removed).
                     if Name = "help" then
                        return Parse_Outcome.New_Error
                          (Help_Requested_Error);
                     elsif Name = "version" then
                        return Parse_Outcome.New_Error
                          (Version_Requested_Error);
                     end if;

                     declare
                        M : constant Long_Match :=
                          Find_By_Long (Config, Name);
                     begin
                        case M.Kind is
                           when Match_None =>
                              return Parse_Outcome.New_Error
                                (Unknown_Switch_Error (Arg));

                           when Match_Flag =>
                              if not Check_Flag_Scope
                                (Config, M.Flag_Idx,
                                 R.Active_Cmd,
                                 R.Has_Active_Command)
                              then
                                 return Parse_Outcome.New_Error
                                   (Command_Mismatch_Error
                                      (Arg,
                                       Switch_To_String
                                         (Config.Commands
                                            (Config.Flags
                                               (M.Flag_Idx).Scope).Name)));
                              end if;

                              R.Flags (M.Flag_Idx).Is_Set := True;
                              R.Flags (M.Flag_Idx).Count :=
                                R.Flags (M.Flag_Idx).Count + 1;

                           when Match_Option =>
                              if not Check_Option_Scope
                                (Config, M.Opt_Idx,
                                 R.Active_Cmd,
                                 R.Has_Active_Command)
                              then
                                 return Parse_Outcome.New_Error
                                   (Command_Mismatch_Error
                                      (Arg,
                                       Switch_To_String
                                         (Config.Commands
                                            (Config.Options
                                               (M.Opt_Idx).Scope).Name)));
                              end if;

                              if not Has_Eq then
                                 return Parse_Outcome.New_Error
                                   (Make_Error
                                      (Missing_Value,
                                       "Long option requires '=' syntax"
                                       & " (e.g., --" & Name & "=VALUE)",
                                       Arg));
                              end if;

                              R.Options (M.Opt_Idx).Has_Value := True;
                              if Config.Options (M.Opt_Idx).Multiple then
                                 R.Options (M.Opt_Idx).Values.Append
                                   (To_Unbounded_String (Eq_Val));
                              end if;
                              R.Options (M.Opt_Idx).Value :=
                                To_Unbounded_String (Eq_Val);
                        end case;
                     end;
                  end;
               end;

            elsif Arg (Arg'First) = '-' and then Arg'Length >= 2 then
               --  Short switch(es)
               declare
                  I : Positive := Arg'First + 1;
               begin
                  while I <= Arg'Last loop
                     declare
                        C : constant Character := Arg (I);
                     begin
                        --  Built-in: -h (matches the long --help
                        --  built-in; pure outcome signal, no mid-parse
                        --  callback).
                        if C = 'h' then
                           return Parse_Outcome.New_Error
                             (Help_Requested_Error);
                        end if;

                        if Has_Flag_Short (Config, C) then
                           declare
                              F : constant Flag_Id :=
                                Find_Flag_By_Short (Config, C);
                           begin
                              if not Check_Flag_Scope
                                (Config, F, R.Active_Cmd,
                                 R.Has_Active_Command)
                              then
                                 return Parse_Outcome.New_Error
                                   (Command_Mismatch_Error
                                      ("-" & C,
                                       Switch_To_String
                                         (Config.Commands
                                            (Config.Flags
                                               (F).Scope).Name)));
                              end if;

                              R.Flags (F).Is_Set := True;
                              R.Flags (F).Count :=
                                R.Flags (F).Count + 1;
                           end;

                        elsif Has_Option_Short (Config, C) then
                           declare
                              O   : constant Option_Id :=
                                Find_Option_By_Short (Config, C);
                              Val : Unbounded_String;
                           begin
                              if not Check_Option_Scope
                                (Config, O, R.Active_Cmd,
                                 R.Has_Active_Command)
                              then
                                 return Parse_Outcome.New_Error
                                   (Command_Mismatch_Error
                                      ("-" & C,
                                       Switch_To_String
                                         (Config.Commands
                                            (Config.Options
                                               (O).Scope).Name)));
                              end if;

                              if I < Arg'Last then
                                 --  Rest of token is the value
                                 Val := To_Unbounded_String
                                   (Arg (I + 1 .. Arg'Last));
                              elsif Arg_Index < Args'Last then
                                 --  Next argument is the value
                                 Arg_Index := Arg_Index + 1;
                                 Val := Args (Arg_Index);
                              else
                                 return Parse_Outcome.New_Error
                                   (Missing_Value_Error ("-" & C));
                              end if;

                              R.Options (O).Has_Value := True;
                              if Config.Options (O).Multiple then
                                 R.Options (O).Values.Append (Val);
                              end if;
                              R.Options (O).Value := Val;
                              exit;  --  Rest consumed as value
                           end;

                        else
                           return Parse_Outcome.New_Error
                             (Unknown_Switch_Error ("-" & C));
                        end if;
                     end;
                     I := I + 1;
                  end loop;
               end;

            else
               --  Positional argument
               if Pos_Exhausted then
                  return Parse_Outcome.New_Error
                    (Unknown_Switch_Error (Arg));
               end if;
               Store_Positional (Arg);
            end if;
         end;

         Arg_Index := Arg_Index + 1;
      end loop;

      --  Handle remaining arguments after "--" as positional
      while Arg_Index <= Args'Last loop
         if Pos_Exhausted then
            return Parse_Outcome.New_Error
              (Too_Many_Values_Error (Positional_Id'Pos (Cur_Pos) + 1));
         end if;
         Store_Positional (To_String (Args (Arg_Index)));
         Arg_Index := Arg_Index + 1;
      end loop;

      --  Validation: check required options
      for O in Option_Id loop
         if Config.Options (O).Required then
            declare
               In_Scope : constant Boolean :=
                 Check_Option_Scope
                   (Config, O, R.Active_Cmd, R.Has_Active_Command);
            begin
               if In_Scope and then not R.Options (O).Has_Value then
                  return Parse_Outcome.New_Error
                    (Missing_Required_Error
                       (Switch_To_String (Config.Options (O).Long)));
               end if;
            end;
         end if;
      end loop;

      return Parse_Outcome.Ok (R);
   end Parse;

   --  ==========================================================================
   --  Parse (convenience: reads Ada.Command_Line)
   --  ==========================================================================

   function Parse (Config : CLI_Config) return Parse_Outcome.Result is
   begin
      return Parse (Config, From_Command_Line);
   end Parse;

end Clara.CLI;
