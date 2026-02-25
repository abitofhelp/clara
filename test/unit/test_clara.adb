pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Clara;

package body Test_Clara is

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
      Put_Line ("--- Test_Clara ---");

      Assert
        (Clara.Library_Name = "CLARA",
         "Library_Name is CLARA");
      Assert
        (Clara.Acronym'Length > 0,
         "Acronym is not empty");
      Assert
        (Clara.Acronym (Clara.Acronym'First ..
           Clara.Acronym'First + 11) = "Command Line",
         "Acronym starts with Command Line");

      Total := Total_Count;
      Passed := Passed_Count;
   end Run;

end Test_Clara;
