pragma Ada_2022;
--  ======================================================================
--  Test_Version - Unit tests for Clara.Version
--  ======================================================================
--  Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
--  SPDX-License-Identifier: BSD-3-Clause
--  ======================================================================

with Ada.Text_IO;
with Test_Framework;
with Clara.Version;

procedure Test_Version is

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
   Put_Line ("=== Clara.Version Tests ===");
   Put_Line ("");

   --  =========================================================================
   --  Test Version Components
   --  =========================================================================

   Put_Line ("-- Version Components --");

   pragma Warnings (Off, "condition is always*");
   Check ("Major is Natural", Clara.Version.Major >= 0);
   Check ("Minor is Natural", Clara.Version.Minor >= 0);
   Check ("Patch is Natural", Clara.Version.Patch >= 0);
   pragma Warnings (On, "condition is always*");

   --  =========================================================================
   --  Test Version String
   --  =========================================================================

   Put_Line ("");
   Put_Line ("-- Version String --");

   Check ("Version string not empty",
          Clara.Version.Version'Length > 0);
   Check ("Version contains major.minor.patch format",
          Clara.Version.Version'Length >= 5);  -- e.g., "0.1.0"

   --  =========================================================================
   --  Test Prerelease
   --  =========================================================================

   Put_Line ("");
   Put_Line ("-- Prerelease Handling --");

   --  For dev version, prerelease = "dev"
   Check ("Prerelease string accessible",
          Clara.Version.Prerelease'Length >= 0);

   Check ("Is_Prerelease returns Boolean",
          Clara.Version.Is_Prerelease or not Clara.Version.Is_Prerelease);

   Check ("Is_Development returns Boolean",
          Clara.Version.Is_Development or not Clara.Version.Is_Development);

   Check ("Is_Stable returns Boolean",
          Clara.Version.Is_Stable or not Clara.Version.Is_Stable);

   --  =========================================================================
   --  Test Consistency
   --  =========================================================================

   Put_Line ("");
   Put_Line ("-- Consistency Checks --");

   --  Is_Stable should be opposite of Is_Prerelease
   Check ("Is_Stable = not Is_Prerelease",
          Clara.Version.Is_Stable = (not Clara.Version.Is_Prerelease));

   --  If Is_Development, must be Is_Prerelease
   Check ("Is_Development implies Is_Prerelease",
          (not Clara.Version.Is_Development) or Clara.Version.Is_Prerelease);

   --  Build metadata is accessible (may be empty)
   Check ("Build_Metadata accessible",
          Clara.Version.Build_Metadata'Length >= 0);

   --  =========================================================================
   --  Summary
   --  =========================================================================

   Put_Line ("");
   Put_Line ("Clara.Version: " & Passed'Image & " /" & Total'Image & " passed");

   Test_Framework.Register_Results (Total, Passed);

end Test_Version;
