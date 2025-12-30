pragma Ada_2022;
--  ======================================================================
--  Test_Clara - Unit tests for Clara root package
--  ======================================================================
--  Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
--  SPDX-License-Identifier: BSD-3-Clause
--  ======================================================================

with Ada.Text_IO;
with Test_Framework;
with Clara;

procedure Test_Clara is

   use Ada.Text_IO;

   Total  : Natural := 0;
   Passed : Natural := 0;

   procedure Check (Name : String; Condition : Boolean) is
   begin
      Total := Total + 1;
      if Condition then
         Passed := Passed + 1;
         Put_Line ("  PASS: " & Name);
      else
         Put_Line ("  FAIL: " & Name);
      end if;
   end Check;

begin
   Put_Line ("");
   Put_Line ("=== Clara Root Package Tests ===");
   Put_Line ("");

   --  =========================================================================
   --  Test Library Constants
   --  =========================================================================

   Put_Line ("-- Library Constants --");

   pragma Warnings (Off, "condition is always*");
   Check ("Library_Name is CLARA",
          Clara.Library_Name = "CLARA");
   Check ("Acronym is defined",
          Clara.Acronym'Length > 0);
   pragma Warnings (On, "condition is always*");

   Check ("Acronym contains 'Command Line'",
          Clara.Acronym (Clara.Acronym'First ..
                         Clara.Acronym'First + 11) = "Command Line");

   --  =========================================================================
   --  Summary
   --  =========================================================================

   Put_Line ("");
   Put_Line ("Clara: " & Passed'Image & " /" & Total'Image & " passed");

   Test_Framework.Register_Results (Total, Passed);

end Test_Clara;
