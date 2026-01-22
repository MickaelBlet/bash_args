#!/usr/bin/env bash

#
# Action types tests for args.sh
#

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"
source "${SCRIPT_DIR}/../args.sh"

#
# Test Functions
#

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

test_append_action() {
    args_add_argument --flag "-i" --action append
    args_parse_arguments "-i" "val1" "-i" "val2" "-i" "val3"
    assert_equals "val1" "${ARGS[i.0]}" "first value should be val1"
    assert_equals "val2" "${ARGS[i.1]}" "second value should be val2"
    assert_equals "val3" "${ARGS[i.2]}" "third value should be val3"
}

#
# Run tests if executed directly
#

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Running action types tests..."
    echo ""

    run_test "store_true action" test_store_true_action
    run_test "store_false action" test_store_false_action
    run_test "store_true default value" test_store_true_default
    run_test "count action" test_count_action
    run_test "count action default value" test_count_action_default
    run_test "append action" test_append_action

    echo ""
    echo "Action tests: $PASSED_TESTS passed, $FAILED_TESTS failed"
fi
