# Changelog

**Version:** 1.0.1<br>
**Date:** <YYYY-MM-DD pending tag><br>
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

## [1.0.1] - <YYYY-MM-DD pending tag>

**First Alire-published release of CLARA.**

`v1.0.0` was tagged but not submitted to the Alire community index
after `alr publish --skip-submit` dry-run validation found SSH
submodule URLs in `.gitmodules` (`git@github.com:...`).  The dry-run
publication failed at the "Deploy sources" step because the recursive
clone could not fetch the public helper submodules
(`hybrid_scripts_python`, `hybrid_test_python`) over SSH in
credentials-free consumer environments such as the Alire dev container
or GHA runners during `alr publish`.

`v1.0.1` is the first version intended for Alire community-index
submission.  No source / API / behavior changes vs `v1.0.0` — only
the `.gitmodules` publishability repair (PR #13, merged `ec80afd`,
2026-06-09) and the version-surface bump in this PR.  Mirrors the
`functional` v4.1.0 → v4.1.1 pattern (functional#6 merged the
HTTPS repair, functional `v4.1.1` was the first version published
to the Alire community index, now LIVE).

### Changed

- Version bumped `1.0.0` → `1.0.1` across `alire.toml`,
  `test/alire.toml`, `src/version/clara-version.ads`
  (`Patch` and `Version` constants), and `test/unit/test_version.adb`
  (`Patch = 1`, `Version = "1.0.1"`).

### Not changed (vs `v1.0.0`)

- No `src/` API or behavior changes.
- Direct dependency stays at `functional = "^4.0.0"` (resolves to
  `functional 4.1.1` from the Alire community index — no root
  `[[pins]]` per T1 / PR #12).
- No tag created by this PR; `v1.0.0` annotated tag preserved at
  `e3c24f4` -> `8b6ea3b` (pre-`.gitmodules`-fix tree).

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
