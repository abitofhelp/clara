pragma Ada_2022;

with Ada.Text_IO;           use Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Clara.Errors;          use Clara.Errors;

package body Test_Errors is

   Total_Count  : Natural := 0;
   Passed_Count : Natural := 0;

   procedure Assert (Condition : Boolean; Name : String) is
   begin
      Total_Count := Total_Count + 1;
      if Condition then
         Passed_Count := Passed_Count + 1;
         Put_Line ("  [PASS] " & Name);
      else
         Put_Line ("  [FAIL] " & Name);
      end if;
   end Assert;

   procedure Run (Total : out Natural; Passed : out Natural) is
   begin
      Total_Count := 0;
      Passed_Count := 0;
      Put_Line ("--- Test_Errors ---");

      --  Make_Error
      declare
         E : constant Parse_Error :=
           Make_Error (Unknown_Switch, "test msg", "--foo");
      begin
         Assert (E.Kind = Unknown_Switch, "Make_Error sets Kind");
         Assert
           (To_String (E.Message) = "test msg",
            "Make_Error sets Message");
         Assert
           (To_String (E.Context) = "--foo",
            "Make_Error sets Context");
      end;

      --  Unknown_Switch_Error
      declare
         E : constant Parse_Error := Unknown_Switch_Error ("--bar");
      begin
         Assert
           (E.Kind = Unknown_Switch,
            "Unknown_Switch_Error kind");
         Assert
           (To_String (E.Context) = "--bar",
            "Unknown_Switch_Error context");
      end;

      --  Missing_Value_Error
      declare
         E : constant Parse_Error := Missing_Value_Error ("--output");
      begin
         Assert (E.Kind = Missing_Value, "Missing_Value_Error kind");
      end;

      --  Missing_Required_Error
      declare
         E : constant Parse_Error := Missing_Required_Error ("config");
      begin
         Assert
           (E.Kind = Missing_Required,
            "Missing_Required_Error kind");
         Assert
           (To_String (E.Context) = "config",
            "Missing_Required_Error context");
      end;

      --  Too_Many_Values_Error
      declare
         E : constant Parse_Error := Too_Many_Values_Error (10);
      begin
         Assert
           (E.Kind = Too_Many_Values,
            "Too_Many_Values_Error kind");
      end;

      --  Command_Mismatch_Error
      declare
         E : constant Parse_Error :=
           Command_Mismatch_Error ("-y", "write");
      begin
         Assert
           (E.Kind = Command_Mismatch,
            "Command_Mismatch_Error kind");
         Assert
           (To_String (E.Context) = "-y",
            "Command_Mismatch_Error context");
      end;

      --  Help_Requested_Error
      declare
         E : constant Parse_Error := Help_Requested_Error;
      begin
         Assert (E.Kind = Help_Requested, "Help_Requested_Error kind");
         Assert
           (Length (E.Message) = 0,
            "Help_Requested has empty message");
      end;

      --  Version_Requested_Error
      declare
         E : constant Parse_Error := Version_Requested_Error;
      begin
         Assert
           (E.Kind = Version_Requested,
            "Version_Requested_Error kind");
      end;

      --  Is_Graceful_Exit
      Assert
        (Is_Graceful_Exit (Help_Requested_Error),
         "Help is graceful exit");
      Assert
        (Is_Graceful_Exit (Version_Requested_Error),
         "Version is graceful exit");
      Assert
        (not Is_Graceful_Exit (Unknown_Switch_Error ("--x")),
         "Unknown_Switch is not graceful exit");

      --  Is_User_Error
      Assert
        (Is_User_Error (Unknown_Switch_Error ("--x")),
         "Unknown_Switch is user error");
      Assert
        (Is_User_Error (Missing_Value_Error ("--o")),
         "Missing_Value is user error");
      Assert
        (not Is_User_Error (Help_Requested_Error),
         "Help_Requested is not user error");

      --  Format
      declare
         E1 : constant Parse_Error :=
           Make_Error (Unknown_Switch, "Bad switch", "--foo");
         E2 : constant Parse_Error :=
           Make_Error (Internal_Error, "Something broke");
         E3 : constant Parse_Error :=
           (Kind => None, others => <>);
      begin
         Assert
           (Format (E1) = "Bad switch: --foo",
            "Format with context");
         Assert
           (Format (E2) = "Something broke",
            "Format without context");
         Assert
           (Format (E3) = "",
            "Format of None error is empty");
      end;

      Total := Total_Count;
      Passed := Passed_Count;
   end Run;

end Test_Errors;
