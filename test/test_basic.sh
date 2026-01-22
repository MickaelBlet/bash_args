#!/usr/bin/env bash

#
# Basic functionality tests for args.sh
#

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"
source "${SCRIPT_DIR}/../args.sh"

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

test_mixed_options_and_arguments() {
    args_add_argument --flag "-v" --action store_true
    args_add_argument --flag "--output" --action store
    args_add_argument --name "INPUT"
    args_parse_arguments "-v" "--output" "out.txt" "input.txt"
    assert_equals "true" "${ARGS[v]}" "flag -v should be true"
    assert_equals "out.txt" "${ARGS[output]}" "output should be out.txt"
    assert_equals "input.txt" "${ARGS[INPUT]}" "INPUT should be input.txt"
}

#
# Run tests if executed directly
#

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Running basic functionality tests..."
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
    run_test "mixed options and arguments" test_mixed_options_and_arguments

    echo ""
    echo "Basic tests: $PASSED_TESTS passed, $FAILED_TESTS failed"
fi
