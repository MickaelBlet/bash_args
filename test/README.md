# Unit Tests for args.sh

This directory contains unit tests for the `args.sh` argument parsing library.

## Running the Tests

To run all tests:

```bash
./test/run_all_tests.sh
```

Or from within the test directory:

```bash
cd test
./run_all_tests.sh
```

To run individual test suites:

```bash
./test/test_basic.sh          # Basic functionality tests
./test/test_actions.sh        # Action types tests
./test/test_advanced.sh       # Advanced features tests
./test/test_parsing.sh        # Parsing features tests
./test/test_helper_functions.sh  # Helper functions tests
./test/test_errors.sh         # Error handling tests
```

## Test Structure

The test suite is organized into the following files:

- **`test_helpers.sh`** - Common test helper functions and assertions
- **`run_all_tests.sh`** - Main test runner that executes all test suites
- **`test_basic.sh`** - Basic functionality tests (10 tests)
  - Positional arguments
  - Short and long options
  - Option parsing basics
- **`test_actions.sh`** - Action types tests (6 tests)
  - `store_true` / `store_false`
  - `count`
  - `append`
- **`test_advanced.sh`** - Advanced features tests (16 tests)
  - Required options/arguments
  - Default values
  - Choices validation
  - `nargs` (multiple values)
  - Destination variables
  - Metavar
- **`test_parsing.sh`** - Special parsing features tests (6 tests)
  - Combined short flags (`-abc`)
  - Double dash separator (`--`)
  - Alternative mode (single dash for long options)
  - Help option auto-generation
- **`test_helper_functions.sh`** - Helper functions tests (6 tests)
  - `args_isexists`
  - `args_count`
  - Configuration functions
- **`test_errors.sh`** - Error handling tests (3 tests)
  - Invalid options
  - Missing required values
  - Extra arguments

## Test Coverage

The test suite covers 47 test cases across the following functionality:

### Basic Functionality (10 tests)
- ✓ Initialization with `args_clean`
- ✓ Positional arguments (single and multiple)
- ✓ Short options (`-o`)
- ✓ Long options (`--option`)
- ✓ Combined short and long options
- ✓ Mixed options and arguments

### Actions (6 tests)
- ✓ `store` - Store a value
- ✓ `store_true` - Store boolean true
- ✓ `store_false` - Store boolean false
- ✓ `count` - Count occurrences
- ✓ `append` - Append multiple values

### Advanced Features (16 tests)
- ✓ Required arguments and options
- ✓ Default values
- ✓ Choices validation
- ✓ Multiple arguments (`nargs=2`, `nargs=?`)
- ✓ Infinite arguments (`nargs="+"` and `nargs="*"`)
- ✓ Destination variables (`--dest`)
- ✓ Metavar for usage display
- ✓ Default with choices

### Parsing Features (6 tests)
- ✓ Options with equals syntax (`--option=value`)
- ✓ Short option with value attached (`-ovalue`)
- ✓ Multiple short flags combined (`-abc`)
- ✓ Double dash separator (`--`)
- ✓ Alternative mode (single dash for long options)
- ✓ Auto-generated help option (`-h`, `--help`)

### Helper Functions (6 tests)
- ✓ `args_isexists` - Check if argument was provided
- ✓ `args_count` - Get count of argument occurrences
- ✓ `args_set_description` - Set usage description
- ✓ `args_set_epilog` - Set usage epilog
- ✓ `args_set_program_name` - Set program name

### Error Handling (3 tests)
- ✓ Invalid options
- ✓ Missing required values
- ✓ Extra arguments

## Test Output

The test scripts use colored output:
- 🔵 Blue header - Test suite name
- 🟢 Green checkmark (✓) - Test passed
- 🔴 Red cross (✗) - Test failed

Example output:
```
========================================
  Running args.sh Test Suite
========================================

Running basic functionality tests...
✓ args_clean initializes correctly
✓ basic positional argument
✓ multiple positional arguments
...

========================================
All tests passed!
Total:  47
Passed: 47
Failed: 0
========================================
```

## Exit Codes

- `0` - All tests passed
- `1` - One or more tests failed

## Adding New Tests

To add a new test:

1. Choose the appropriate test file based on the feature category
2. Add a test function following the naming convention `test_<description>`:

```bash
test_my_new_feature() {
    # Setup
    args_add_argument --flag "-f" --action store_true

    # Execute
    args_parse_arguments "-f"

    # Assert
    assert_equals "true" "${ARGS[f]}" "flag should be true"
}
```

3. Add the test to `run_all_tests.sh` in the appropriate section:

```bash
run_test "my new feature description" test_my_new_feature
```

4. Update the standalone test file to run when executed directly (already set up in each file)

## Helper Functions

The test suite provides these assertion helpers (defined in `test_helpers.sh`):

- `run_test <name> <function>` - Run a test with isolation and reporting
- `assert_equals <expected> <actual> [message]` - Assert two values are equal
- `assert_true <value> [message]` - Assert value is "true"
- `assert_false <value> [message]` - Assert value is "false"
- `assert_fails <command>` - Assert command fails (non-zero exit)

## Requirements

- Bash 4.0 or later
- The `args.sh` library in the parent directory (`../args.sh`)

## Test Isolation

Each test runs in a subshell with a clean `args_clean` state to ensure tests don't interfere with each other. This means:
- Global state is reset between tests
- Failed tests don't affect subsequent tests
- Tests can be run in any order
