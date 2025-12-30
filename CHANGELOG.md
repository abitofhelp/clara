# Changelog

**Version:** 1.0.0<br>
**Date:** 2025-12-29<br>
**SPDX-License-Identifier:** BSD-3-Clause<br>
**License File:** See the LICENSE file in the project root<br>
**Copyright:** © 2025 Michael Gardner, A Bit of Help, Inc.<br>
**Status:** Released

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

### Changed

### Deprecated

### Removed

### Fixed

### Security

---

## [1.0.0] - 2025-12-29

_Initial release of CLARA._

### Added

- Type-safe command-line argument parsing via generic instantiation
- `Clara.Application` - Root package for CLI definition
- `Clara.Flag` - Boolean flags with short/long forms (`-v`, `--verbose`)
- `Clara.Option` - Key-value options with short/long forms (`-o file`, `--output=file`)
- `Clara.Positional` - Positional arguments with single and multiple value support
- Built-in `--help` and `--version` flag handling
- Integration with Functional library's `Result` and `Option` monads
- Railway-oriented parsing with `And_Then`, `Map`, `Or_Else` composition
- SPARK-compatible design (no heap allocation, stateless parsing)
- Comprehensive test suite with 95% code coverage
- Full documentation: SRS, SDS, STG, quick start guide
