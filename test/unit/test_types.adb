pragma Ada_2022;

with Ada.Text_IO;           use Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Clara.Types;           use Clara.Types;

package body Test_Types is

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
      Put_Line ("--- Test_Types ---");

      --  Bounded metadata string lengths
      Assert (Max_Long_Switch = 64, "Max_Long_Switch is 64");
      Assert (Max_Help = 256, "Max_Help is 256");
      Assert (Max_Value_Name = 16, "Max_Value_Name is 16");

      --  Switch_String conversions
      declare
         S : constant Switch_String := To_Switch ("verbose");
      begin
         Assert
           (Switch_Strings.To_String (S) = "verbose",
            "To_Switch round-trips");
         Assert
           (Switch_Strings.Length (S) = 7,
            "Switch_String length is correct");
      end;

      --  Help_String conversions
      declare
         H : constant Help_String := To_Help ("Enable verbose output");
      begin
         Assert
           (Help_Strings.To_String (H) = "Enable verbose output",
            "To_Help round-trips");
      end;

      --  VName_String conversions
      declare
         V : constant VName_String := To_VName ("FILE");
      begin
         Assert
           (VName_Strings.To_String (V) = "FILE",
            "To_VName round-trips");
      end;

      --  Value_String (Unbounded)
      declare
         V : constant Value_String := To_Value ("hello world");
      begin
         Assert
           (Value_To_String (V) = "hello world",
            "To_Value/Value_To_String round-trips");
      end;

      --  Null_Value
      Assert
        (Value_To_String (Null_Value) = "",
         "Null_Value is empty string");

      --  Value_List (Vector)
      declare
         VL : Value_List;
      begin
         Assert (VL.Is_Empty, "Value_List starts empty");
         Assert (Natural (VL.Length) = 0, "Value_List length is 0");

         VL.Append (To_Value ("first"));
         VL.Append (To_Value ("second"));

         Assert (not VL.Is_Empty, "Value_List not empty after append");
         Assert
           (Natural (VL.Length) = 2,
            "Value_List length is 2 after 2 appends");
         Assert
           (To_String (VL.First_Element) = "first",
            "First element is correct");
         Assert
           (To_String (VL.Last_Element) = "second",
            "Last element is correct");
      end;

      --  Large value strings (no bounded limit)
      declare
         Big : constant String (1 .. 8192) := [others => 'X'];
         V   : constant Value_String := To_Value (Big);
      begin
         Assert
           (Length (V) = 8192,
            "Value_String handles 8192-char string");
      end;

      Total := Total_Count;
      Passed := Passed_Count;
   end Run;

end Test_Types;
