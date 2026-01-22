#!/usr/bin/env bash

# Demonstrate args.sh compatibility with Bash strict mode
set -euo pipefail

# Source the args.sh library
source "$(dirname "$0")/../args.sh"

# Set up the argument parser
args_set_description "Demonstration of args.sh with set -euo pipefail enabled"
args_set_epilog "This script demonstrates robust error handling with strict mode."

# Add various argument types
args_add_argument \
    --flag="--verbose" \
    --help="enable verbose output" \
    --action="store_true"

args_add_argument \
    --flag="--output" \
    --help="output file (required)" \
    --action="store" \
    --metavar="FILE" \
    --required

args_add_argument \
    --flag="--format" \
    --help="output format" \
    --action="store" \
    --choices="json xml yaml" \
    --default="json"

args_add_argument \
    --flag="--count" \
    --help="number of items to process" \
    --action="store" \
    --metavar="N" \
    --default="10"

# Parse arguments - errors are handled gracefully even with set -e
args_parse_arguments "$@"

# Display results (safe to access with set -u)
echo "=== Configuration ==="
echo "Verbose:  ${ARGS[verbose]:-false}"
echo "Output:   ${ARGS[output]}"
echo "Format:   ${ARGS[format]}"
echo "Count:    ${ARGS[count]}"
echo ""
echo "✓ All arguments parsed successfully with set -euo pipefail enabled!"
echo ""
echo "Try these to see error handling:"
echo "  $0 --invalid                    # Invalid option error"
echo "  $0                              # Missing required option error"
echo "  $0 --out result.txt             # Abbreviation works!"
echo "  $0 --output test.txt --form xml # Abbreviations work!"
