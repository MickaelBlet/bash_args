#!/usr/bin/env bash

set -euo pipefail

# Source the args.sh library
source "$(dirname "$0")/../args.sh"

# Set description and epilog
args_set_description "Demonstration of option abbreviation support"
args_set_epilog "Try using abbreviated options like --verb, --vers, --out, or --opt!"

# Add options with long names
args_add_argument \
    --flag="--verbose" \
    --help="enable verbose output" \
    --action="store_true"

args_add_argument \
    --flag="--version" \
    --help="show version information" \
    --action="store_true"

args_add_argument \
    --flag="--output" \
    --help="specify output file" \
    --action="store" \
    --metavar="FILE"

args_add_argument \
    --flag="--optimize" \
    --help="optimization level (0-3)" \
    --action="store" \
    --metavar="LEVEL" \
    --default="0"

# Parse the command-line arguments
args_parse_arguments "$@"

# Display results
echo "=== Parsed Arguments ==="
echo "verbose:  ${ARGS[verbose]:-false}"
echo "version:  ${ARGS[version]:-false}"
echo "output:   ${ARGS[output]:-<not set>}"
echo "optimize: ${ARGS[optimize]}"
echo ""
echo "Try these examples:"
echo "  $0 --verb                  # abbreviation for --verbose"
echo "  $0 --vers                  # abbreviation for --version"
echo "  $0 --out result.txt        # abbreviation for --output"
echo "  $0 --opt=3                 # abbreviation for --optimize"
echo "  $0 --ver                   # ambiguous! (matches both --verbose and --version)"
