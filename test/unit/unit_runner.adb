pragma Ada_2022;
--  ===========================================================================
--  Unit Test Runner for Clara
--  ===========================================================================

with Ada.Text_IO;    use Ada.Text_IO;
with Ada.Command_Line;
with Test_Framework;
with Test_Clara;
with Test_Types;
with Test_Errors;
with Test_Version;
with Test_CLI;

procedure Unit_Runner is
   Total, Passed : Natural;
   Exit_Code     : Integer;
begin
   Test_Framework.Reset;

   --  Run all test suites
   Test_Clara.Run (Total, Passed);
   Put_Line ("Passed:" & Passed'Image & "  Failed:" &
             Natural'Image (Total - Passed));
   Test_Framework.Register_Results (Total, Passed);

   Test_Types.Run (Total, Passed);
   Put_Line ("Passed:" & Passed'Image & "  Failed:" &
             Natural'Image (Total - Passed));
   Test_Framework.Register_Results (Total, Passed);

   Test_Errors.Run (Total, Passed);
   Put_Line ("Passed:" & Passed'Image & "  Failed:" &
             Natural'Image (Total - Passed));
   Test_Framework.Register_Results (Total, Passed);

   Test_Version.Run (Total, Passed);
   Put_Line ("Passed:" & Passed'Image & "  Failed:" &
             Natural'Image (Total - Passed));
   Test_Framework.Register_Results (Total, Passed);

   Test_CLI.Run (Total, Passed);
   Put_Line ("Passed:" & Passed'Image & "  Failed:" &
             Natural'Image (Total - Passed));
   Test_Framework.Register_Results (Total, Passed);

   --  Print grand summary
   Exit_Code := Test_Framework.Print_Category_Summary
     ("UNIT TESTS",
      Test_Framework.Grand_Total_Tests,
      Test_Framework.Grand_Total_Passed);

   Ada.Command_Line.Set_Exit_Status
     (Ada.Command_Line.Exit_Status (Exit_Code));
end Unit_Runner;
