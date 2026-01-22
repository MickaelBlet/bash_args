#!/usr/bin/env bash

#
# Helper functions tests for args.sh
#

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"
source "${SCRIPT_DIR}/../args.sh"

#
# Test Functions
#

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

#
# Run tests if executed directly
#

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Running helper functions tests..."
    echo ""

    run_test "args_isexists returns true" test_args_isexists_true
    run_test "args_isexists returns false" test_args_isexists_false
    run_test "args_count returns correct count" test_args_count
    run_test "set_description" test_set_description
    run_test "set_epilog" test_set_epilog
    run_test "set_program_name" test_set_program_name

    echo ""
    echo "Helper function tests: $PASSED_TESTS passed, $FAILED_TESTS failed"
fi
