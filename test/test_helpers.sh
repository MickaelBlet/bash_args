#!/usr/bin/env bash

#
# Helper functions for test suite
#

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters (should be imported from main test script)
if [[ -z "${TOTAL_TESTS+x}" ]]; then
    TOTAL_TESTS=0
    PASSED_TESTS=0
    FAILED_TESTS=0
fi

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Helper function to run a test
run_test() {
    local test_name="$1"
    local test_func="$2"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    # Run test in subshell to isolate environment
    # Redirect stderr and stdout to suppress expected error messages
    if (
        args_clean
        $test_func
    ) >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} ${test_name}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "${RED}✗${NC} ${test_name}"
        # Re-run test to show actual error
        (
            args_clean
            $test_func
        ) 2>&1 | head -10
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
