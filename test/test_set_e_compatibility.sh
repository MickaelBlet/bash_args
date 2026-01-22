#!/usr/bin/env bash

#
# Compatibility tests for set -euo pipefail
#

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"
source "${SCRIPT_DIR}/../args.sh"

#
# Test Functions
#

test_set_e_invalid_option() {
    # Test that invalid options show proper error messages with set -e
    local output
    output=$(bash -c '
        set -euo pipefail
        source "'"${SCRIPT_DIR}"'/../args.sh"
        args_add_argument --flag="--verbose" --action="store_true"
        args_parse_arguments --invalid 2>&1
    ' || true)

    [[ "${output}" == *"usage:"* ]] || return 1
    [[ "${output}" == *"invalid option"* ]] || return 1
    return 0
}

test_set_e_ambiguous_abbreviation() {
    # Test that ambiguous abbreviations show proper error messages with set -e
    local output
    output=$(bash -c '
        set -euo pipefail
        source "'"${SCRIPT_DIR}"'/../args.sh"
        args_add_argument --flag="--verbose" --action="store_true"
        args_add_argument --flag="--version" --action="store_true"
        args_parse_arguments --ver 2>&1
    ' || true)

    [[ "${output}" == *"usage:"* ]] || return 1
    [[ "${output}" == *"ambiguous option"* ]] || return 1
    [[ "${output}" == *"--verbose"* ]] || return 1
    [[ "${output}" == *"--version"* ]] || return 1
    return 0
}

test_set_e_missing_required() {
    # Test that missing required options show proper error messages with set -e
    local output
    output=$(bash -c '
        set -euo pipefail
        source "'"${SCRIPT_DIR}"'/../args.sh"
        args_add_argument --flag="--output" --action="store" --required
        args_parse_arguments 2>&1
    ' || true)

    [[ "${output}" == *"usage:"* ]] || return 1
    [[ "${output}" == *"required"* ]] || return 1
    return 0
}

test_set_e_valid_abbreviation() {
    # Test that valid abbreviations work correctly with set -e
    local output
    output=$(bash -c '
        set -euo pipefail
        source "'"${SCRIPT_DIR}"'/../args.sh"
        args_add_argument --flag="--verbose" --action="store_true"
        args_add_argument --flag="--version" --action="store_true"
        args_parse_arguments --verb
        echo "verbose=${ARGS[verbose]}"
    ')

    assert_equals "verbose=true" "${output}" "should parse abbreviation successfully"
}

test_set_e_successful_parse() {
    # Test that successful parsing works with set -e
    local output
    output=$(bash -c '
        set -euo pipefail
        source "'"${SCRIPT_DIR}"'/../args.sh"
        args_add_argument --flag="--output" --action="store"
        args_parse_arguments --output test.txt
        echo "output=${ARGS[output]}"
    ')

    assert_equals "output=test.txt" "${output}" "should parse successfully"
}

test_set_e_with_nounset() {
    # Test that unset variable access doesn't cause issues with set -u
    local output
    output=$(bash -c '
        set -euo pipefail
        source "'"${SCRIPT_DIR}"'/../args.sh"
        args_add_argument --flag="--optional" --action="store"
        args_parse_arguments
        # Access potentially unset variable safely
        echo "optional=${ARGS[optional]:-<not set>}"
    ')

    assert_equals "optional=<not set>" "${output}" "should handle unset variables"
}

#
# Run tests if executed directly
#

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Running set -euo pipefail compatibility tests..."
    echo ""

    run_test "invalid option with set -e" test_set_e_invalid_option
    run_test "ambiguous abbreviation with set -e" test_set_e_ambiguous_abbreviation
    run_test "missing required with set -e" test_set_e_missing_required
    run_test "valid abbreviation with set -e" test_set_e_valid_abbreviation
    run_test "successful parse with set -e" test_set_e_successful_parse
    run_test "set -u compatibility" test_set_e_with_nounset

    echo ""
    echo "set -e compatibility tests: $PASSED_TESTS passed, $FAILED_TESTS failed"
fi
