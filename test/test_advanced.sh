#!/usr/bin/env bash

#
# Advanced features tests for args.sh
#

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"
source "${SCRIPT_DIR}/../args.sh"

#
# Test Functions
#

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

test_nargs_question_mark() {
    args_add_argument --flag "--optional" --nargs "?"
    args_parse_arguments "--optional"
    # Should succeed even without value
    return 0
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

test_dest_variable_array_access() {
    args_add_argument --flag "--option" --action store --dest "MY_VAR"
    args_parse_arguments "--option" "test_value"
    assert_equals "test_value" "${MY_VAR[0]}" "MY_VAR[0] should be test_value"
}

test_dest_variable_overwrite() {
    MY_VAR="initial_value"
    args_add_argument --flag "--option" --action store --dest "MY_VAR"
    args_parse_arguments "--option" "second_value"
    assert_equals "second_value" "${MY_VAR}" "MY_VAR should hold the latest value"
    assert_equals "1" "${#MY_VAR[@]}" "MY_VAR should hold a single element"
}

test_dest_variable_nargs() {
    args_add_argument --flag "--point" --nargs 2 --dest "POINT_VAR"
    args_parse_arguments "--point" "1" "2"
    assert_equals "1" "${POINT_VAR[0]}" "POINT_VAR[0] should be 1"
    assert_equals "2" "${POINT_VAR[1]}" "POINT_VAR[1] should be 2"
}

test_dest_variable_empty_value() {
    args_add_argument --flag "--option" --nargs "?" --dest "OPT_VAR"
    args_parse_arguments "--option"
    assert_equals "" "${OPT_VAR}" "OPT_VAR should be empty"
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

test_default_with_choices() {
    args_add_argument --flag "--level" --choices "debug info warn error" --default "info"
    args_parse_arguments
    assert_equals "info" "${ARGS[level]}" "level should default to info"
}

#
# Run tests if executed directly
#

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Running advanced features tests..."
    echo ""

    run_test "required option fails when missing" test_required_option
    run_test "required option satisfied" test_required_option_satisfied
    run_test "option with default value" test_option_with_default
    run_test "option overrides default value" test_option_overrides_default
    run_test "choices with valid value" test_choices_valid
    run_test "choices with invalid value fails" test_choices_invalid
    run_test "positional choices with valid value" test_positional_choices_valid
    run_test "positional choices with invalid value fails" test_positional_choices_invalid
    run_test "nargs with value 2" test_nargs_two
    run_test "nargs ? (question mark)" test_nargs_question_mark
    run_test "infinite nargs +" test_infinite_nargs_plus
    run_test "infinite nargs *" test_infinite_nargs_star
    run_test "infinite nargs * with empty" test_infinite_nargs_star_empty
    run_test "dest variable" test_dest_variable
    run_test "dest variable array access" test_dest_variable_array_access
    run_test "dest variable overwrite single element" test_dest_variable_overwrite
    run_test "dest variable with nargs" test_dest_variable_nargs
    run_test "dest variable empty value" test_dest_variable_empty_value
    run_test "metavar in usage" test_metavar_in_usage
    run_test "default with choices" test_default_with_choices

    echo ""
    echo "Advanced tests: $PASSED_TESTS passed, $FAILED_TESTS failed"
fi
