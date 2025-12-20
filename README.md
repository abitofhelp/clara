# CLARA - Command Line Arguments for Reliable Applications

[![License](https://img.shields.io/badge/license-BSD--3--Clause-blue.svg)](LICENSE) [![Ada](https://img.shields.io/badge/Ada-2022-blue.svg)](https://ada-lang.io) [![SPARK](https://img.shields.io/badge/SPARK-Compatible-green.svg)](https://www.adacore.com/about-spark) [![Alire](https://img.shields.io/badge/Alire-2.0+-blue.svg)](https://alire.ada.dev)

**Version:** 0.1.0<br>
**Date:** 2025-12-19<br>
**SPDX-License-Identifier:** BSD-3-Clause<br>
**License File:** See the LICENSE file in the project root<br>
**Copyright:** (c) 2025 Michael Gardner, A Bit of Help, Inc.<br>
**Status:** In Development

## Overview

**CLARA** (**C**ommand **L**ine **A**rguments for **R**eliable **A**pplications) is a type-safe command-line argument parser for Ada 2022. It uses generic instantiation for compile-time type safety and integrates with the [Functional](https://github.com/abitofhelp/functional) library's Result and Option monads for railway-oriented argument processing.

Designed for safety-critical, embedded, and high-assurance applications with SPARK compatibility.

## Features

- **Type-safe at compile time** - Each flag/option is its own package, no string lookups
- **Functional integration** - Returns `Result` and `Option` types, composable with `And_Then`, `Map`, `or`
- **SPARK compatible** - No heap allocation, stateless parsing via `Ada.Command_Line`
- **Declarative definition** - Define CLI structure through generic instantiation
- **Expandable** - Designed to support subcommands in future versions

## Quick Start

### Installation

Add to your `alire.toml`:

```toml
[[depends-on]]
clara = "^0.1.0"
```

### Basic Usage

```ada
with Clara.Application;

--  Define your CLI
package My_CLI is new Clara.Application ("myapp", "My application description");

--  Define flags and options as packages
package Verbose is new My_CLI.Flag
   (Short => 'v', Long => "verbose", Help => "Enable verbose output");

package Output is new My_CLI.Option
   (Short => 'o', Long => "output", Value_Name => "FILE", Help => "Output file path");

package Files is new My_CLI.Positional
   (Name => "FILES", Help => "Input files to process", Multiple => True);
```

### Parsing with Functional Monads

```ada
with Functional.Result;

--  Parse returns Result[Unit, Parse_Error]
My_CLI.Parse
   .And_Then (Validate_Args'Access)
   .And_Then (Build_Config'Access)
   .Map_Error (To_User_Error'Access);

--  Query flags - no string lookups, compile-time safe
if Verbose.Is_Set then
   Enable_Verbose_Mode;
end if;

--  Options return Option[String] - use "or" operator for defaults
Output_Path : constant String := Output.Value or "./output.txt";

--  Process positional arguments
for File of Files.Values loop
   Process_File (File);
end loop;
```

### Railway-Oriented CLI Processing

```ada
function Run return App_Result.Result is
begin
   return My_CLI.Parse                          --  Result[Unit, Parse_Error]
      .Map_Error (To_App_Error'Access)          --  Result[Unit, App_Error]
      .And_Then (Check_Help_Flag'Access)        --  Early exit if --help
      .And_Then (Build_Config'Access)           --  Result[Config, App_Error]
      .And_Then (Execute'Access);               --  Result[Unit, App_Error]
end Run;
```

## Design

CLARA uses Ada's generic instantiation pattern (similar to [Functional](https://github.com/abitofhelp/functional)) rather than a builder pattern:

| Aspect | CLARA Approach |
|--------|----------------|
| **Definition** | Generic packages (`My_CLI.Flag`, `My_CLI.Option`) |
| **Type Safety** | Compile-time - `Verbose.Is_Set` not `Has_Flag("verbose")` |
| **No String Lookups** | Typos caught at compile time |
| **SPARK Compatible** | No heap allocation, stateless |
| **Parsing Backend** | `Ada.Command_Line` (no state isolation issues) |

## Roadmap

- [x] Project setup and architecture
- [ ] Core types (Flag, Option, Positional)
- [ ] Application generic package
- [ ] Parse function returning Result
- [ ] Help text generation
- [ ] Subcommand support (future)

## Documentation

- **[Quick Start](docs/quick_start.md)** - Get started in minutes
- **[CHANGELOG](CHANGELOG.md)** - Release history

## Dependencies

- [Functional](https://github.com/abitofhelp/functional) >= 4.0.0 - Result/Option monads

## Clone with Submodules

```bash
git clone --recurse-submodules https://github.com/abitofhelp/clara.git

# Or if already cloned:
git submodule update --init --recursive
```

## Contributing

This project is not open to external contributions at this time.

## AI Assistance & Authorship

This project is designed, implemented, and maintained by human developers, with Michael Gardner as the Principal Software Engineer and project lead.

AI coding assistants are used as tools for drafting, refactoring, and documentation. All changes are reviewed and integrated by human maintainers who remain responsible for architecture, correctness, and licensing.

## License

Copyright (c) 2025 Michael Gardner, A Bit of Help, Inc.

Licensed under the BSD-3-Clause License. See [LICENSE](LICENSE) for details.

## Author

Michael Gardner<br>
A Bit of Help, Inc.<br>
[github.com/abitofhelp](https://github.com/abitofhelp)
