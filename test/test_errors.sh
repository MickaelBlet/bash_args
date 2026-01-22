#!/usr/bin/env bash

#
# Error handling tests for args.sh
#

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"
source "${SCRIPT_DIR}/../args.sh"

#
# Test Functions
#

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

#
# Run tests if executed directly
#

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Running error handling tests..."
    echo ""

    run_test "error on invalid option" test_error_on_invalid_option
    run_test "error on missing required value" test_error_on_missing_required_value
    run_test "error on extra arguments" test_error_on_extra_arguments

    echo ""
    echo "Error handling tests: $PASSED_TESTS passed, $FAILED_TESTS failed"
fi
