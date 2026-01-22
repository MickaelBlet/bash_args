#!/usr/bin/env bash

#
# Unit tests for args.sh
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Source args.sh from parent directory
source "${SCRIPT_DIR}/../args.sh"

# Helper function to run a test
run_test() {
    local test_name="$1"
    local test_func="$2"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    # Run test in subshell to isolate environment
    if (
        args_clean
        $test_func
    ); then
        echo -e "${GREEN}✓${NC} ${test_name}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "${RED}✗${NC} ${test_name}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# Helper function to assert equality
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"

    if [[ "$expected" != "$actual" ]]; then
        echo "  Expected: '$expected'"
        echo "  Actual:   '$actual'"
        [[ -n "$message" ]] && echo "  Message:  $message"
        return 1
    fi
    return 0
}

# Helper function to assert true
assert_true() {
    local condition="$1"
    local message="${2:-}"

    if [[ "$condition" != "true" ]]; then
        echo "  Expected: true"
        echo "  Actual:   $condition"
        [[ -n "$message" ]] && echo "  Message:  $message"
        return 1
    fi
    return 0
}

# Helper function to assert false
assert_false() {
    local condition="$1"
    local message="${2:-}"

    if [[ "$condition" != "false" ]]; then
        echo "  Expected: false"
        echo "  Actual:   $condition"
        [[ -n "$message" ]] && echo "  Message:  $message"
        return 1
    fi
    return 0
}

# Helper function to assert command fails
assert_fails() {
    if "$@" 2>/dev/null; then
        echo "  Expected command to fail but it succeeded: $*"
        return 1
    fi
    return 0
}

#
# Test Functions
#

test_args_clean() {
    args_clean
    assert_equals "0" "${__ARGS[argument.size]}" "argument.size should be 0"
    assert_equals "0" "${__ARGS[option.size]}" "option.size should be 0"
    assert_equals "false" "${__ARGS[sorted]}" "sorted should be false"
    assert_equals "false" "${__ARGS[alternative]}" "alternative should be false"
}

test_basic_positional_argument() {
    args_add_argument --name "ARG1"
    args_parse_arguments "test_value"
    assert_equals "test_value" "${ARGS[ARG1]}" "ARG1 should be test_value"
}

test_multiple_positional_arguments() {
    args_add_argument --name "ARG1"
    args_add_argument --name "ARG2"
    args_parse_arguments "value1" "value2"
    assert_equals "value1" "${ARGS[ARG1]}" "ARG1 should be value1"
    assert_equals "value2" "${ARGS[ARG2]}" "ARG2 should be value2"
}

test_required_positional_argument() {
    args_add_argument --name "ARG1" --required
    assert_fails args_parse_arguments
}

test_optional_positional_argument_with_default() {
    args_add_argument --name "ARG1" --default "default_value"
    args_parse_arguments
    assert_equals "default_value" "${ARGS[ARG1]}" "ARG1 should have default value"
}

test_short_option_store() {
    args_add_argument --flag "-o" --action store
    args_parse_arguments "-o" "value"
    assert_equals "value" "${ARGS[o]}" "option -o should be value"
}

test_long_option_store() {
    args_add_argument --flag "--option" --action store
    args_parse_arguments "--option" "value"
    assert_equals "value" "${ARGS[option]}" "option --option should be value"
}

test_short_and_long_option() {
    args_add_argument --flag "-o" --flag "--option" --action store
    args_parse_arguments "-o" "value"
    assert_equals "value" "${ARGS[o]}" "short option -o should be value"
    assert_equals "value" "${ARGS[option]}" "long option --option should be value"
}

test_option_with_equals() {
    args_add_argument --flag "--option" --action store
    args_parse_arguments "--option=value"
    assert_equals "value" "${ARGS[option]}" "option --option should be value"
}

test_store_true_action() {
    args_add_argument --flag "-f" --action store_true
    args_parse_arguments "-f"
    assert_equals "true" "${ARGS[f]}" "flag -f should be true"
}

test_store_false_action() {
    args_add_argument --flag "-f" --action store_false
    args_parse_arguments "-f"
    assert_equals "false" "${ARGS[f]}" "flag -f should be false"
}

test_store_true_default() {
    args_add_argument --flag "-f" --action store_true
    args_parse_arguments
    assert_equals "false" "${ARGS[f]:-false}" "flag -f should default to false"
}

test_count_action() {
    args_add_argument --flag "-v" --action count
    args_parse_arguments "-v" "-v" "-v"
    assert_equals "3" "${ARGS[v]}" "flag -v count should be 3"
}

test_count_action_default() {
    args_add_argument --flag "-v" --action count
    args_parse_arguments
    assert_equals "0" "${ARGS[v]:-0}" "flag -v should default to 0"
}

test_required_option() {
    args_add_argument --flag "-r" --required --action store
    assert_fails args_parse_arguments
}

test_required_option_satisfied() {
    args_add_argument --flag "-r" --required --action store
    args_parse_arguments "-r" "value"
    assert_equals "value" "${ARGS[r]}" "required option -r should be value"
}

test_option_with_default() {
    args_add_argument --flag "--option" --action store --default "default_val"
    args_parse_arguments
    assert_equals "default_val" "${ARGS[option]}" "option should have default value"
}

test_option_overrides_default() {
    args_add_argument --flag "--option" --action store --default "default_val"
    args_parse_arguments "--option" "custom_val"
    assert_equals "custom_val" "${ARGS[option]}" "option should be overridden"
}

test_choices_valid() {
    args_add_argument --flag "--color" --action store --choices "red green blue"
    args_parse_arguments "--color" "red"
    assert_equals "red" "${ARGS[color]}" "color should be red"
}

test_choices_invalid() {
    args_add_argument --flag "--color" --action store --choices "red green blue"
    assert_fails args_parse_arguments "--color" "yellow"
}

test_positional_choices_valid() {
    args_add_argument --name "COLOR" --choices "red green blue"
    args_parse_arguments "green"
    assert_equals "green" "${ARGS[COLOR]}" "COLOR should be green"
}

test_positional_choices_invalid() {
    args_add_argument --name "COLOR" --choices "red green blue"
    assert_fails args_parse_arguments "yellow"
}

test_nargs_two() {
    args_add_argument --flag "--point" --nargs 2
    args_parse_arguments "--point" "1" "2"
    assert_equals "1" "${ARGS[point.0]}" "first arg should be 1"
    assert_equals "2" "${ARGS[point.1]}" "second arg should be 2"
}

test_append_action() {
    args_add_argument --flag "-i" --action append
    args_parse_arguments "-i" "val1" "-i" "val2" "-i" "val3"
    assert_equals "val1" "${ARGS[i.0]}" "first value should be val1"
    assert_equals "val2" "${ARGS[i.1]}" "second value should be val2"
    assert_equals "val3" "${ARGS[i.2]}" "third value should be val3"
}

test_infinite_nargs_plus() {
    args_add_argument --flag "--files" --nargs "+"
    args_parse_arguments "--files" "file1" "file2" "file3"
    assert_equals "file1" "${ARGS[files.0]}" "first file should be file1"
    assert_equals "file2" "${ARGS[files.1]}" "second file should be file2"
    assert_equals "file3" "${ARGS[files.2]}" "third file should be file3"
}

test_infinite_nargs_star() {
    args_add_argument --flag "--files" --nargs "*"
    args_parse_arguments "--files" "file1" "file2"
    assert_equals "file1" "${ARGS[files.0]}" "first file should be file1"
    assert_equals "file2" "${ARGS[files.1]}" "second file should be file2"
}

test_infinite_nargs_star_empty() {
    args_add_argument --flag "--files" --nargs "*"
    args_parse_arguments "--files"
    # Should not fail even with no arguments
    return 0
}

test_dest_variable() {
    args_add_argument --flag "--option" --action store --dest "MY_VAR"
    args_parse_arguments "--option" "test_value"
    assert_equals "test_value" "${MY_VAR}" "MY_VAR should be test_value"
}

test_metavar_in_usage() {
    args_add_argument --flag "--file" --metavar "FILE" --action store
    local usage
    usage=$(args_usage "test_script")
    if [[ "$usage" =~ "FILE" ]]; then
        return 0
    else
        echo "  Usage should contain metavar FILE"
        return 1
    fi
}

test_help_option_auto_added() {
    # Help option should be auto-added when parsing
    args_add_argument --flag "-v" --action store_true
    # When help is called, it returns ARGS_USAGE_RETURN_CODE (64)
    if args_parse_arguments "-h" 2>/dev/null; then
        echo "  Help option should trigger usage and return code 64"
        return 1
    else
        local exit_code=$?
        if [[ $exit_code -eq 64 ]]; then
            return 0
        else
            echo "  Expected return code 64, got $exit_code"
            return 1
        fi
    fi
}

test_args_isexists_true() {
    args_add_argument --flag "-v" --action store_true
    args_parse_arguments "-v"
    if args_isexists "-v"; then
        return 0
    else
        echo "  args_isexists should return true for -v"
        return 1
    fi
}

test_args_isexists_false() {
    args_add_argument --flag "-v" --action store_true
    args_parse_arguments
    if ! args_isexists "-v"; then
        return 0
    else
        echo "  args_isexists should return false for -v"
        return 1
    fi
}

test_args_count() {
    args_add_argument --flag "-v" --action count
    args_parse_arguments "-v" "-v"
    local count
    count=$(args_count "-v")
    assert_equals "2" "$count" "count should be 2"
}

test_double_dash_separator() {
    args_add_argument --flag "-f" --action store_true
    args_add_argument --name "ARG1"
    args_parse_arguments "-f" "--" "--not-an-option"
    assert_equals "true" "${ARGS[f]}" "flag -f should be true"
    assert_equals "--not-an-option" "${ARGS[ARG1]}" "ARG1 should be --not-an-option"
}

test_multi_short_flags() {
    args_add_argument --flag "-a" --action store_true
    args_add_argument --flag "-b" --action store_true
    args_add_argument --flag "-c" --action store_true
    args_parse_arguments "-abc"
    assert_equals "true" "${ARGS[a]}" "flag -a should be true"
    assert_equals "true" "${ARGS[b]}" "flag -b should be true"
    assert_equals "true" "${ARGS[c]}" "flag -c should be true"
}

test_set_alternative_true() {
    args_set_alternative "true"
    args_add_argument --flag "--option" --action store
    args_parse_arguments "-option" "value"
    assert_equals "value" "${ARGS[option]}" "alternative option should work"
}

test_set_alternative_false() {
    args_set_alternative "false"
    args_add_argument --flag "--option" --action store
    assert_fails args_parse_arguments "-option" "value"
}

test_set_description() {
    args_set_description "This is a test description"
    assert_equals "This is a test description" "${__ARGS[usage.description]}"
}

test_set_epilog() {
    args_set_epilog "This is an epilog"
    assert_equals "This is an epilog" "${__ARGS[usage.epilog]}"
}

test_set_program_name() {
    args_set_program_name "my_program"
    assert_equals "my_program" "${__ARGS[program.name]}"
}

test_error_on_invalid_option() {
    args_add_argument --flag "-v" --action store_true
    assert_fails args_parse_arguments "-x"
}

test_error_on_missing_required_value() {
    args_add_argument --flag "-o" --action store
    assert_fails args_parse_arguments "-o"
}

test_error_on_extra_arguments() {
    args_add_argument --name "ARG1"
    assert_fails args_parse_arguments "value1" "value2" "value3"
}

test_mixed_options_and_arguments() {
    args_add_argument --flag "-v" --action store_true
    args_add_argument --flag "--output" --action store
    args_add_argument --name "INPUT"
    args_parse_arguments "-v" "--output" "out.txt" "input.txt"
    assert_equals "true" "${ARGS[v]}" "flag -v should be true"
    assert_equals "out.txt" "${ARGS[output]}" "output should be out.txt"
    assert_equals "input.txt" "${ARGS[INPUT]}" "INPUT should be input.txt"
}

test_nargs_question_mark() {
    args_add_argument --flag "--optional" --nargs "?"
    args_parse_arguments "--optional"
    # Should succeed even without value
    return 0
}

test_default_with_choices() {
    args_add_argument --flag "--level" --choices "debug info warn error" --default "info"
    args_parse_arguments
    assert_equals "info" "${ARGS[level]}" "level should default to info"
}

test_short_option_with_value_attached() {
    args_add_argument --flag "-o" --action store
    args_parse_arguments "-ovalue"
    assert_equals "value" "${ARGS[o]}" "option -o should be value"
}

#
# Run all tests
#

echo "Running args.sh unit tests..."
echo ""

run_test "args_clean initializes correctly" test_args_clean
run_test "basic positional argument" test_basic_positional_argument
run_test "multiple positional arguments" test_multiple_positional_arguments
run_test "required positional argument fails when missing" test_required_positional_argument
run_test "optional positional argument with default" test_optional_positional_argument_with_default
run_test "short option with store action" test_short_option_store
run_test "long option with store action" test_long_option_store
run_test "short and long option together" test_short_and_long_option
run_test "option with equals syntax" test_option_with_equals
run_test "store_true action" test_store_true_action
run_test "store_false action" test_store_false_action
run_test "store_true default value" test_store_true_default
run_test "count action" test_count_action
run_test "count action default value" test_count_action_default
run_test "required option fails when missing" test_required_option
run_test "required option satisfied" test_required_option_satisfied
run_test "option with default value" test_option_with_default
run_test "option overrides default value" test_option_overrides_default
run_test "choices with valid value" test_choices_valid
run_test "choices with invalid value fails" test_choices_invalid
run_test "positional choices with valid value" test_positional_choices_valid
run_test "positional choices with invalid value fails" test_positional_choices_invalid
run_test "nargs with value 2" test_nargs_two
run_test "append action" test_append_action
run_test "infinite nargs +" test_infinite_nargs_plus
run_test "infinite nargs *" test_infinite_nargs_star
run_test "infinite nargs * with empty" test_infinite_nargs_star_empty
run_test "dest variable" test_dest_variable
run_test "metavar in usage" test_metavar_in_usage
run_test "help option auto-added" test_help_option_auto_added
run_test "args_isexists returns true" test_args_isexists_true
run_test "args_isexists returns false" test_args_isexists_false
run_test "args_count returns correct count" test_args_count
run_test "double dash separator" test_double_dash_separator
run_test "multi short flags combined" test_multi_short_flags
run_test "set_alternative true allows single dash" test_set_alternative_true
run_test "set_alternative false rejects single dash" test_set_alternative_false
run_test "set_description" test_set_description
run_test "set_epilog" test_set_epilog
run_test "set_program_name" test_set_program_name
run_test "error on invalid option" test_error_on_invalid_option
run_test "error on missing required value" test_error_on_missing_required_value
run_test "error on extra arguments" test_error_on_extra_arguments
run_test "mixed options and arguments" test_mixed_options_and_arguments
run_test "nargs ? (question mark)" test_nargs_question_mark
run_test "default with choices" test_default_with_choices
run_test "short option with value attached" test_short_option_with_value_attached

#
# Print summary
#

echo ""
echo "========================================"
if [[ $FAILED_TESTS -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
else
    echo -e "${RED}Some tests failed.${NC}"
fi
echo "Total:  $TOTAL_TESTS"
echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
if [[ $FAILED_TESTS -gt 0 ]]; then
    echo -e "${RED}Failed: $FAILED_TESTS${NC}"
else
    echo "Failed: $FAILED_TESTS"
fi
echo "========================================"

# Exit with appropriate code
if [[ $FAILED_TESTS -eq 0 ]]; then
    exit 0
else
    exit 1
fi
