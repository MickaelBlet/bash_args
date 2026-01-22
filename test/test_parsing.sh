#!/usr/bin/env bash

#
# Special parsing features tests for args.sh
#

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"
source "${SCRIPT_DIR}/../args.sh"

#
# Test Functions
#

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

test_short_option_with_value_attached() {
    args_add_argument --flag "-o" --action store
    args_parse_arguments "-ovalue"
    assert_equals "value" "${ARGS[o]}" "option -o should be value"
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

#
# Run tests if executed directly
#

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Running parsing features tests..."
    echo ""

    run_test "double dash separator" test_double_dash_separator
    run_test "multi short flags combined" test_multi_short_flags
    run_test "short option with value attached" test_short_option_with_value_attached
    run_test "set_alternative true allows single dash" test_set_alternative_true
    run_test "set_alternative false rejects single dash" test_set_alternative_false
    run_test "help option auto-added" test_help_option_auto_added

    echo ""
    echo "Parsing tests: $PASSED_TESTS passed, $FAILED_TESTS failed"
fi
