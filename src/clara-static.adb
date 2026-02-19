pragma Ada_2022;
--  ===========================================================================
--  Clara.Static (Body) - SPARK-Provable Static CLI Implementation
--  ===========================================================================
--  Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
--  SPDX-License-Identifier: BSD-3-Clause
--  ===========================================================================

with Ada.Command_Line;
with Ada.Strings.Fixed;
with Clara.Version;

package body Clara.Static
  with SPARK_Mode => On
is

   use Ada.Command_Line;

   --  =========================================================================
   --  Internal Helper Functions
   --  =========================================================================

   function Starts_With (S : String; Prefix : String) return Boolean is
     (S'Length >= Prefix'Length
      and then S (S'First .. S'First + Prefix'Length - 1) = Prefix);

   function Strip_Prefix (S : String; Prefix : String) return String is
     (if Starts_With (S, Prefix)
      then S (S'First + Prefix'Length .. S'Last)
      else S);

   --  Find = in a string for --option=value parsing
   function Find_Equals (S : String) return Natural is
   begin
      for I in S'Range loop
         if S (I) = '=' then
            return I;
         end if;
      end loop;
      return 0;
   end Find_Equals;

   --  Match a flag definition against an argument
   function Matches_Flag
     (Arg : String;
      Def : Flag_Definition) return Boolean
   is
      Long_Str : constant String := Long_Switch_Strings.To_String (Def.Long);
   begin
      --  Check --long form
      if Starts_With (Arg, "--") then
         return Strip_Prefix (Arg, "--") = Long_Str;
      end if;

      --  Check -s short form (single char)
      if Arg'Length = 2
        and then Arg (Arg'First) = '-'
        and then Arg (Arg'First + 1) = Def.Short
        and then Def.Short /= ASCII.NUL
      then
         return True;
      end if;

      return False;
   end Matches_Flag;

   --  Match an option definition against an argument (without value)
   function Matches_Option_Name
     (Arg : String;
      Def : Option_Definition) return Boolean
   is
      Long_Str  : constant String := Long_Switch_Strings.To_String (Def.Long);
      Eq_Pos    : constant Natural := Find_Equals (Arg);
      Arg_Name  : constant String :=
        (if Eq_Pos > 0 then Arg (Arg'First .. Eq_Pos - 1) else Arg);
   begin
      --  Check --long or --long=value form
      if Starts_With (Arg_Name, "--") then
         return Strip_Prefix (Arg_Name, "--") = Long_Str;
      end if;

      --  Check -s short form
      if Arg_Name'Length = 2
        and then Arg_Name (Arg_Name'First) = '-'
        and then Arg_Name (Arg_Name'First + 1) = Def.Short
        and then Def.Short /= ASCII.NUL
      then
         return True;
      end if;

      return False;
   end Matches_Option_Name;

   --  Extract value from --option=value or return empty
   function Extract_Inline_Value (Arg : String) return String is
      Eq_Pos : constant Natural := Find_Equals (Arg);
   begin
      if Eq_Pos > 0 and then Eq_Pos < Arg'Last then
         return Arg (Eq_Pos + 1 .. Arg'Last);
      else
         return "";
      end if;
   end Extract_Inline_Value;

   --  Check if argument looks like a switch (starts with -)
   function Is_Switch (Arg : String) return Boolean is
     (Arg'Length > 0 and then Arg (Arg'First) = '-');

   --  =========================================================================
   --  Parse Implementation
   --  =========================================================================

   function Parse (Config : CLI_Config) return Parse_Result.Result is
      Results   : Parse_Results;
      Arg_Index : Positive := 1;
      Arg_Count : constant Natural := Argument_Count;

      --  Track which positional we're filling
      Current_Positional : Positional_Names := Positional_Names'First;
      Positional_Done    : Boolean := False;

      --  Track pending option (waiting for value in next arg)
      type Pending_Option is record
         Active : Boolean := False;
         Which  : Option_Names := Option_Names'First;
      end record;
      Pending : Pending_Option := (Active => False, others => <>);

   begin
      --  Initialize results
      for F in Flag_Names loop
         Results.Flags (F) := (Is_Set => False, Count => 0);
      end loop;

      for O in Option_Names loop
         Results.Options (O) := Option_Value.None;
      end loop;

      for P in Positional_Names loop
         Results.Positionals (P) := (Capacity => Max_Positional_Values,
                                      Items    => [others => Value_Strings.Null_Bounded_String],
                                      Count    => 0);
      end loop;

      --  Process each argument
      while Arg_Index <= Arg_Count loop
         declare
            Arg : constant String := Argument (Arg_Index);
            Matched : Boolean := False;
         begin
            --  Handle pending option value
            if Pending.Active then
               Results.Options (Pending.Which) :=
                 Option_Value.New_Some (To_Value (Arg));
               Pending.Active := False;
               Matched := True;

            --  Check for --help
            elsif Arg = "--help" or else Arg = "-h" then
               Results.Help_Requested := True;
               Matched := True;

            --  Check for --version
            elsif Arg = "--version" or else Arg = "-V" then
               Results.Version_Requested := True;
               Matched := True;

            --  Check flags
            elsif not Matched and then Is_Switch (Arg) then
               for F in Flag_Names loop
                  if Matches_Flag (Arg, Config.Flags (F)) then
                     Results.Flags (F).Is_Set := True;
                     Results.Flags (F).Count :=
                       Results.Flags (F).Count + 1;
                     Matched := True;
                     exit;
                  end if;
               end loop;
            end if;

            --  Check options
            if not Matched and then Is_Switch (Arg) then
               for O in Option_Names loop
                  if Matches_Option_Name (Arg, Config.Options (O)) then
                     declare
                        Inline_Val : constant String := Extract_Inline_Value (Arg);
                     begin
                        if Inline_Val'Length > 0 then
                           --  --option=value form
                           Results.Options (O) :=
                             Option_Value.New_Some (To_Value (Inline_Val));
                        else
                           --  --option value form (value in next arg)
                           Pending := (Active => True, Which => O);
                        end if;
                        Matched := True;
                        exit;
                     end;
                  end if;
               end loop;
            end if;

            --  Unknown switch
            if not Matched and then Is_Switch (Arg) then
               return Parse_Result.New_Error
                 ((Kind    => Unknown_Switch,
                   Message => To_Message ("Unknown option: " & Arg),
                   Context => To_Value (Arg)));
            end if;

            --  Positional argument
            if not Matched and then not Positional_Done then
               declare
                  Pos_Def : Positional_Definition renames
                    Config.Positionals (Current_Positional);
                  Pos_Res : Positional_Values renames
                    Results.Positionals (Current_Positional);
               begin
                  if Pos_Res.Count < Pos_Res.Capacity then
                     Pos_Res.Count := Pos_Res.Count + 1;
                     Pos_Res.Items (Pos_Res.Count) := To_Value (Arg);
                     Matched := True;

                     --  Move to next positional if not multiple
                     if not Pos_Def.Multiple then
                        if Current_Positional < Positional_Names'Last then
                           Current_Positional :=
                             Positional_Names'Succ (Current_Positional);
                        else
                           Positional_Done := True;
                        end if;
                     end if;
                  end if;
               end;
            end if;

            --  Unhandled argument
            if not Matched then
               return Parse_Result.New_Error
                 ((Kind    => Invalid_Value,
                   Message => To_Message ("Unexpected argument: " & Arg),
                   Context => To_Value (Arg)));
            end if;
         end;

         Arg_Index := Arg_Index + 1;
      end loop;

      --  Check for pending option without value
      if Pending.Active then
         declare
            Opt_Name : constant String :=
              Long_Switch_Strings.To_String
                (Config.Options (Pending.Which).Long);
         begin
            return Parse_Result.New_Error
              ((Kind    => Missing_Value,
                Message => To_Message ("Option --" & Opt_Name &
                                        " requires a value"),
                Context => To_Value ("--" & Opt_Name)));
         end;
      end if;

      --  Check required options
      for O in Option_Names loop
         if Config.Options (O).Required
           and then Option_Value.Is_None (Results.Options (O))
         then
            declare
               Opt_Name : constant String :=
                 Long_Switch_Strings.To_String (Config.Options (O).Long);
            begin
               return Parse_Result.New_Error
                 ((Kind    => Missing_Required,
                   Message => To_Message ("Required option --" & Opt_Name &
                                           " not provided"),
                   Context => To_Value ("--" & Opt_Name)));
            end;
         end if;
      end loop;

      return Parse_Result.Ok (Results);
   end Parse;

   --  =========================================================================
   --  Help Text Generation
   --  =========================================================================

   function Help_Text (Config : CLI_Config) return String is
      use Ada.Strings.Fixed;
      NL : constant Character := ASCII.LF;

      Result : String (1 .. 4096) := [others => ' '];
      Pos    : Natural := 0;

      procedure Append (S : String) is
      begin
         if Pos + S'Length <= Result'Last then
            Result (Pos + 1 .. Pos + S'Length) := S;
            Pos := Pos + S'Length;
         end if;
      end Append;

   begin
      Append (App_Name & " - " & App_Description & NL & NL);
      Append ("Usage: " & App_Name & " [OPTIONS]");

      --  Add positional names to usage
      for P in Positional_Names loop
         declare
            Name_Str : constant String :=
              Name_Strings.To_String (Config.Positionals (P).Name);
         begin
            if Config.Positionals (P).Multiple then
               Append (" [" & Name_Str & "...]");
            else
               Append (" [" & Name_Str & "]");
            end if;
         end;
      end loop;
      Append (NL & NL);

      --  Flags section
      Append ("Flags:" & NL);
      for F in Flag_Names loop
         declare
            Def : Flag_Definition renames Config.Flags (F);
            Long_Str : constant String := Long_Switch_Strings.To_String (Def.Long);
            Help_Str : constant String := Help_Strings.To_String (Def.Help);
         begin
            if Def.Short /= ASCII.NUL then
               Append ("  -" & Def.Short & ", --" & Long_Str);
            else
               Append ("      --" & Long_Str);
            end if;
            if Help_Str'Length > 0 then
               Append ("  " & Help_Str);
            end if;
            Append ("" & NL);
         end;
      end loop;
      Append ("" & NL);

      --  Options section
      Append ("Options:" & NL);
      for O in Option_Names loop
         declare
            Def : Option_Definition renames Config.Options (O);
            Long_Str  : constant String := Long_Switch_Strings.To_String (Def.Long);
            Value_Str : constant String := Value_Name_Strings.To_String (Def.Value_Name);
            Help_Str  : constant String := Help_Strings.To_String (Def.Help);
         begin
            if Def.Short /= ASCII.NUL then
               Append ("  -" & Def.Short & ", --" & Long_Str & "=<" & Value_Str & ">");
            else
               Append ("      --" & Long_Str & "=<" & Value_Str & ">");
            end if;
            if Help_Str'Length > 0 then
               Append ("  " & Help_Str);
            end if;
            if Def.Required then
               Append (" (required)");
            end if;
            Append ("" & NL);
         end;
      end loop;

      return Result (1 .. Pos);
   end Help_Text;

   --  =========================================================================
   --  Version Text
   --  =========================================================================

   function Version_Text return String is
   begin
      return App_Name & " version " & Clara.Version.Version;
   end Version_Text;

   --  =========================================================================
   --  Get_Option_Or
   --  =========================================================================

   function Get_Option_Or
     (Results : Parse_Results;
      Opt     : Option_Names;
      Default : String) return Value_String
   is
   begin
      if Option_Value.Is_Some (Results.Options (Opt)) then
         return Option_Value.Value (Results.Options (Opt));
      else
         return To_Value (Default);
      end if;
   end Get_Option_Or;

end Clara.Static;
