# Args

A powerful and flexible argument parser for **Bash** scripts, inspired by Python's [argparse](https://python.readthedocs.io/en/latest/library/argparse.html).  
Parse command-line arguments and options natively in Bash with automatic help generation, type validation, and more.

**Compatible with Bash version >= 4.2.0**

## Features

- **Positional Arguments** - Define required or optional positional parameters
- **Optional Arguments** - Support for short (`-f`) and long (`--flag`) options
- **Option Abbreviation** - Use shortened versions of long options (e.g., `--verb` for `--verbose`)
- **Multiple Actions** - Store values, booleans, counts, or append to lists
- **Validation** - Enforce choices, required arguments, and value constraints
- **Flexible Parsing** - Support for `nargs`, default values, and custom metavar
- **Auto-Generated Help** - Automatic `-h`/`--help` with formatted usage messages
- **Destination Variables** - Store parsed values directly to custom variables
- **Alternative Mode** - Accept single dash for long options (`-option` instead of `--option`)
- **Strict Mode Compatible** - Fully compatible with `set -euo pipefail` for robust error handling

For detailed documentation, see [Documentation](#documentation).

## Installation

Simply source the `args.sh` script in your Bash script:

```bash
source "args.sh"
```

Or use an absolute/relative path:

```bash
source "/path/to/args.sh"
```

## Quickstart

This example demonstrates the main features of the argument parser:

```bash
#!/usr/bin/env bash

set -euo pipefail

# Source the args.sh library
source "args.sh"

# Set description and epilog for help message
args_set_description "example" "of" "description"
args_set_epilog "example of epilog"

# Add a required positional argument
args_add_argument \
    --help "take the first argument" \
    --dest "ARG1_VALUE" \
    --required \
    -- "ARG1"

# Add a boolean flag (--print-hello or -p)
args_add_argument \
    --flag="-p" --flag="--print-hello" \
    --help="print hello" \
    --action="store_true" \
    --dest="DO_HELLO"

# Add an optional argument with a default value
args_add_argument \
    --help="help of option" \
    --metavar="VALUE" \
    --default="24" \
    -- "--option"

# Parse the command-line arguments
args_parse_arguments "$@"

# Access parsed values using destination variables or the ARGS map
echo "'ARG1' argument from dest ${ARG1_VALUE:-}"
echo "'ARG1' argument from map  ${ARGS[ARG1]}"
echo "'--option' option from map ${ARGS[option]}"
if ${DO_HELLO:-false}; then
    echo "Hello world"
fi
```

**Example usage:**

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

## Option Abbreviation

Args.sh supports automatic abbreviation of long option names, allowing users to type shortened versions as long as they are unambiguous.

### How It Works

When parsing a long option (starting with `--`), if an exact match isn't found, args.sh will attempt to match it as an abbreviation. The abbreviation must uniquely identify one option - if multiple options start with the same prefix, an error is reported.

### Examples

```bash
# Given options: --verbose, --version, --output, --optimize

# Valid abbreviations:
./script.sh --verb      # matches --verbose
./script.sh --vers      # matches --version
./script.sh --out       # matches --output
./script.sh --opt       # matches --optimize

# Ambiguous abbreviations (will fail with helpful error):
./script.sh --ver       # Could match: --verbose OR --version
./script.sh --o         # Could match: --output OR --optimize

# Works with all syntax forms:
./script.sh --verb              # boolean flag
./script.sh --out file.txt      # separate value
./script.sh --out=file.txt      # assignment syntax
./script.sh --opt 3             # numeric value
```

### Abbreviation with Alternative Mode

Abbreviations work seamlessly with alternative mode (single dash for long options):

```bash
args_set_alternative true

# These all work:
./script.sh -verbose      # full option name
./script.sh -verb         # abbreviated
./script.sh -out=file.txt # abbreviated with assignment
```

### Error Handling

- **Ambiguous abbreviation**: Lists all matching options
  ```
  script.sh: ambiguous option: '--ver' could match: --verbose --version
  ```
- **Non-existent abbreviation**: Reports invalid option
  ```
  script.sh: invalid option -- '--notfound'
  ```

### Notes

- Abbreviations only work for **long options** (`--option`), not short options (`-o`)
- Full option names always work alongside abbreviations
- Exact matches take precedence over abbreviations
- Single-character abbreviations work if unambiguous

## Strict Mode Compatibility

Args.sh is fully compatible with Bash strict mode (`set -euo pipefail`), ensuring robust error handling in production scripts.

```bash
#!/usr/bin/env bash

set -euo pipefail  # Enable strict mode

source "args.sh"

args_add_argument --flag="--output" --action="store" --required
args_add_argument --flag="--verbose" --action="store_true"

# Errors are handled gracefully with proper usage messages
args_parse_arguments "$@"

# Access parsed values safely
echo "Output: ${ARGS[output]}"
echo "Verbose: ${ARGS[verbose]:-false}"
```

### Error Handling

All error cases display proper usage information before exiting:

- **Invalid options**: Shows usage line and error message
- **Missing required options**: Shows usage line and which option is required
- **Ambiguous abbreviations**: Shows usage line and lists matching options
- **Invalid choice values**: Shows usage line and valid choices

This ensures users always get helpful feedback, even with `set -e` enabled.

## Documentation

### Functions

|Function|Description|
|--:|---|
|[args_add_argument](docs/functions.md#args_add_argument)|Add a argument.|
|[args_parse_arguments](docs/functions.md#args_parse_arguments)|Convert argument strings to objects and assign them as attributes on the ARGS map.|
|[args_clean](docs/functions.md#args_clean)|Clean all map and array for recalled.|
|[args_count](docs/functions.md#args_count)|Count the number of occurence of argument after parsed.|
|[args_debug_values](docs/functions.md#args_debug_values)|Show all values of arguments and options.|
|[args_isexists](docs/functions.md#args_isexists)|Check if argument is exists after parsed.|
|[args_set_alternative](docs/functions.md#args_set_alternative)|Set if args_parse_arguments can accept a single '-' for a long option.|
|[args_set_description](docs/functions.md#args_set_description)|Set a usage description.|
|[args_set_epilog](docs/functions.md#args_set_epilog)|Set a epilog description.|
|[args_set_program_name](docs/functions.md#args_set_program_name)|Set the program name for usage message.|
|[args_set_usage_widths](docs/functions.md#args_set_usage_widths)|Set the widths of usage message.|
|[args_set_usage](docs/functions.md#args_set_usage)|Set a full usage message.|
|[args_usage](docs/functions.md#args_usage)|Show/Generate usage message.|

### Global Variables

After calling `args_parse_arguments`, parsed values are accessible through these global variables:

|Name|Type|Description|
|--:|:--:|---|
|`ARGS`|Associative Array|Stores all parsed argument values. Access using `${ARGS[argument_name]}`|
|`__ARGS`|Associative Array|Internal storage used by args.sh. Do not modify directly.|
