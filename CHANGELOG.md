# Changelog

**Version:** 1.0.0<br>
**Date:** 2026-06-09<br>
**SPDX-License-Identifier:** BSD-3-Clause<br>
**License File:** See the LICENSE file in the project root<br>
**Copyright:** © 2025-2026 Michael Gardner, A Bit of Help, Inc.<br>
**Status:** Released

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

No unreleased changes yet.

---

## [1.0.0] - 2026-06-09

**Test Coverage:** 79 unit + 0 integration + 0 examples = 79 total

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

### Changed

- **`Clara.CLI` is now parse-only** (no parse-time callbacks).
  Help and version are surfaced exclusively as outcome signals
  on `Parse_Outcome.Result` (`Error_Value.Kind in
  Help_Requested | Version_Requested`).  Consumers detect these
  after `Parse` returns and render help / version text
  themselves; parse-time control flow is decoupled from
  consumer rendering.  Pure parse → outcome semantics simplify
  consumer integration and remove a mid-parse side-effect
  surprise.

### Removed

- **`Show_Help` generic formal procedure** removed from
  `Clara.CLI`.  Previously, encountering `--help` or `-h`
  during parse would invoke a consumer-supplied `Show_Help`
  callback in addition to returning `Help_Requested`.  The
  callback is no longer invoked; `Help_Requested` (and
  `Version_Requested` for `--version`) are the sole signals.
  **Migration**: drop `Show_Help => ...` from your
  `Clara.CLI` instantiation; render help / version after
  `Parse` returns by inspecting `Error_Value.Kind`.
