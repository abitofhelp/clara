pragma Ada_2022;

with Ada.Text_IO;   use Ada.Text_IO;
with Clara.Version;

package body Test_Version is

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
      Put_Line ("--- Test_Version ---");

      Assert (Clara.Version.Major = 1, "Major is 1");
      Assert (Clara.Version.Minor = 0, "Minor is 0");
      Assert (Clara.Version.Patch = 0, "Patch is 0");
      Assert (Clara.Version.Version = "1.0.0", "Version is 1.0.0");
      Assert
        (Clara.Version.Prerelease = "",
         "Prerelease is empty for stable");
      Assert
        (not Clara.Version.Is_Prerelease,
         "Is_Prerelease is False for stable");
      Assert
        (not Clara.Version.Is_Development,
         "Is_Development is False for stable");
      Assert (Clara.Version.Is_Stable, "Is_Stable is True for 1.0.0");

      Total := Total_Count;
      Passed := Passed_Count;
   end Run;

end Test_Version;
