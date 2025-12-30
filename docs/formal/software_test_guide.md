# Software Test Guide (STG)

**Project:** CLARA - Command Line Arguments for Reliable Applications
**Version:** 1.0.0<br>
**Date:** 2025-12-29<br>
**SPDX-License-Identifier:** BSD-3-Clause<br>
**License File:** See the LICENSE file in the project root<br>
**Copyright:** © 2025 Michael Gardner, A Bit of Help, Inc.<br>
**Status:** Released

---

## 1. Introduction

### 1.1 Purpose

This Software Test Guide (STG) defines the test strategy, test cases, and verification approach for **CLARA**, a type-safe command-line argument parsing library for Ada 2022.

### 1.2 Scope

This document covers:
- Test strategy and approach
- Unit test specifications
- Integration test specifications
- Coverage requirements

### 1.3 References

- [CLARA SRS](software_requirements_specification.md)
- [CLARA SDS](software_design_specification.md)
- Test Framework documentation

---

## 2. Test Strategy

### 2.1 Test Levels

| Level | Purpose | Scope |
|-------|---------|-------|
| Unit | Verify individual packages | Clara.Types, Clara.Errors, Flag, Option, Positional |
| Integration | Verify package interactions | Full parsing with multiple args |
| SPARK | Formal verification | Proof of absence of runtime errors |

### 2.2 Test Framework

CLARA uses the custom Test_Framework from test/common/:

```ada
with Test_Framework;

procedure Test_Flag is
   procedure Test_Is_Set is
      --  Test implementation
   begin
      Test_Framework.Assert (Verbose.Is_Set, "Flag should be set");
   end Test_Is_Set;
begin
   Test_Is_Set;
   Test_Framework.Register_Results ("Test_Flag", Passed, Failed);
end Test_Flag;
```

### 2.3 Coverage Requirements

| Metric | Target |
|--------|--------|
| Line Coverage | >= 90% |
| Branch Coverage | >= 85% |
| MC/DC Coverage | >= 80% (for SPARK packages) |

---

## 3. Unit Test Specifications

### 3.1 Flag Tests

| Test Case | Description | Expected Result |
|-----------|-------------|-----------------|
| TC-FLAG-001 | Flag not present | Is_Set returns False, Count = 0 |
| TC-FLAG-002 | Short flag present (-v) | Is_Set returns True, Count = 1 |
| TC-FLAG-003 | Long flag present (--verbose) | Is_Set returns True, Count = 1 |
| TC-FLAG-004 | Multiple short flags (-vvv) | Count = 3 |
| TC-FLAG-005 | Combined short flags (-vh) | Both flags set |

### 3.2 Option Tests

| Test Case | Description | Expected Result |
|-----------|-------------|-----------------|
| TC-OPT-001 | Option not present | Has_Value False, Value returns None |
| TC-OPT-002 | Short option with space (-o file) | Value = "file" |
| TC-OPT-003 | Long option with equals (--output=file) | Value = "file" |
| TC-OPT-004 | Long option with space (--output file) | Value = "file" |
| TC-OPT-005 | Option with "or" default | Returns default when None |
| TC-OPT-006 | Required option missing | Parse returns Error |

### 3.3 Positional Tests

| Test Case | Description | Expected Result |
|-----------|-------------|-----------------|
| TC-POS-001 | No positional args | Values is empty |
| TC-POS-002 | Single positional arg | Values contains 1 element |
| TC-POS-003 | Multiple positional args | Values contains all elements |
| TC-POS-004 | Positional after flags | Correctly separated |
| TC-POS-005 | Positional with -- separator | Args after -- are positional |

### 3.4 Parse Error Tests

| Test Case | Description | Expected Result |
|-----------|-------------|-----------------|
| TC-ERR-001 | Unknown switch | Error with Unknown_Switch kind |
| TC-ERR-002 | Missing option value | Error with Missing_Value kind |
| TC-ERR-003 | Valid parse | Ok(Unit) returned |
| TC-ERR-004 | Help flag | Error with Help_Requested kind |

### 3.5 Help Generation Tests

| Test Case | Description | Expected Result |
|-----------|-------------|-----------------|
| TC-HELP-001 | Help contains app name | Name appears in output |
| TC-HELP-002 | Help contains description | Description appears |
| TC-HELP-003 | Help lists all flags | All flags shown with help text |
| TC-HELP-004 | Help lists all options | All options shown with value names |

---

## 4. Integration Test Specifications

### 4.1 Full Parse Scenarios

| Test Case | Command Line | Expected Result |
|-----------|--------------|-----------------|
| TC-INT-001 | `app` | No flags set, no positionals |
| TC-INT-002 | `app -v file.txt` | Verbose set, 1 positional |
| TC-INT-003 | `app --output=out.txt file1 file2` | Output = "out.txt", 2 positionals |
| TC-INT-004 | `app -vh --output file.txt input.ada` | Multiple flags, option, positional |
| TC-INT-005 | `app --help` | Help_Requested error (graceful exit) |
| TC-INT-006 | `app --unknown` | Unknown_Switch error |

### 4.2 Edge Cases

| Test Case | Description | Expected Result |
|-----------|-------------|-----------------|
| TC-EDGE-001 | Empty string argument | Handled gracefully |
| TC-EDGE-002 | Argument with spaces (quoted) | Preserved correctly |
| TC-EDGE-003 | Very long argument | Within bounds or error |
| TC-EDGE-004 | Unicode in arguments | Handled correctly |
| TC-EDGE-005 | Argument starting with - but not switch | Treated as positional after -- |

---

## 5. SPARK Verification

### 5.1 Packages Under SPARK

| Package | SPARK_Mode | Proof Level |
|---------|------------|-------------|
| Clara | On | Full |
| Clara.Types | On | Full |
| Clara.Errors | On | Full |
| Clara.Version | On | Full |
| Clara.Application (core) | On | Full |

### 5.2 Proof Objectives

| Objective | Verification |
|-----------|--------------|
| No runtime errors | GNATprove level 2 |
| No uninitialized reads | Flow analysis |
| Bounded string access | Range checks proven |
| Array bounds | Index checks proven |

---

## 6. Test Environment

### 6.1 Build Commands

```bash
# Run all tests
make test-all

# Run unit tests only
make test-unit

# Run with coverage
make test-coverage

# Run SPARK proofs
make spark-prove
```

### 6.2 Test Directory Structure

```
test/
├── common/           # Shared test framework
│   ├── test_framework.ads
│   └── test_framework.adb
├── unit/             # Unit tests
│   ├── unit_tests.gpr
│   ├── unit_runner.adb
│   ├── test_flag.adb
│   ├── test_option.adb
│   └── test_positional.adb
├── integration/      # Integration tests
│   ├── integration_tests.gpr
│   └── test_full_parse.adb
└── spark/            # SPARK instantiation tests
    └── spark_instantiations.ads
```

---

## 7. Traceability Matrix

| Requirement | Test Cases |
|-------------|------------|
| REQ-APP-001 | TC-INT-001 through TC-INT-006 |
| REQ-FLAG-001 | TC-FLAG-001 through TC-FLAG-005 |
| REQ-FLAG-005 | TC-FLAG-001, TC-FLAG-002 |
| REQ-OPT-001 | TC-OPT-001 through TC-OPT-006 |
| REQ-OPT-005 | TC-OPT-001, TC-OPT-005 |
| REQ-POS-001 | TC-POS-001 through TC-POS-005 |
| REQ-ERR-001 | TC-ERR-001 through TC-ERR-004 |
| REQ-HELP-001 | TC-HELP-001 through TC-HELP-004 |

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 0.1.0 | 2025-12-19 | Michael Gardner | Initial test strategy |
