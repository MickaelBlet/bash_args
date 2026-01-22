# Unit Tests for args.sh

This directory contains unit tests for the `args.sh` argument parsing library.

## Running the Tests

To run the test suite:

```bash
./test/test_args.sh
```

Or from within the test directory:

```bash
cd test
./test_args.sh
```

## Test Coverage

The test suite covers the following functionality:

### Basic Functionality
- ✓ Initialization with `args_clean`
- ✓ Positional arguments (single and multiple)
- ✓ Short options (`-o`)
- ✓ Long options (`--option`)
- ✓ Combined short and long options

### Actions
- ✓ `store` - Store a value
- ✓ `store_true` - Store boolean true
- ✓ `store_false` - Store boolean false
- ✓ `count` - Count occurrences
- ✓ `append` - Append multiple values

### Advanced Features
- ✓ Required arguments and options
- ✓ Default values
- ✓ Choices validation
- ✓ Multiple arguments (`nargs`)
- ✓ Infinite arguments (`nargs="+"` and `nargs="*"`)
- ✓ Optional arguments (`nargs="?"`)
- ✓ Destination variables (`--dest`)
- ✓ Metavar for usage display
- ✓ Alternative mode (single dash for long options)

### Parsing Features
- ✓ Options with equals syntax (`--option=value`)
- ✓ Short option with value attached (`-ovalue`)
- ✓ Multiple short flags combined (`-abc`)
- ✓ Double dash separator (`--`)
- ✓ Auto-generated help option (`-h`, `--help`)

### Helper Functions
- ✓ `args_isexists` - Check if argument was provided
- ✓ `args_count` - Get count of argument occurrences
- ✓ `args_set_description` - Set usage description
- ✓ `args_set_epilog` - Set usage epilog
- ✓ `args_set_program_name` - Set program name

### Error Handling
- ✓ Invalid options
- ✓ Missing required values
- ✓ Extra arguments
- ✓ Invalid choices
- ✓ Required arguments/options not provided

## Test Output

The test script uses colored output:
- 🟢 Green checkmark (✓) - Test passed
- 🔴 Red cross (✗) - Test failed

## Exit Codes

- `0` - All tests passed
- `1` - One or more tests failed

## Adding New Tests

To add a new test:

1. Create a test function following the naming convention `test_<description>`:

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

2. Add the test to the test runner section:

```bash
run_test "my new feature description" test_my_new_feature
```

## Helper Functions

The test suite provides these assertion helpers:

- `assert_equals <expected> <actual> [message]` - Assert two values are equal
- `assert_true <value> [message]` - Assert value is "true"
- `assert_false <value> [message]` - Assert value is "false"
- `assert_fails <command>` - Assert command fails (non-zero exit)

## Requirements

- Bash 4.0 or later
- The `args.sh` library in the parent directory

## Test Isolation

Each test runs in a subshell with a clean `args_clean` state to ensure tests don't interfere with each other.
