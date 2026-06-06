#!/usr/bin/env bash

#
# Main test runner - runs all test suites
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Global test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Source test helpers
source "${SCRIPT_DIR}/test_helpers.sh"

# Source args.sh
source "${SCRIPT_DIR}/../args.sh"

echo "========================================"
echo "  Running args.sh Test Suite"
echo "========================================"
echo ""

# Run test_basic.sh
echo -e "${BLUE}Running basic functionality tests...${NC}"
source "${SCRIPT_DIR}/test_basic.sh"
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

# Run test_actions.sh
echo -e "${BLUE}Running action types tests...${NC}"
source "${SCRIPT_DIR}/test_actions.sh"
run_test "store_true action" test_store_true_action
run_test "store_false action" test_store_false_action
run_test "store_true default value" test_store_true_default
run_test "count action" test_count_action
run_test "count action default value" test_count_action_default
run_test "append action" test_append_action
echo ""

# Run test_advanced.sh
echo -e "${BLUE}Running advanced features tests...${NC}"
source "${SCRIPT_DIR}/test_advanced.sh"
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

# Run test_parsing.sh
echo -e "${BLUE}Running parsing features tests...${NC}"
source "${SCRIPT_DIR}/test_parsing.sh"
run_test "double dash separator" test_double_dash_separator
run_test "multi short flags combined" test_multi_short_flags
run_test "short option with value attached" test_short_option_with_value_attached
run_test "set_alternative true allows single dash" test_set_alternative_true
run_test "set_alternative false rejects single dash" test_set_alternative_false
run_test "help option auto-added" test_help_option_auto_added
echo ""

# Run test_abbreviation.sh
echo -e "${BLUE}Running abbreviation tests...${NC}"
source "${SCRIPT_DIR}/test_abbreviation.sh"
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

# Run test_helper_functions.sh
echo -e "${BLUE}Running helper functions tests...${NC}"
source "${SCRIPT_DIR}/test_helper_functions.sh"
run_test "args_isexists returns true" test_args_isexists_true
run_test "args_isexists returns false" test_args_isexists_false
run_test "args_count returns correct count" test_args_count
run_test "set_description" test_set_description
run_test "set_epilog" test_set_epilog
run_test "set_program_name" test_set_program_name
echo ""

# Run test_errors.sh
echo -e "${BLUE}Running error handling tests...${NC}"
source "${SCRIPT_DIR}/test_errors.sh"
run_test "error on invalid option" test_error_on_invalid_option
run_test "error on missing required value" test_error_on_missing_required_value
run_test "error on extra arguments" test_error_on_extra_arguments
echo ""

# Run test_set_e_compatibility.sh
echo -e "${BLUE}Running set -e compatibility tests...${NC}"
source "${SCRIPT_DIR}/test_set_e_compatibility.sh"
run_test "invalid option with set -e" test_set_e_invalid_option
run_test "ambiguous abbreviation with set -e" test_set_e_ambiguous_abbreviation
run_test "missing required with set -e" test_set_e_missing_required
run_test "valid abbreviation with set -e" test_set_e_valid_abbreviation
run_test "successful parse with set -e" test_set_e_successful_parse
run_test "set -u compatibility" test_set_e_with_nounset
echo ""

#
# Print summary
#

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
