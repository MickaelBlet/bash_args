# Functions

## args_add_argument

Define a positional or optional argument for the parser.

### Options

|Option|Description|
|--:|---|
|`--action ACTION`|Action to perform when argument is encountered (default: `store`)<br/>Valid actions: `append`, `count`, `store`, `store_true`, `store_false`<br/>See [Actions](#action) for details|
|`--choices CHOICES`|Whitespace-separated list of valid values|
|`--default DEFAULT`|Default value(s) if argument is not provided (multiple values separated by spaces)|
|`--dest DESTINATION`|Name of the global variable to store the value (if not specified, uses argument name)|
|`--flag FLAG`|Define this as an optional argument with the specified flag(s). Can be used multiple times for aliases|
|`--help HELP`|Description text shown in usage message|
|`--metavar METAVAR`|Display name for the argument in usage message (defaults to the argument name)|
|`--name NAME`|Explicit name for a positional argument|
|`--nargs NARGS`|Number of values this argument accepts<br/>- A number: exact count<br/>- `?`: 0 or 1<br/>- `*`: 0 or more<br/>- `+`: 1 or more|
|`--required`|Mark this argument as required|

### Return Value

Returns `1` on error, `0` on success.

```bash
args_add_argument [options...] -- [name/flags...]
```

### Action

Actions determine how argument values are processed and stored:

|Action|Description|
|--:|---|
|`store`|Store the argument's value (default action)|
|`store_true`|Store `true` when the flag is present, `false` otherwise. Used for boolean flags|
|`store_false`|Store `false` when the flag is present, `true` otherwise|
|`append`|Append each value to a list. Useful for options that can be specified multiple times.<br/>If a default value exists, command-line values are appended after the defaults|
|`count`|Count the number of times the argument appears. Returns a numeric value|

### Examples

```bash
# Simple positional argument
args_add_argument -- "FOO"

# Required positional argument
args_add_argument --name="FOO" --required

# Boolean flag (true when present)
args_add_argument --action "store_true" -- "-f" "--foo"

# Boolean flag (false when present)
args_add_argument --flag "-f" --flag "--foo" --action="store_false"

# Optional argument that stores a value
args_add_argument -- "-f" "--foo"

# Optional argument that accepts 2 values
args_add_argument --nargs="2" --metavar="FOO1 FOO2" -- "-f" "--foo"

# Counter argument (counts occurrences)
args_add_argument --action="count" -- "-f" "--foo"

# Argument with choices validation
args_add_argument --choices="dev prod staging" -- "--environment"

# Argument with default value and custom destination
args_add_argument --default="8080" --dest="PORT" -- "--port"
```

## args_parse_arguments

Parse command-line arguments and store them in the `ARGS` associative array and any specified destination variables.

This function must be called after all `args_add_argument` calls. It processes the command-line arguments according to the argument definitions and populates the global `ARGS` map with parsed values.

**Usage:**
```bash
args_parse_arguments "$@"
```

### Return Values

- `0` - Parsing succeeded
- `1` - Parsing failed (invalid arguments, missing required values, etc.)
- `64` - Help message was displayed (when `-h` or `--help` is used)

### Example

```bash
#!/usr/bin/env bash
source "args.sh"

args_add_argument --flag "-v" --action count --dest "VERBOSITY"
args_add_argument -- "input_file"

# Parse the arguments
args_parse_arguments "$@"

# Access parsed values
echo "Input file: ${ARGS[input_file]}"
echo "Verbosity level: ${VERBOSITY}"
```

## args_clean

Reset the argument parser state, clearing all arguments and configuration.

Call this function to start fresh when you need to parse arguments multiple times in the same script or to clean up before defining a new set of arguments.

### Example

```bash
# First parsing
args_add_argument -- "file1"
args_parse_arguments "$@"

# Reset and parse again with different arguments
args_clean
args_add_argument -- "file2"
args_parse_arguments "$@"
```

## args_count

Get the number of times an argument was provided on the command line.

Particularly useful with the `count` action or when checking how many times an optional argument was specified.

### Parameters

|Parameter|Description|
|--:|---|
|`$1`|Name of the argument (without dashes for options)|

### Return Value

Returns `0` and outputs the count to stdout.

### Example

```bash
args_add_argument --flag "-v" --action count
args_parse_arguments "$@"

# Get the count
count=$(args_count "v")
echo "Verbosity level: $count"
```

## args_debug_values

Display all parsed argument values for debugging purposes.

Outputs the contents of the `ARGS` associative array, showing all argument names and their corresponding values. Useful for troubleshooting argument parsing issues.

### Example

```bash
args_parse_arguments "$@"

# Show all parsed values
args_debug_values
```

## args_isexists

Check whether an argument was provided on the command line.

Returns success (`0`) if the argument exists, failure (`1`) otherwise. Useful for conditional logic based on whether optional arguments were provided.

### Parameters

|Parameter|Description|
|--:|---|
|`$1`|Name of the argument (without dashes for options)|

### Return Value

- `0` - Argument was provided
- `1` - Argument was not provided

### Example

```bash
args_add_argument --flag "--verbose"
args_parse_arguments "$@"

# Check if verbose was provided
if args_isexists "verbose"; then
    echo "Verbose mode enabled"
fi
```

## args_set_alternative

Enable or disable alternative parsing mode where long options can be specified with a single dash.

When enabled, both `-option` and `--option` are accepted for long option names. This is useful for compatibility with tools that use single-dash long options.

### Parameters

|Parameter|Description|
|--:|---|
|`$1`|Enable alternative mode: `true` or `false` (default: `false`)|

### Example

```bash
# Enable alternative mode
args_set_alternative true

args_add_argument -- "--verbose"

# Now both work:
# ./script.sh -verbose
# ./script.sh --verbose
```

## args_set_description

Set the description text displayed at the top of the help message.

All arguments are concatenated with spaces. The description appears after the usage line and before the argument list.

### Example

```bash
args_set_description "This script processes files and generates reports."
args_set_description "A simple example" "of a multi-part" "description"

# Both produce text that appears in --help output
```

## args_set_epilog

Set the epilog text displayed at the bottom of the help message.

All arguments are concatenated with spaces. The epilog appears after the argument list and is useful for providing additional information, examples, or notes.

### Example

```bash
args_set_epilog "For more information, visit https://example.com"
args_set_epilog "Examples:" "  script.sh file.txt" "  script.sh --verbose file.txt"
```

## args_set_program_name

Set a custom program name for the usage message.

By default, the program name is automatically determined from `$0`. Use this function to override it with a custom name.

### Parameters

|Parameter|Description|
|--:|---|
|`$1`|Program name to display in usage messages|

### Example

```bash
# Set custom program name
args_set_program_name "my_script"

# Usage line will show: "usage: my_script [options]..."
# instead of the actual script filename
```

## args_set_usage_widths

Customize the column widths in the help message for better formatting.

The help message is formatted with four columns: padding, argument names, separator, and help text. This function allows you to adjust these widths to accommodate longer argument names or terminal sizes.

### Parameters

|Parameter|Description|
|--:|---|
|`$1`|Left padding width (spaces before argument names)|
|`$2`|Argument column width (for flags and names)|
|`$3`|Separator width (spaces between argument and help text)|
|`$4`|Help text width (before wrapping)|

### Example

```bash
# Set custom widths
args_set_usage_widths 2 20 2 56
```

**Visual examples:**

<img src="images/headerUsageWidth.drawio.png" />

```bash
args_set_usage_widths 2 20 2 56
```

<img src="images/example1UsageWidth.drawio.png" />

```bash
args_set_usage_widths 2 30 2 15
```

<img src="images/example2UsageWidth.drawio.png" />

```bash
args_set_usage_widths 1 21 1 30
```

<img src="images/example3UsageWidth.drawio.png" />

## args_set_usage

Override the automatically generated usage line with a custom message.

By default, args.sh generates a usage line based on the defined arguments. Use this function to provide a completely custom usage line instead.

All arguments are concatenated. This replaces the entire usage line shown at the top of the help message.

### Example

```bash
# Set a custom usage line
args_set_usage "usage: my_prog [options...]" " -- " "[args...]"

# Result: "usage: my_prog [options...] -- [args...]"
```

## args_usage

Display or generate the help/usage message.

Outputs the formatted help message including the usage line, description, argument list, and epilog. This is automatically called when `-h` or `--help` is used, but can also be called manually.

### Parameters

|Parameter|Description|
|--:|---|
|`$1`|Script name to display in the usage line (optional, defaults to `$0`)|

### Example

```bash
# Manually display usage
args_usage "foo.sh"

# Or let it use the script name automatically
args_usage
```