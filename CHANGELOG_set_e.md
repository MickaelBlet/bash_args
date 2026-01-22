# Changes for set -euo pipefail Compatibility

## Summary

Made args.sh fully compatible with Bash strict mode (`set -euo pipefail`) to ensure robust error handling in production scripts.

## Issues Fixed

### 1. Command Substitution Exit Code Handling

**Problem**: When `set -e` is active, command substitutions that return non-zero exit codes cause the script to exit immediately, preventing proper error handling.

**Location**: `args_parse_arguments` function when calling `__args_parse_option_find_by_abbrev`

**Solution**: Temporarily disable `set -e` around the command substitution to capture both output and exit code:

```bash
# Save set -e state
local errexit_was_set=false
if [[ $- == *e* ]]; then
    errexit_was_set=true
    set +e
fi

# Call function that may return non-zero
abbrev_match=$(__args_parse_option_find_by_abbrev "${abbrev_arg}" "${binary_name}")
local abbrev_result=$?

# Restore set -e if it was enabled
if [[ "${errexit_was_set}" == "true" ]]; then
    set -e
fi
```

### 2. Missing Usage Lines in Error Messages

**Problem**: Invalid option errors didn't show usage lines, making it inconsistent with other error messages.

**Locations**:
- Invalid long option handling (line ~1884)
- Invalid short option handling (line ~1888)

**Solution**: Added `args_usage_line "${binary_name}"` before error messages:

```bash
# Before
__args_echo_error "${binary_name}" "invalid option -- '$1'"
return 1

# After
args_usage_line "${binary_name}"
__args_echo_error "${binary_name}" "invalid option -- '$1'"
return 1
```

### 3. Ambiguous Abbreviation Error in Command Substitution

**Problem**: When reporting ambiguous abbreviations from within `__args_parse_option_find_by_abbrev`, the usage line was captured by command substitution instead of being displayed.

**Location**: `__args_parse_option_find_by_abbrev` function (line ~295)

**Solution**: Redirect usage line output to stderr:

```bash
args_usage_line "${binary_name}" >&2
__args_echo_error "${binary_name}" "ambiguous option: '${abbrev}' could match: ${matching_options[*]}"
```

## Changes Summary

### Modified Files

1. **args.sh**:
   - Added set -e state management around command substitution (lines ~1759-1770)
   - Added usage line to invalid option errors (lines 1884, 1888)
   - Added stderr redirect for usage line in abbreviation function (line ~295)

2. **test/test_set_e_compatibility.sh** (NEW):
   - Added 6 comprehensive tests for set -euo pipefail compatibility
   - Tests cover: invalid options, ambiguous abbreviations, missing required, valid parsing

3. **test/run_all_tests.sh**:
   - Integrated set -e compatibility tests into main test suite

4. **README.md**:
   - Added "Strict Mode Compatible" to features list
   - Added "Strict Mode Compatibility" section with examples
   - Documented error handling behavior with set -e

5. **example/strict_mode_demo.sh** (NEW):
   - Created demonstration script showing args.sh working with `set -euo pipefail`
   - Shows proper error handling and abbreviation support

## Test Results

- **Total Tests**: 68 (62 existing + 6 new)
- **Pass Rate**: 100%
- **New Test Coverage**:
  - Invalid option with set -e
  - Ambiguous abbreviation with set -e
  - Missing required option with set -e
  - Valid abbreviation with set -e
  - Successful parsing with set -e
  - set -u (nounset) compatibility

## Backward Compatibility

All changes are fully backward compatible:
- Scripts without `set -e` work exactly as before
- The set -e state detection only affects behavior when set -e is active
- No changes to the public API
- All existing tests continue to pass

## Benefits

1. **Production Ready**: Scripts using args.sh can safely use `set -euo pipefail` for robust error handling
2. **Better Error Messages**: Consistent usage line display across all error types
3. **User Friendly**: Even with strict mode, users always get helpful error messages before the script exits
4. **Reliable**: Prevents silent failures and ensures errors are caught early
