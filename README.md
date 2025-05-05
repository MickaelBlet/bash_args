# Args

Parse and store arguments/options from `argv` natively on **bash**.  
Inspired by the Python library [argparse](https://python.readthedocs.io/en/latest/library/argparse.html).  
Compatible with **bash** version >= **4.2.0**.  
Documentations available at [documentations](#documentations).

## Quikstart

```bash
#!/usr/bin/env bash

set -euo pipefail

source "args.sh"

args_set_description "example" "of" "description"
args_set_epilog "example of epilog"

args_add_argument \
    --help "take the first argument" \
    --dest "ARG1_VALUE" \
    --required \
    -- "ARG1"
args_add_argument \
    --flag="-p" --flag="--print-hello" \
    --help="print hello" \
    --action="store_true" \
    --dest="DO_HELLO"
args_add_argument \
    --help="help of option" \
    --metavar="VALUE" \
    --default="24" \
    -- "--option"

args_parse_arguments "$@"

echo "'ARG1' argument from dest ${ARG1_VALUE:-}"
echo "'ARG1' argument from map  ${ARGS[ARG1]}"
echo "'--option' option from map ${ARGS[option]}"
if ${DO_HELLO:-false}; then
    echo "Hello world"
fi
```

```
$ ./example/quickstart.sh
usage: quickstart.sh [-h] [-p] [--option VALUE] -- ARG1
quickstart.sh: argument 'ARG1' is required
$ ./example/quickstart.sh -h
usage: quickstart.sh [-h] [-p] [--option VALUE] -- ARG1

example of description

positional arguments:
  ARG1                  take the first argument

optional arguments:
  -h, --help            print this help message
  -p, --print-hello     print hello
  --option VALUE        help of option

example of epilog
$ ./example/quickstart.sh 42
'ARG1' argument from dest 42
'ARG1' argument from map  42
'--option' option from map 24
$ ./example/quickstart.sh 42 -p
'ARG1' argument from dest 42
'ARG1' argument from map  42
'--option' option from map 24
Hello world
$ ./example/quickstart.sh 42 -p --option 42
'ARG1' argument from dest 42
'ARG1' argument from map  42
'--option' option from map 42
Hello world
```

## Documentations

### Functions

|Function|Description|
|--:|---|
|[args_add_argument](docs/functions.md#args_add_argument)|Add a argument.|
|[args_parse_arguments](docs/functions.md#args_parse_arguments)|Convert argument strings to objects and assign them as attributes on the ARGS map.|
|[args_clean](docs/functions.md#args_clean)|Clean all map and array for recalled.|
|[args_count](docs/functions.md#args_count)|Count the number of occurence of argument after parsed.|
|[args_debug_values](docs/functions.md#args_debug_values)|Show all values of arguments and options.|
|[args_isexists](docs/functions.md#args_isexists)|Check if argument is exists after parsed.|
|[args_set_alternative](docs/functions.md#args_set_alternative)|Set if args_parse_arguments can be accept a single '-' for a long option.|
|[args_set_description](docs/functions.md#args_set_description)|Set a usage description.|
|[args_set_epilog](docs/functions.md#args_set_epilog)|Set a epilog description.|
|[args_set_program_name](docs/functions.md#args_set_program_name)|Set the program name for usage message.|
|[args_set_usage_widths](docs/functions.md#args_set_usage_widths)|Set the widths of usage message.|
|[args_set_usage](docs/functions.md#args_set_usage)|Set a full usage message.|
|[args_usage](docs/functions.md#args_usage)|Show/Generate usage message.|

### Global variables

|Name|Description|
|--:|---|
|__ARGS|Assossiative array for use internaly in args script.|
|ARGS|Assossiative array for store after [args_parse_arguments](../README.md#args_parse_arguments).|