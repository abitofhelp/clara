pragma Ada_2022;
--  ===========================================================================
--  SPARK_Static_Test - SPARK Verification for Clara.Static
--  ===========================================================================
--  Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.
--  SPDX-License-Identifier: BSD-3-Clause
--  ===========================================================================

with Clara.Static;
with Clara.Types;

package SPARK_Static_Test with
  SPARK_Mode => On
is

   --  Define enumerations for testing
   type Test_Flags is (Verbose, Debug, Help_Flag);
   type Test_Options is (Output, Config, Format);
   type Test_Positionals is (Input_File, Output_File);

   --  Instantiate Clara.Static
   package Test_CLI is new Clara.Static
     (Flag_Names       => Test_Flags,
      Option_Names     => Test_Options,
      Positional_Names => Test_Positionals,
      App_Name         => "spark_test",
      App_Description  => "SPARK verification test");

   --  Test configuration
   Test_Config : constant Test_CLI.CLI_Config :=
     (Flags =>
        [Verbose   => Test_CLI.Flag ('v', "verbose", "Verbose mode"),
         Debug     => Test_CLI.Flag ('d', "debug", "Debug mode"),
         Help_Flag => Test_CLI.Flag ('h', "help", "Show help")],

      Options =>
        [Output => Test_CLI.Opt ('o', "output", "FILE", "Output file"),
         Config => Test_CLI.Opt ('c', "config", "PATH", "Config file"),
         Format => Test_CLI.Opt ('f', "format", "FMT", "Format type")],

      Positionals =>
        [Input_File  => Test_CLI.Pos ("INPUT", "Input file"),
         Output_File => Test_CLI.Pos ("OUTPUT", "Output file")]);

   --  Test functions
   function Test_Parse return Boolean
     with Post => Test_Parse'Result;

   function Test_Results_Access return Boolean
     with Post => Test_Results_Access'Result;

end SPARK_Static_Test;
