#!/bin/bash

# set -x

set -euo pipefail

source "args.sh"

args_set_description "example" "of" "description"
args_set_epilog "example of epilog"

args_set_alternative true

args_add_argument \
    --help "take the first argument" \
    --dest "ARG1" \
    --required \
    --choices "TOTO TATA" \
    -- "ARG1"
args_add_argument \
    --help "take the second argument" \
    --dest "ARG2" \
    --default="42" \
    -- "ARG2"
args_add_argument \
    --help="print hello" \
    --action="store_true" \
    --dest="DO_HELLO" \
    -- "-p" "--print-hello" "-g" "-b" "-d" "-e" "-f"
args_add_argument \
    --help="help of option" \
    --nargs="*" \
    --default="TOTO OPTION2" \
    --dest=OPTIONS \
    -- "--option" "-a"
args_add_argument \
    --help="help of append pdqpoj wdpqojwd pqowjd pqwojdpqowdj pqojwd qpowjd qpj" \
    --action="append" \
    --default="APPP1 APPP2" \
    --dest=APPEND \
    -- "--append" "-o"
args_add_argument \
    --help="help of count" \
    --action="count" \
    -- "--count" "-c"

args_parse_arguments "$@"

args_count "-c"
echo "${ARGS[c]}"

echo "'ARG1' argument from dest ${ARG1:-}"
echo "'ARG2' argument from dest ${ARG2:-}"
echo "'ARG1' argument from map  ${ARGS[ARG1]}"
echo "'--option' option from map ${ARGS[option.0]:-}"
echo "'--option' option from map ${ARGS[option.1]:-}"
echo "'--option' option from map ${ARGS[option.2]:-}"

echo "'--append' option from map ${ARGS[a.0]:-}"
echo "'--append' option from map ${ARGS[a.1]:-}"
echo "'--append' option from map ${ARGS[a.2]:-}"

echo "'--option' option from map ${ARGS[option]:-}"
echo "'--option' option from dest ${OPTIONS[*]:-}"

if [[ "${#OPTIONS[@]}" -eq 0 ]]; then
    OPTIONS=()
fi

if [[ "${#APPEND[@]}" -eq 0 ]]; then
    APPEND=()
fi

for op in "${OPTIONS[@]}"; do
    echo "${op}"
done

for op in "${APPEND[@]}"; do
    echo "${op}"
done
if ${DO_HELLO:-false}; then
    echo "Hello world"
fi

echo

args_debug_values

# set -o posix ; set