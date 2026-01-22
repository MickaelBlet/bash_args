#!/usr/bin/env bash

#
# Abbreviation functionality tests for args.sh
#

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test_helpers.sh"
source "${SCRIPT_DIR}/../args.sh"

#
# Test Functions
#

test_basic_abbreviation() {
    args_add_argument --flag="--verbose" --action="store_true"
    args_add_argument --flag="--value" --action="store"
    args_parse_arguments "--verb"
    assert_equals "true" "${ARGS[verbose]}" "verbose should be true with abbreviation"
}

test_abbreviation_with_value() {
    args_add_argument --flag="--output" --action="store"
    args_add_argument --flag="--option" --action="store"
    args_parse_arguments "--out" "myfile.txt"
    assert_equals "myfile.txt" "${ARGS[output]}" "output should be myfile.txt"
}

test_abbreviation_with_equals() {
    args_add_argument --flag="--output" --action="store"
    args_add_argument --flag="--optimize" --action="store"
    args_parse_arguments "--ou=test.txt"
    assert_equals "test.txt" "${ARGS[output]}" "output should be test.txt"
}

test_ambiguous_abbreviation() {
    args_add_argument --flag="--verbose" --action="store_true"
    args_add_argument --flag="--version" --action="store_true"
    assert_fails args_parse_arguments "--ver"
}

test_nonexistent_abbreviation() {
    args_add_argument --flag="--verbose" --action="store_true"
    assert_fails args_parse_arguments "--notexist"
}

test_full_option_with_abbreviation() {
    args_add_argument --flag="--verbose" --action="store_true"
    args_parse_arguments "--verbose"
    assert_equals "true" "${ARGS[verbose]}" "full option name should still work"
}

test_abbreviation_store_true() {
    args_add_argument --flag="--enable-feature" --action="store_true"
    args_parse_arguments "--enable"
    assert_equals "true" "${ARGS[enable-feature]}" "enable-feature should be true"
}

test_abbreviation_store_false() {
    args_add_argument --flag="--disable-feature" --action="store_false"
    args_parse_arguments "--disable"
    assert_equals "false" "${ARGS[disable-feature]}" "disable-feature should be false"
}

test_abbreviation_count() {
    args_add_argument --flag="--verbose" --action="count"
    args_parse_arguments "--verb" "--verb" "--verb"
    assert_equals "3" "${ARGS[verbose]}" "verbose count should be 3"
}

test_abbreviation_append() {
    args_add_argument --flag="--include" --action="append"
    args_parse_arguments "--inc" "path1" "--inc" "path2"
    assert_equals "path1 path2" "${ARGS[include]}" "include should contain both paths"
}

test_abbreviation_with_choices() {
    args_add_argument --flag="--format" --action="store" --choices="json xml yaml"
    args_parse_arguments "--form" "json"
    assert_equals "json" "${ARGS[format]}" "format should be json"
}

test_abbreviation_alternative_mode() {
    args_set_alternative true
    args_add_argument --flag="--verbose" --action="store_true"
    args_add_argument --flag="--value" --action="store"
    args_parse_arguments "-verb"
    assert_equals "true" "${ARGS[verbose]}" "verbose should work in alternative mode"
}

test_abbreviation_alternative_equals() {
    args_set_alternative true
    args_add_argument --flag="--output" --action="store"
    args_add_argument --flag="--option" --action="store"
    args_parse_arguments "-out=test.txt"
    assert_equals "test.txt" "${ARGS[output]}" "output should work with = in alternative mode"
}

test_single_char_abbreviation() {
    args_add_argument --flag="--verbose" --action="store_true"
    args_add_argument --flag="--output" --action="store"
    args_parse_arguments "--v"
    assert_equals "true" "${ARGS[verbose]}" "single char abbreviation should work"
}

test_abbreviation_vs_short_option() {
    args_add_argument --flag="-v" --flag="--verbose" --action="store_true"
    args_add_argument --flag="-e" --flag="--enable" --action="store_true"
    args_parse_arguments "-v"
    assert_equals "true" "${ARGS[v]}" "short option should match exactly"
    assert_equals "true" "${ARGS[verbose]}" "both short and long should be set"
}

#
# Run tests if executed directly
#

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Running abbreviation functionality tests..."
    echo ""

    run_test "basic abbreviation matching" test_basic_abbreviation
    run_test "abbreviation with separate value" test_abbreviation_with_value
    run_test "abbreviation with equals syntax" test_abbreviation_with_equals
    run_test "ambiguous abbreviation fails" test_ambiguous_abbreviation
    run_test "non-existent abbreviation fails" test_nonexistent_abbreviation
    run_test "full option name still works" test_full_option_with_abbreviation
    run_test "abbreviation with store_true" test_abbreviation_store_true
    run_test "abbreviation with store_false" test_abbreviation_store_false
    run_test "abbreviation with count" test_abbreviation_count
    run_test "abbreviation with append" test_abbreviation_append
    run_test "abbreviation with choices" test_abbreviation_with_choices
    run_test "abbreviation in alternative mode" test_abbreviation_alternative_mode
    run_test "abbreviation with equals in alternative mode" test_abbreviation_alternative_equals
    run_test "single character abbreviation" test_single_char_abbreviation
    run_test "short option vs abbreviation" test_abbreviation_vs_short_option

    echo ""
    echo "Abbreviation tests: $PASSED_TESTS passed, $FAILED_TESTS failed"
fi
