pragma Ada_2022;
--  ===========================================================================
--  Integration Test Runner for Clara
--  ===========================================================================

with Ada.Text_IO;    use Ada.Text_IO;
with Ada.Command_Line;
with Test_Framework;
with Test_Integration;

procedure Integration_Runner is
   Total, Passed : Natural;
   Exit_Code     : Integer;
begin
   Test_Framework.Reset;

   Test_Integration.Run (Total, Passed);
   Put_Line ("Passed:" & Passed'Image & "  Failed:" &
             Natural'Image (Total - Passed));
   Test_Framework.Register_Results (Total, Passed);

   Exit_Code := Test_Framework.Print_Category_Summary
     ("INTEGRATION TESTS",
      Test_Framework.Grand_Total_Tests,
      Test_Framework.Grand_Total_Passed);

   Ada.Command_Line.Set_Exit_Status
     (Ada.Command_Line.Exit_Status (Exit_Code));
end Integration_Runner;
