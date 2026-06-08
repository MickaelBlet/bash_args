#
# args.sh
#
# Licensed under the MIT License <http://opensource.org/licenses/MIT>.
# Copyright (c) 2025 BLET Mickael.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

ARGS_USAGE_RETURN_CODE=64  # return code at help called

declare -A ARGS  # declare ARGS as an associative array
declare -A __ARGS  # declare __ARGS as an associative array

# Clean all argument-related data structures.
# Resets the ARGS and __ARGS associative arrays to their initial state.
args_clean() {
    ARGS=()
    __ARGS=()

    __ARGS[program.name]=""
    __ARGS[usage]=""
    __ARGS[usage.description]=""
    __ARGS[usage.epilog]=""
    __ARGS[usage.width.padding]=2
    __ARGS[usage.width.argument]=20
    __ARGS[usage.width.separator]=2
    __ARGS[usage.width.help]=56
    __ARGS[alternative]="false"

    # positional argument
    __ARGS[argument.size]=0
    # optional argument
    __ARGS[option.size]=0
    # indicate if arguments are sorted
    __ARGS[sorted]="false"
    return 0
}

# Check if an argument or option already exists.
#   Parameters:
#     $1 - The name of the argument or option to check.
#   Returns:
#     0 - If the argument or option exists.
#     1 - If the argument or option does not exist.
__args_already_exists() {
    local type
    local i=0
    local j=0
    while [[ ${i} -lt ${__ARGS[argument.size]} ]]; do
        if [[ "$1" == "${__ARGS[argument.${i}.name]}" ]]; then
            return 0;
        fi
        i=$((i + 1))
    done
    i=0
    while [[ ${i} -lt ${__ARGS[option.size]} ]]; do
        for type in "short" "long"; do
            j=0
            while [[ ${j} -lt ${__ARGS[option.${i}.${type}.size]} ]]; do
                if [[ "$1" == "${__ARGS[option.${i}.${type}.${j}]}" ]]; then
                    return 0;
                fi
                j=$((j + 1))
            done
        done
        i=$((i + 1))
    done
    return 1;
}

# Sort the options in the __ARGS array based on their properties.
__args_sort() {
    if [[ "true" == "${__ARGS[sorted]}" ]]; then
        return 0
    fi
    local n="${__ARGS[option.size]}"
    local i j k src max a b swap
    # Snapshot every option's fields once, so the O(n^2) comparison phase and
    # the reorder move only lightweight indices instead of whole records.
    local -a S_action S_metavar S_help S_default S_dest S_required
    local -a S_exists S_count S_choices S_nargs S_ssize S_lsize
    local -A S_short S_long
    i=0
    while [[ ${i} -lt ${n} ]]; do
        S_action[i]="${__ARGS[option.${i}.action]}"
        S_metavar[i]="${__ARGS[option.${i}.metavar]}"
        S_help[i]="${__ARGS[option.${i}.help]}"
        S_default[i]="${__ARGS[option.${i}.default]}"
        S_dest[i]="${__ARGS[option.${i}.dest]}"
        S_required[i]="${__ARGS[option.${i}.required]}"
        S_exists[i]="${__ARGS[option.${i}.exists]}"
        S_count[i]="${__ARGS[option.${i}.count]}"
        S_choices[i]="${__ARGS[option.${i}.choices]}"
        S_nargs[i]="${__ARGS[option.${i}.nargs]}"
        S_ssize[i]="${__ARGS[option.${i}.short.size]}"
        S_lsize[i]="${__ARGS[option.${i}.long.size]}"
        j=0
        while [[ ${j} -lt ${S_ssize[i]} ]]; do
            S_short[${i}.${j}]="${__ARGS[option.${i}.short.${j}]}"
            j=$((j + 1))
        done
        j=0
        while [[ ${j} -lt ${S_lsize[i]} ]]; do
            S_long[${i}.${j}]="${__ARGS[option.${i}.long.${j}]}"
            j=$((j + 1))
        done
        i=$((i + 1))
    done
    # order[] holds the permutation; bubble-sort it with the original comparator
    # evaluated on the snapshot (identical comparison/swap sequence, hence output).
    local -a order
    i=0
    while [[ ${i} -lt ${n} ]]; do
        order[i]="${i}"
        i=$((i + 1))
    done
    max=$((n - 1))
    while [[ ${max} -gt 0 ]]; do
        i=0
        while [[ ${i} -lt ${max} ]]; do
            a="${order[i]}"
            b="${order[$((i + 1))]}"
            swap="false"
            if [[ 0 -ne ${S_ssize[a]} ]] && [[ 0 -ne ${S_ssize[b]} ]]; then
                if [[ "false" == "${S_required[a]}" ]] && [[ "true" == "${S_required[b]}" ]]; then
                    swap="true"
                elif [[ "false" == "${S_required[a]}" ]] && [[ "${S_short[${a}.0]}" > "${S_short[${b}.0]}" ]]; then
                    swap="true"
                fi
            elif [[ 0 -eq ${S_ssize[a]} ]] && [[ 0 -eq ${S_ssize[b]} ]] && \
                 [[ 0 -ne ${S_lsize[a]} ]] && [[ 0 -ne ${S_lsize[b]} ]]; then
                if [[ "false" == "${S_required[a]}" ]] && [[ "true" == "${S_required[b]}" ]]; then
                    swap="true"
                elif [[ "false" == "${S_required[a]}" ]] && [[ "${S_long[${a}.0]}" > "${S_long[${b}.0]}" ]]; then
                    swap="true"
                fi
            elif [[ 0 -eq ${S_ssize[a]} ]]; then
                swap="true"
            fi
            if [[ "true" == "${swap}" ]]; then
                order[i]="${b}"
                order[$((i + 1))]="${a}"
            fi
            i=$((i + 1))
        done
        max=$((max - 1))
    done
    # Write records back in sorted order and (re)build the O(1) lookup keys.
    # Option tokens are never removed, so every key is overwritten in place;
    # no separate clearing pass is needed (args_clean wipes everything).
    k=0
    while [[ ${k} -lt ${n} ]]; do
        src="${order[k]}"
        __ARGS[option.${k}.action]="${S_action[src]}"
        __ARGS[option.${k}.metavar]="${S_metavar[src]}"
        __ARGS[option.${k}.help]="${S_help[src]}"
        __ARGS[option.${k}.default]="${S_default[src]}"
        __ARGS[option.${k}.dest]="${S_dest[src]}"
        __ARGS[option.${k}.required]="${S_required[src]}"
        __ARGS[option.${k}.exists]="${S_exists[src]}"
        __ARGS[option.${k}.count]="${S_count[src]}"
        __ARGS[option.${k}.choices]="${S_choices[src]}"
        __ARGS[option.${k}.nargs]="${S_nargs[src]}"
        __ARGS[option.${k}.short.size]="${S_ssize[src]}"
        __ARGS[option.${k}.long.size]="${S_lsize[src]}"
        j=0
        while [[ ${j} -lt ${S_ssize[src]} ]]; do
            __ARGS[option.${k}.short.${j}]="${S_short[${src}.${j}]}"
            __ARGS[map.opt.-${S_short[${src}.${j}]}]="${k}"
            __ARGS[map.short.${S_short[${src}.${j}]}]="${k}"
            j=$((j + 1))
        done
        j=0
        while [[ ${j} -lt ${S_lsize[src]} ]]; do
            __ARGS[option.${k}.long.${j}]="${S_long[${src}.${j}]}"
            __ARGS[map.opt.--${S_long[${src}.${j}]}]="${k}"
            __ARGS[map.alt.-${S_long[${src}.${j}]}]="${k}"
            j=$((j + 1))
        done
        k=$((k + 1))
    done
    __ARGS[sorted]="true"
    return 0
}

__args_echo_error() {
    local str
    # generate usage message
    if [[ -n "${__ARGS[program.name]}" ]]; then
        str="${__ARGS[program.name]##*/}"
    else
        str="${1##*/}"
    fi
    shift
    echo "${str}: $*" >&2
    return 0
}

# Find an option by abbreviated long option name.
#   Parameters:
#     $1 - The abbreviated option (e.g., "--verb" for "--verbose").
#     $2 - The binary name for error messages.
#   Returns:
#     0 - If exactly one match is found (prints the option index to stdout).
#     1 - If no match or ambiguous match (prints error to stderr if ambiguous).
__args_parse_option_find_by_abbrev() {
    local abbrev="$1"
    local binary_name="$2"
    local prefix=""
    local search_term=""

    # Extract the prefix and search term
    if [[ "${abbrev}" == "--"* ]]; then
        prefix="--"
        search_term="${abbrev:2}"
    elif [[ "${abbrev}" == "-"* ]]; then
        prefix="-"
        search_term="${abbrev:1}"
    else
        return 1
    fi

    # Only abbreviate long options (prefix must be --)
    if [[ "${prefix}" != "--" ]]; then
        return 1
    fi

    # If it contains '=', only abbreviate the part before '='
    if [[ "${search_term}" == *"="* ]]; then
        search_term="${search_term%%=*}"
    fi

    local matches=()
    local i=0
    local j

    # Search through all long options
    while [[ "${i}" -lt "${__ARGS[option.size]}" ]]; do
        j=0
        while [[ "${j}" -lt "${__ARGS[option.${i}.long.size]}" ]]; do
            local long_opt="${__ARGS[option.${i}.long.${j}]}"
            # Check if the long option starts with the search term
            if [[ "${long_opt}" == "${search_term}"* ]]; then
                matches+=("${i}")
                break
            fi
            j=$((j + 1))
        done
        i=$((i + 1))
    done

    # Check the number of matches
    if [[ ${#matches[@]} -eq 0 ]]; then
        # No match found - return empty
        return 1
    elif [[ ${#matches[@]} -eq 1 ]]; then
        # Single match found - output index
        echo "${matches[0]}"
        return 0
    else
        # Ambiguous abbreviation - print error and output marker
        local matching_options=()
        for i in "${matches[@]}"; do
            j=0
            while [[ "${j}" -lt "${__ARGS[option.${i}.long.size]}" ]]; do
                local long_opt="${__ARGS[option.${i}.long.${j}]}"
                if [[ "${long_opt}" == "${search_term}"* ]]; then
                    matching_options+=("--${long_opt}")
                    break
                fi
                j=$((j + 1))
            done
        done
        args_usage_line "${binary_name}" >&2
        __args_echo_error "${binary_name}" "ambiguous option: '${abbrev}' could match: ${matching_options[*]}"
        echo "AMBIGUOUS"
        return 1
    fi
}

# Check if the value is an alternative value for a specific option.
#   Parameters:
#     $1 - The index of the option.
#     $2 - The value to check.
#   Returns:
#     0 - If the value is an alternative value.
#     1 - If the value is not an alternative value.
__args_parse_option_is_alternative_value() {
    [[ "${__ARGS[map.alt.$2]-}" == "$1" ]]
}

# Check if the value is an alternative assignment value for a specific option.
#   Parameters:
#     $1 - The index of the option.
#     $2 - The value to check.
#   Returns:
#     0 - If the value is an alternative assignment value.
#     1 - If the value is not an alternative assignment value.
__args_parse_option_is_alternative_assign_value() {
    [[ "$2" == *"="* && "${__ARGS[map.alt.${2%%=*}]-}" == "$1" ]]
}

# Check if the value is a valid value for a specific option.
#   Parameters:
#     $1 - The index of the option.
#     $2 - The value to check.
#   Returns:
#     0 - If the value is a valid value.
#     1 - If the value is not a valid value.
__args_parse_option_is_value() {
    [[ "${__ARGS[map.opt.$2]-}" == "$1" ]]
}

# Check if the value is an assignment value for a specific option.
#   Parameters:
#     $1 - The index of the option.
#     $2 - The value to check.
#   Returns:
#     0 - If the value is an assignment value.
#     1 - If the value is not an assignment value.
__args_parse_option_is_assign_value() {
    [[ "$2" == *"="* && "${__ARGS[map.opt.${2%%=*}]-}" == "$1" ]]
}

# Check if the value is a multi-short value for a specific option.
#   Parameters:
#     $1 - The index of the option.
#     $2 - The value to check.
#   Returns:
#     0 - If the value is a multi-short value.
#     1 - If the value is not a multi-short value.
__args_parse_option_is_multi_short_value() {
    [[ "$2" == "-"?* && "$2" != "--"* && "${__ARGS[map.short.${2:1:1}]-}" == "$1" ]]
}

# Check if the value is a multi-short assignment value for a specific option.
#   Parameters:
#     $1 - The index of the option.
#     $2 - The value to check.
#   Returns:
#     0 - If the value is a multi-short assignment value.
#     1 - If the value is not a multi-short assignment value.
__args_parse_option_on_multi_short_value() {
    [[ "${__ARGS[map.short.${2:0:1}]-}" == "$1" ]]
}

# Assign a value to an option in the ARGS array.
#   Parameters:
#     $1 - The index of the option.
#     $2 - The value to assign.
__args_parse_assign_option_value() {
    local index="$1"
    local value="$2"
    local type
    local name
    local i
    for type in "short" "long"; do
        i=0
        while [[ "${i}" -lt "${__ARGS[option.${index}.${type}.size]}" ]]; do
            name="${__ARGS[option.${index}.${type}.${i}]}"
            ARGS[${name}]="${value}"
            i=$((i + 1))
        done
    done
    return 0
}

# Assign a multi-value to an option in the ARGS array.
#   Parameters:
#     $1 - The index of the option.
#     $2 - The index value.
#     $3 - The value to assign.
__args_parse_assign_option_multi_values() {
    local index="$1"
    local index_value="$2"
    local value="$3"
    local i
    local type
    local name
    for type in "short" "long"; do
        i=0
        while [[ "${i}" -lt "${__ARGS[option.${index}.${type}.size]}" ]]; do
            name="${__ARGS[option.${index}.${type}.${i}]}"
            ARGS[${name}.${index_value}]="${value}"
            if [[ -n "${ARGS[${name}]+abracadabra}" ]]; then
                ARGS[${name}]="${ARGS[${name}]} ${value}"
            else
                ARGS[${name}]="${value}"
            fi
            i=$((i + 1))
        done
    done
    return 0
}

# Set the program name.
#   Parameters:
#     $1 - The name of the program.
args_set_program_name() {
    __ARGS[program.name]="$1"
    return 0
}

# Set a description for the usage message.
#   Parameters:
#     $* - The description message.
#   Examples:
#     args_set_description "Your description message"
#     args_set_description "Your" "description" "message" "with" "multiple" "arguments"
args_set_description() {
    __ARGS[usage.description]="$*"
    return 0
}

# Set an epilog for the usage message.
#   Parameters:
#     $* - The epilog message.
#   Examples:
#     args_set_epilog "Your epilog message"
#     args_set_epilog "Your" "epilog" "message" "with" "multiple" "arguments"
args_set_epilog() {
    __ARGS[usage.epilog]="$*"
    return 0
}

# Set the usage message.
#   Parameters:
#     $* - The usage message.
#   Examples:
#     args_set_usage "Your usage message"
#     args_set_usage "Your" "usage" "message" "with" "multiple" "arguments"
args_set_usage() {
    __ARGS[usage]="$*"
    return 0
}

# Set the widths for the usage message.
#   Parameters:
#     $1 - Padding width.
#     $2 - Argument width.
#     $3 - Separator width.
#     $4 - Help width.
#   Examples:
#     args_set_usage_widths 2 56 2 20
args_set_usage_widths() {
    __ARGS[usage.width.padding]="$1"
    __ARGS[usage.width.argument]="$2"
    __ARGS[usage.width.separator]="$3"
    __ARGS[usage.width.help]="$4"
    return 0
}

# Set if args_parse_arguments can be accept a single '-' for a long option.
#   Parameters:
#     $1 - Alternative mode (true/false).
args_set_alternative() {
    if [[ "true" == "$1" ]] || [[ "false" == "$1" ]]; then
        __ARGS[alternative]="$1"
        return 0
    else
        echo "$0: line ${BASH_LINENO[0]}: ${FUNCNAME[0]}: accept only true or false parameter" >&2
        return 1
    fi
}

# Check if argument is exists in argv.
#   Parameters:
#     $1 - Argument name.
args_isexists() {
    local i
    local j
    local type
    local name
    if [[ "$1" == "--"* ]]; then
        name="${1:2}"
    elif [[ "$1" == "-"* ]]; then
        name="${1:1}"
    else
        name="$1"
    fi
    i=0
    while [[ "${i}" -lt "${__ARGS[argument.size]}" ]]; do
        if [[ "${name}" == "${__ARGS[argument.${i}.name]}" ]]; then
            if [[ "true" == "${__ARGS[argument.${i}.exists]}" ]]; then
                return 0
            else
                return 1
            fi
        fi
        i=$((i + 1))
    done
    for type in "short" "long"; do
        i=0
        while [[ "${i}" -lt "${__ARGS[option.size]}" ]]; do
            j=0
            while [[ "${j}" -lt "${__ARGS[option.${i}.${type}.size]}" ]]; do
                if [[ "${name}" == "${__ARGS[option.${i}.${type}.${j}]}" ]]; then
                    if [[ "true" == "${__ARGS[option.${i}.exists]}" ]]; then
                        return 0
                    else
                        return 1
                    fi
                fi
                j=$((j + 1))
            done
            i=$((i + 1))
        done
    done
    echo "${__ARGS[program.name]:-$0}: line ${BASH_LINENO[0]}: ${FUNCNAME[0]}: '$1' is not a valid argument name" >&2
    return 1
}

# Check the count of argument in argv.
#   Parameters:
#     $1 - Argument name.
args_count() {
    local name
    if [[ "$1" == "--"* ]]; then
        name="${1:2}"
    elif [[ "$1" == "-"* ]]; then
        name="${1:1}"
    else
        name="$1"
    fi
    local i=0
    while [[ "${i}" -lt "${__ARGS[argument.size]}" ]]; do
        if [[ "${name}" == "${__ARGS[argument.${i}.name]}" ]]; then
            echo "${__ARGS[argument.${i}.count]}"
            return 0
        fi
        i=$((i + 1))
    done
    local type
    for type in "short" "long"; do
        i=0
        local j
        while [[ "${i}" -lt "${__ARGS[option.size]}" ]]; do
            j=0
            while [[ "${j}" -lt "${__ARGS[option.${i}.${type}.size]}" ]]; do
                if [[ "${name}" == "${__ARGS[option.${i}.${type}.${j}]}" ]]; then
                    echo "${__ARGS[option.${i}.count]}"
                    return 0
                fi
                j=$((j + 1))
            done
            i=$((i + 1))
        done
    done
    echo "${__ARGS[program.name]:-$0}: line ${BASH_LINENO[0]}: ${FUNCNAME[0]}: '$1' is not a valid argument name" >&2
    return 1
}

# Add a argument.
#   Parameters:
#     --action {append, count, store, store_false, store_true}
#                         The action of argument (default: store).
#     --choices CHOICES   List of valid values (separate by spaces).
#     --default DEFAULT   Default(s) value(s) (multi separate by spaces).
#     --dest DESTINATION  Destination variable (global scope).
#     --flag FLAG         Add a optional argument.
#     --help HELP         Usage helper.
#     --metavar METAVAR   Usage argument name (if not set use long/short name).
#     --name NAME         Set the name of positionnal argument.
#     --nargs NARGS       The number of arguments that should be consumed.
#     --required          Is required if exists.
#   Example:
#     args_add_argument --help="help of FOO" --dest="FOO" -- "FOO"
args_add_argument() {
    local action="store"
    local choices=""
    local default=""
    local dest=""
    local help=""
    local metavar=""
    local nargs=1
    local required=false
    local args=()
    while [[ $# -ne 0 ]]; do
        case "${1}" in
            "--")
                shift
                break;;
            "--action")
                if [[ $# -le 1 ]]; then
                    echo "$0: line ${BASH_LINENO[0]}: ${FUNCNAME[0]}: '--action' option require a argument" >&2
                    return 1
                fi
                action="${2,,}"
                shift 2;;
            "--action="*)
                action="${1#*=}"
                action="${action,,}"
                shift;;
            "--choices")
                if [[ $# -le 1 ]]; then
                    echo "$0: line ${BASH_LINENO[0]}: ${FUNCNAME[0]}: '--choices' option require a argument" >&2
                    return 1
                fi
                choices="$2"
                shift 2;;
            "--choices="*)
                choices="${1#*=}"
                shift;;
            "--default")
                if [[ $# -le 1 ]]; then
                    echo "$0: line ${BASH_LINENO[0]}: ${FUNCNAME[0]}: '--default' option require a argument" >&2
                    return 1
                fi
                default="$2"
                shift 2;;
            "--default="*)
                default="${1#*=}"
                shift;;
            "--dest")
                if [[ $# -le 1 ]]; then
                    echo "$0: line ${BASH_LINENO[0]}: ${FUNCNAME[0]}: '--dest' option require a argument" >&2
                    return 1
                fi
                dest="$2"
                shift 2;;
            "--dest="*)
                dest="${1#*=}"
                shift;;
            "--help")
                if [[ $# -le 1 ]]; then
                    echo "$0: line ${BASH_LINENO[0]}: ${FUNCNAME[0]}: '--help' option require a argument" >&2
                    return 1
                fi
                help="$2"
                shift 2;;
            "--help="*)
                help="${1#*=}"
                shift;;
            "--metavar")
                if [[ $# -le 1 ]]; then
                    echo "$0: line ${BASH_LINENO[0]}: ${FUNCNAME[0]}: '--metavar' option require a argument" >&2
                    return 1
                fi
                metavar="$2"
                shift 2;;
            "--metavar="*)
                metavar="${1#*=}"
                shift;;
            "--nargs")
                if [[ $# -le 1 ]]; then
                    echo "$0: line ${BASH_LINENO[0]}: ${FUNCNAME[0]}: '--nargs' option require a argument" >&2
                    return 1
                fi
                nargs="$2"
                shift 2;;
            "--nargs="*)
                nargs="${1#*=}"
                shift;;
            "--required")
                required="true"
                shift;;
            "--name")
                if [[ $# -le 1 ]]; then
                    echo "$0: line ${BASH_LINENO[0]}: ${FUNCNAME[0]}: '--name' option require a argument" >&2
                    return 1
                fi
                args+=("$2")
                shift 2;;
            "--name="*)
                args+=("${1#*=}")
                shift;;
            "--flag")
                if [[ $# -le 1 ]]; then
                    echo "$0: line ${BASH_LINENO[0]}: ${FUNCNAME[0]}: '--flag' option require a argument" >&2
                    return 1
                fi
                args+=("$2")
                shift 2;;
            "--flag="*)
                args+=("${1#*=}")
                shift;;
            "-"*)
                echo "$0: line ${BASH_LINENO[0]}: ${FUNCNAME[0]}: unrecognized option '$1'" >&2
                return 1;;
            *)
                args+=("$1")
                shift;;
        esac
    done

    while [[ $# -ne 0 ]]; do
        args+=("$1")
        shift
    done

    # bad format of action
    if [[ "${action}" != "append" ]] && \
       [[ "${action}" != "count" ]] && \
       [[ "${action}" != "store" ]] && \
       [[ "${action}" != "store_false" ]] && \
       [[ "${action}" != "store_true" ]]; then
        echo "$0: line ${BASH_LINENO[0]}: ${FUNCNAME[0]}: unknown action '${action}'" >&2
        return 1
    fi

    # default and required
    if [[ -n "${default}" ]] && [[ "true" == "${required}" ]]; then
        echo "$0: line ${BASH_LINENO[0]}: ${FUNCNAME[0]}: '--default' used with '--required'" >&2
        return 1
    fi

    # store_true or store_false
    if [[ "store_true" == "${action}" ]] || [[ "store_false" == "${action}" ]]; then
        # default
        if [[ -n "${default}" ]]; then
            echo "$0: line ${BASH_LINENO[0]}: ${FUNCNAME[0]}: '--default' used with action '${action}'" >&2
            return 1
        fi
        # metavar
        if [[ -n "${metavar}" ]]; then
            echo "$0: line ${BASH_LINENO[0]}: ${FUNCNAME[0]}: '--metavar' used with action '${action}'" >&2
            return 1
        fi
    fi

    # choises and not store
    if [[ "${action}" != "store" ]] && [[ -n "${choices}" ]]; then
        echo "$0: line ${BASH_LINENO[0]}: ${FUNCNAME[0]}: '--choices' used without action 'store'" >&2
        return 1
    fi

    # infinite mode
    if [[ "+" == "${nargs}" ]] || [[ "*" == "${nargs}" ]]; then
        if [[ "*" == "${nargs}" ]]; then
            nargs=0
        elif [[ "+" == "${nargs}" ]]; then
            nargs=1
        fi
        action="infinite"
    fi
    if [[ "?" == "${nargs}" ]]; then
        nargs=0
    fi

    if [[ "${nargs}" -gt 1 ]]; then
        # default
        if [[ -n "${default}" ]]; then
            # save last IFS
            local old_ifs
            old_ifs="${IFS}"
            IFS=$' '
            # get number of word
            local word
            local word_nb=0
            for word in ${default}; do
                word+=""
                word_nb=$((word_nb + 1))
            done
            IFS="${old_ifs}"
            if [[ "${word_nb}" -ne "${nargs}" ]]; then
                echo "$0: line ${BASH_LINENO[0]}: ${FUNCNAME[0]}: number word of '--default' (${word_nb}) is not the same of '--nargs' (${nargs})" >&2
                return 1
            fi
        fi
        # choices
        if [[ -n "${choices}" ]]; then
            echo "$0: line ${BASH_LINENO[0]}: ${FUNCNAME[0]}: '--choices' can't used with '--nargs'" >&2
            return 1
        fi
    fi

    if [[ -n "${default}" ]] && [[ -n "${choices}" ]]; then
        local default_exists="false"
        # save last IFS
        local old_ifs
        old_ifs="${IFS}"
        IFS=$' '
        # check if default exists on choices
        local word
        for word in ${choices}; do
            if [[ "${word}" == "${default}" ]]; then
                default_exists="true"
                break
            fi
        done
        IFS="${old_ifs}"
        if [[ "false" == "${default_exists}" ]]; then
            echo "$0: line ${BASH_LINENO[0]}: ${FUNCNAME[0]}: default value '${default}' not present on choices values" >&2
            return 1
        fi
    fi

    # not name or flags
    if [[ ${#args[@]} -eq 0 ]]; then
        echo "$0: line ${BASH_LINENO[0]}: ${FUNCNAME[0]}: need a flag or argument name" >&2
        return 1
    fi

    local is_argument=false
    local is_flag=false
    local short_flags=()
    local long_flags=()
    local argument_name=""
    local arg
    # check format of argument
    for arg in "${args[@]}"; do
        if [[ "${arg}" == "--"* ]]; then
            # already exists
            if __args_already_exists "${arg:2}"; then
                echo "$0: line ${BASH_LINENO[0]}: ${FUNCNAME[0]}: option name '${arg}' already exists" >&2
                return 1
            fi
            is_flag="true"
            [[ ! "${long_flags[*]:-}" =~ (^|[[:space:]])"${arg:2}"($|[[:space:]]) ]] && long_flags+=("${arg:2}")
        elif [[ "${arg}" == "-"* ]]; then
            # size or digit of short
            if [[ "${#arg}" -ne 2 ]] || [[ "${arg}" =~ ^"-"[[:digit:]]$ ]]; then
                echo "$0: line ${BASH_LINENO[0]}: ${FUNCNAME[0]}: short option name '${arg}' not valid" >&2
                return 1
            fi
            # already exists
            if __args_already_exists "${arg:1}"; then
                echo "$0: line ${BASH_LINENO[0]}: ${FUNCNAME[0]}: option name '${arg}' already exists" >&2
                return 1
            fi
            is_flag="true"
            [[ ! "${short_flags[*]:-}" =~ (^|[[:space:]])"${arg:1}"($|[[:space:]]) ]] && short_flags+=("${arg:1}")
        else
            # multi argument name
            if [[ "true" == "${is_argument}" ]]; then
                echo "$0: line ${BASH_LINENO[0]}: ${FUNCNAME[0]}: you can't have multi argument name" >&2
                return 1
            fi
            # empty argument name
            if [[ -z "${arg}" ]]; then
                echo "$0: line ${BASH_LINENO[0]}: ${FUNCNAME[0]}: name of argument is empty" >&2
                return 1
            fi
            # already exists
            if __args_already_exists "${arg}"; then
                echo "$0: line ${BASH_LINENO[0]}: ${FUNCNAME[0]}: argument name '${arg}' already exists" >&2
                return 1
            fi
            is_argument="true"
            argument_name="${arg}"
        fi
        if [[ "true" == "${is_argument}" ]] && \
           [[ "true" == "${is_flag}" ]]; then
            echo "$0: line ${BASH_LINENO[0]}: ${FUNCNAME[0]}: you can't mixte argument and flag(s)" >&2
            return 1
        fi
    done

    # sort flags
    local max
    max="$((${#long_flags[@]} - 1))"
    local i j tmp
    while [[ "${max}" -gt 0 ]]; do
        i=0
        j=1
        while [[ "${i}" -lt "${max}" ]]; do
            if [[ -n "${long_flags[${i}]}" ]] && \
               [[ -n "${long_flags[${j}]}" ]]; then
                if [[ "${long_flags[${i}]}" > "${long_flags[${j}]}" ]]; then
                    tmp="${long_flags[${i}]}"
                    long_flags[${i}]="${long_flags[${j}]}"
                    long_flags[${j}]="${tmp}"
                fi
            fi
            i=$((i + 1))
            j=$((j + 1))
        done
        max=$((max - 1))
    done
    max="$((${#short_flags[@]} - 1))"
    while [[ "${max}" -gt 0 ]]; do
        i=0
        j=1
        while [[ "${i}" -lt "${max}" ]]; do
            if [[ -n "${short_flags[${i}]}" ]] && \
               [[ -n "${short_flags[${j}]}" ]]; then
                if [[ "${short_flags[${i}]}" > "${short_flags[${j}]}" ]]; then
                    tmp="${short_flags[${i}]}"
                    short_flags[${i}]="${short_flags[${j}]}"
                    short_flags[${j}]="${tmp}"
                fi
            fi
            i=$((i + 1))
            j=$((j + 1))
        done
        max=$((max - 1))
    done

    if [[ "true" == "${is_argument}" ]]; then
        __ARGS[argument.${__ARGS[argument.size]}.name]="${argument_name}"
        __ARGS[argument.${__ARGS[argument.size]}.help]="${help}"
        __ARGS[argument.${__ARGS[argument.size]}.default]="${default}"
        __ARGS[argument.${__ARGS[argument.size]}.dest]="${dest}"
        __ARGS[argument.${__ARGS[argument.size]}.required]="${required}"
        __ARGS[argument.${__ARGS[argument.size]}.exists]="false"
        __ARGS[argument.${__ARGS[argument.size]}.count]=0
        __ARGS[argument.${__ARGS[argument.size]}.choices]="${choices}"
        __ARGS[argument.size]=$((${__ARGS[argument.size]} + 1))
    else
        for i in "${!short_flags[@]}"; do
            __ARGS[option.${__ARGS[option.size]}.short.${i}]="${short_flags[${i}]}"
        done
        __ARGS[option.${__ARGS[option.size]}.short.size]="${#short_flags[@]}"

        for i in "${!long_flags[@]}"; do
            __ARGS[option.${__ARGS[option.size]}.long.${i}]="${long_flags[${i}]}"
        done
        __ARGS[option.${__ARGS[option.size]}.long.size]="${#long_flags[@]}"

        if [[ "store_false" == "${action}" ]]; then
            __ARGS[option.${__ARGS[option.size]}.default]="true"
        elif [[ "store_true" == "${action}" ]]; then
            __ARGS[option.${__ARGS[option.size]}.default]="false"
        elif [[ -z "${default}" ]] && [[ "count" == "${action}" ]]; then
            __ARGS[option.${__ARGS[option.size]}.default]="0"
        else
            __ARGS[option.${__ARGS[option.size]}.default]="${default}"
        fi
        __ARGS[option.${__ARGS[option.size]}.action]="${action}"
        __ARGS[option.${__ARGS[option.size]}.metavar]="${metavar}"
        __ARGS[option.${__ARGS[option.size]}.help]="${help}"
        __ARGS[option.${__ARGS[option.size]}.dest]="${dest}"
        __ARGS[option.${__ARGS[option.size]}.required]="${required}"
        __ARGS[option.${__ARGS[option.size]}.exists]="false"
        __ARGS[option.${__ARGS[option.size]}.count]=0
        __ARGS[option.${__ARGS[option.size]}.choices]="${choices}"
        __ARGS[option.${__ARGS[option.size]}.nargs]="${nargs}"
        __ARGS[option.size]=$((${__ARGS[option.size]} + 1))
    fi
    __ARGS[sorted]="false"
    return 0
}

# Show all values of arguments and options
args_debug_values() {
    # get column max of options
    local max_col=0
    local key
    local value
    local i
    local j
    local count
    local type
    i=0
    while [[ "${i}" -lt "${__ARGS[argument.size]}" ]]; do
        count="${#__ARGS[argument.${i}.name]}"
        if [[ ${count} -gt ${max_col} ]]; then
            max_col=${count}
        fi
        i=$((i + 1))
    done
    i=0
    while [[ "${i}" -lt "${__ARGS[option.size]}" ]]; do
        key=""
        for type in "short" "long"; do
            j=0
            while [[ "${j}" -lt "${__ARGS[option.${i}.${type}.size]}" ]]; do
                [[ -n "${key}" ]] && key+=", "
                [[ "short" == "${type}" ]] && key+="-"
                [[ "long" == "${type}" ]] && key+="--"
                key+="${__ARGS[option.${i}.${type}.${j}]}"
                j=$((j + 1))
            done
        done
        count=$((${#key}))
        if [[ ${count} -gt ${max_col} ]]; then
            max_col=${count}
        fi
        i=$((i + 1))
    done

    i=0
    while [[ "${i}" -lt "${__ARGS[argument.size]}" ]]; do
        printf -- "%-*s : %s (count: %s, exists: %s)\n" \
            "${max_col}" \
            "${__ARGS[argument.${i}.name]}" \
            "${ARGS[${__ARGS[argument.${i}.name]}]:-}" \
            "${__ARGS[argument.${i}.count]}" \
            "${__ARGS[argument.${i}.exists]}"
        i=$((i + 1))
    done
    i=0
    while [[ "${i}" -lt "${__ARGS[option.size]}" ]]; do
        key=""
        for type in "short" "long"; do
            j=0
            while [[ "${j}" -lt "${__ARGS[option.${i}.${type}.size]}" ]]; do
                [[ -n "${key}" ]] && key+=", "
                [[ "short" == "${type}" ]] && key+="-"
                [[ "long" == "${type}" ]] && key+="--"
                key+="${__ARGS[option.${i}.${type}.${j}]}"
                j=$((j + 1))
            done
        done
        local name=""
        if [[ "${__ARGS[option.${i}.long.size]}" -ne 0 ]]; then
            name="${__ARGS[option.${i}.long.0]}"
        elif [[ "${__ARGS[option.${i}.short.size]}" -ne 0 ]]; then
            name="${__ARGS[option.${i}.short.0]}"
        fi
        printf -- "%-*s : %s (count: %s, exists: %s)\n" \
            "${max_col}" \
            "${key}" \
            "${ARGS[${name}]:-}" \
            "${__ARGS[option.${i}.count]}" \
            "${__ARGS[option.${i}.exists]}"
        i=$((i + 1))
    done
    return 0
}

# Show/Generate usage line message
#   params:
#     $1  Name/Path of script
args_usage_line() {
    if [[ -n "${__ARGS[usage]}" ]]; then
        echo "${__ARGS[usage]}"
    else
        __args_sort
        local i
        local j
        local str
        local max_col
        local current_col=0
        local has_max_col="false"
        max_col="$((${__ARGS[usage.width.padding]} + ${__ARGS[usage.width.argument]} + ${__ARGS[usage.width.separator]} + ${__ARGS[usage.width.help]}))"
        # generate usage message
        if [[ -n "${__ARGS[program.name]}" ]]; then
            str="usage: ${__ARGS[program.name]##*/}"
        else
            str="usage: ${1##*/}"
        fi
        local usage_basename_length="${#str}"
        local jump_spaces
        printf -v jump_spaces "%*s" "${usage_basename_length}" ""
        current_col="${usage_basename_length}"
        i=0
        while [[ "${i}" -lt "${__ARGS[option.size]}" ]]; do
            local option=""
            option+=" "
            if [[ "false" == "${__ARGS[option.${i}.required]}" ]]; then
                option+="["
            fi
            if [[ "${__ARGS[option.${i}.short.size]}" -ne 0 ]]; then
                option+="-${__ARGS[option.${i}.short.0]}"
            elif [[ "${__ARGS[option.${i}.long.size]}" -ne 0 ]]; then
                option+="--${__ARGS[option.${i}.long.0]}"
            fi
            if [[ "store" == "${__ARGS[option.${i}.action]}" ]] || \
               [[ "append" == "${__ARGS[option.${i}.action]}" ]] || \
               [[ "infinite" == "${__ARGS[option.${i}.action]}" ]]; then
                option+=" "
                if [[ -n "${__ARGS[option.${i}.metavar]}" ]]; then
                    option+="${__ARGS[option.${i}.metavar]}"
                elif [[ -n "${__ARGS[option.${i}.choices]}" ]]; then
                    option+="{${__ARGS[option.${i}.choices]// /,}}"
                else
                    if [[ "${__ARGS[option.${i}.long.size]}" -ne 0 ]]; then
                        local option_argument="${__ARGS[option.${i}.long.0]^^}"
                        option+="${option_argument//-/_}"
                    else
                        option+="${__ARGS[option.${i}.short.0]^^}"
                    fi
                    if [[ "infinite" == "${__ARGS[option.${i}.action]}" ]]; then
                        option+="..."
                    fi
                fi
            fi
            if [[ "false" == "${__ARGS[option.${i}.required]}" ]]; then
                option+="]"
            fi
            if [[ "$((current_col + ${#option}))" -gt "${max_col}" ]]; then
                has_max_col="true"
                str+=$'\n'
                str+="${jump_spaces}"
                current_col="${usage_basename_length}"
            fi
            str+="${option}"
            current_col="$((current_col + ${#option}))"
            i=$((i + 1))
        done
        if [[ "${__ARGS[argument.size]}" -ne 0 ]]; then
            if [[ "true" == "${has_max_col}" ]] || [[ "$((current_col + 3))" -gt "${max_col}" ]]; then
                str+=$'\n'
                str+="${jump_spaces}"
                str+=" --"
                str+=$'\n'
                str+="${jump_spaces}"
                current_col="${usage_basename_length}"
            else
                str+=" --"
                current_col="$((current_col + 3))"
            fi
        fi
        i=0
        while [[ "${i}" -lt "${__ARGS[argument.size]}" ]]; do
            local option=""
            option+=" "
            if [[ "true" == "${__ARGS[argument.${i}.required]}" ]]; then
                if [[ -n "${__ARGS[argument.${i}.choices]}" ]]; then
                    option+="{${__ARGS[argument.${i}.choices]// /,}}"
                else
                    option+="${__ARGS[argument.${i}.name]}"
                fi
            else
                if [[ -n "${__ARGS[argument.${i}.choices]}" ]]; then
                    option+="[{${__ARGS[argument.${i}.choices]// /,}}]"
                else
                    option+="[${__ARGS[argument.${i}.name]}]"
                fi
            fi
            if [[ "$((current_col + ${#option}))" -gt "${max_col}" ]]; then
                str+=$'\n'
                str+="${jump_spaces}"
                current_col="${usage_basename_length}"
            fi
            str+="${option}"
            current_col="$((current_col + ${#option}))"
            i=$((i + 1))
        done
        str+=$'\n'
        echo -n "${str}"
    fi
    return 0
}

# Show/Generate usage message
#   params:
#     $1  Name/Path of script
args_usage() {
    if [[ -n "${__ARGS[usage]}" ]]; then
        echo "${__ARGS[usage]}"
    else
        local i
        local j
        local str
        local max_col
        local current_col=0
        local has_max_col="false"
        local jump_spaces
        local jump_spaces_padding
        local jump_spaces_helper
        printf -v jump_spaces_padding "%*s" "${__ARGS[usage.width.padding]}" ""
        printf -v jump_spaces_helper "%*s" "$((${__ARGS[usage.width.padding]} + ${__ARGS[usage.width.argument]} + ${__ARGS[usage.width.separator]} - 1))" ""
        max_col="$((${__ARGS[usage.width.padding]} + ${__ARGS[usage.width.argument]} + ${__ARGS[usage.width.separator]} + ${__ARGS[usage.width.help]}))"
        args_usage_line "$1"
        str=""
        if [[ -n "${__ARGS[usage.description]}" ]]; then
            str+=$'\n'
            str+="${__ARGS[usage.description]}"
            str+=$'\n'
        fi
        if [[ "${__ARGS[argument.size]}" -ne 0 ]]; then
            str+=$'\n'
            str+="positional arguments:"
            str+=$'\n'
        fi
        i=0
        while [[ "${i}" -lt "${__ARGS[argument.size]}" ]]; do
            str+="${jump_spaces_padding}"
            local option=""
            if [[ -n "${__ARGS[argument.${i}.choices]}" ]]; then
                option+="{${__ARGS[argument.${i}.choices]// /,}}"
            else
                option+="${__ARGS[argument.${i}.name]}"
            fi
            str+="${option}"
            if [[ -n "${__ARGS[argument.${i}.help]}" ]]; then
                if [[ "${#option}" -gt "${__ARGS[usage.width.argument]}" ]]; then
                    str+=$'\n'
                    str+="${jump_spaces_helper}"
                else
                    printf -v jump_spaces "%*s" "$((${__ARGS[usage.width.argument]} - ${#option} + ${__ARGS[usage.width.separator]} - 1))" ""
                    str+="${jump_spaces}"
                fi
                current_col="${#jump_spaces_helper}"
                # save last IFS
                local old_ifs
                old_ifs="${IFS}"
                IFS=$' \t\n'
                local word=""
                for word in ${__ARGS[argument.${i}.help]}; do
                    if [[ "$((current_col + ${#word} + 1))" -gt "$((${__ARGS[usage.width.padding]} + ${__ARGS[usage.width.argument]} + ${__ARGS[usage.width.separator]} + ${__ARGS[usage.width.help]}))" ]]; then
                        str+=$'\n'
                        str+="${jump_spaces_helper}"
                        current_col="${#jump_spaces_helper}"
                    fi
                    str+=" ${word}"
                    current_col="$((current_col + ${#word} + 1))"
                done
                IFS="${old_ifs}"
            fi
            str+=$'\n'
            i=$((i + 1))
        done
        if [[ "${__ARGS[option.size]}" -ne 0 ]]; then
            str+=$'\n'
            str+="optional arguments:"
            str+=$'\n'
        fi
        i=0
        while [[ "${i}" -lt "${__ARGS[option.size]}" ]]; do
            str+="${jump_spaces_padding}"
            local option=""
            local type
            for type in "short" "long"; do
                j=0
                while [[ "${j}" -lt "${__ARGS[option.${i}.${type}.size]}" ]]; do
                    [[ -n "${option}" ]] && option+=", "
                    [[ "short" == "${type}" ]] && option+="-"
                    [[ "long" == "${type}" ]] && option+="--"
                    option+="${__ARGS[option.${i}.${type}.${j}]}"
                    j=$((j + 1))
                done
            done

            if [[ "store" == "${__ARGS[option.${i}.action]}" ]] || \
               [[ "append" == "${__ARGS[option.${i}.action]}" ]] || \
               [[ "infinite" == "${__ARGS[option.${i}.action]}" ]]; then
                option+=" "
                if [[ -n "${__ARGS[option.${i}.metavar]}" ]]; then
                    option+="${__ARGS[option.${i}.metavar]}"
                elif [[ -n "${__ARGS[option.${i}.choices]}" ]]; then
                    option+="{${__ARGS[option.${i}.choices]// /,}}"
                else
                    if [[ "${__ARGS[option.${i}.long.size]}" -ne 0 ]]; then
                        local option_argument="${__ARGS[option.${i}.long.0]^^}"
                        option+="${option_argument//-/_}"
                    else
                        option+="${__ARGS[option.${i}.short.0]^^}"
                    fi
                    if [[ "infinite" == "${__ARGS[option.${i}.action]}" ]]; then
                        option+="..."
                    fi
                fi
            fi
            str+="${option}"

            if [[ -n "${__ARGS[option.${i}.help]}" ]]; then
                if [[ "${#option}" -gt "${__ARGS[usage.width.argument]}" ]]; then
                    str+=$'\n'
                    str+="${jump_spaces_helper}"
                else
                    printf -v jump_spaces "%*s" "$((${__ARGS[usage.width.argument]} - ${#option} + ${__ARGS[usage.width.separator]} - 1))" ""
                    str+="${jump_spaces}"
                fi
                current_col="${#jump_spaces_helper}"
                # save last IFS
                local old_ifs
                old_ifs="${IFS}"
                IFS=$' \t\n'
                local word=""
                for word in ${__ARGS[option.${i}.help]}; do
                    if [[ "$((current_col + ${#word} + 1))" -gt "$((${__ARGS[usage.width.padding]} + ${__ARGS[usage.width.argument]} + ${__ARGS[usage.width.separator]} + ${__ARGS[usage.width.help]}))" ]]; then
                        str+=$'\n'
                        str+="${jump_spaces_helper}"
                        current_col="${#jump_spaces_helper}"
                    fi
                    str+=" ${word}"
                    current_col="$((current_col + ${#word} + 1))"
                done
                IFS="${old_ifs}"
            fi
            str+=$'\n'
            i=$((i + 1))
        done
        if [[ -n "${__ARGS[usage.epilog]}" ]]; then
            str+=$'\n'
            str+="${__ARGS[usage.epilog]}"
            str+=$'\n'
        fi
        echo -n "${str}"
    fi
    return 0
}

# Use after args_add_argument functions
# Convert argument strings to objects and assign them as attributes on the ARGS map
# Previous calls to args_add_argument
# determine exactly what objects are created and how they are assigned
# Execute this with "$@" parameters
args_parse_arguments() {
    local binary_name="$0"
    local help_options=()
    if ! __args_already_exists "h" && ! __args_already_exists "help"; then
        help_options+=("-h")
        help_options+=("--help")
        args_add_argument --action="store_true" --help="print this help message" -- "-h" "--help"
    elif ! __args_already_exists "h"; then
        help_options+=("-h")
        args_add_argument --action="store_true" --help="print this help message" -- "-h"
    elif ! __args_already_exists "help"; then
        help_options+=("--help")
        args_add_argument --action="store_true" --help="print this help message" -- "--help"
    fi
    __args_sort
    local i
    local j
    local cand
    local acand
    local positional_index=0
    while true; do
        if [[ $# -eq 0 ]]; then
            break
        fi
        if [[ "--" == "$1" ]]; then
            shift
            break
        fi
        for i in "${!help_options[@]}"; do
            if [[ "true" == "${__ARGS[alternative]}" ]] && \
               [[ "--help" == "${help_options[i]}" ]] && \
               [[ "-help" == "${1}" ]]; then
                args_usage "${binary_name}"
                return "${ARGS_USAGE_RETURN_CODE}"
            fi
            if [[ "${1}" == "${help_options[i]}" ]]; then
                args_usage "${binary_name}"
                return "${ARGS_USAGE_RETURN_CODE}"
            fi
        done
        # Get options (fast O(1) lookup -> candidate option index)
        if [[ "true" == "${__ARGS[alternative]}" ]]; then
            acand=""
            [[ "$1" == *"="* ]] && acand="${__ARGS[map.alt.${1%%=*}]-}"
            [[ -z "${acand}" ]] && acand="${__ARGS[map.alt.$1]-}"
            i="${acand:-${__ARGS[option.size]}}"
            while [[ "${i}" -lt "${__ARGS[option.size]}" ]]; do
                if __args_parse_option_is_alternative_value "${i}" "$1"; then
                    if [[ "${__ARGS[option.${i}.nargs]}" -gt 1 ]]; then
                        local option_name="$1"
                        local nargs=0
                        while [[ "${nargs}" -lt "${__ARGS[option.${i}.nargs]}" ]]; do
                            if [[ $# -le 1 ]] || [[ "--" == "$2" ]]; then
                                args_usage_line "${binary_name}"
                                __args_echo_error "${binary_name}" "option '${option_name}' require '${__ARGS[option.${i}.nargs]}' arguments"
                                return 1
                            fi
                            __args_parse_assign_option_multi_values "${i}" "${nargs}" "$2"
                            nargs=$((nargs + 1))
                            shift
                        done
                        __ARGS[option.${i}.count]=$((${__ARGS[option.${i}.count]} + 1))
                        __ARGS[option.${i}.exists]="true"
                        shift
                    elif [[ "infinite" == "${__ARGS[option.${i}.action]}" ]]; then
                        local option_name="$1"
                        while true; do
                            if [[ $# -le 1 ]] || \
                               [[ "--" == "$2" ]] || \
                               [[ "$2" =~ ^"-"[[:alpha:]] ]] || \
                               [[ "$2" =~ ^"--"[[:alpha:]] ]]; then
                                break
                            fi
                            __args_parse_assign_option_multi_values "${i}" "${__ARGS[option.${i}.count]}" "$2"
                            __ARGS[option.${i}.count]=$((${__ARGS[option.${i}.count]} + 1))
                            shift
                        done
                        __ARGS[option.${i}.exists]="true"
                        shift
                    elif [[ "append" == "${__ARGS[option.${i}.action]}" ]]; then
                        local value=""
                        if [[ $# -le 1 ]] || [[ "--" == "$2" ]]; then
                            args_usage_line "${binary_name}"
                            __args_echo_error "${binary_name}" "option '$1' require a argument"
                            return 1
                        fi
                        value="$2"
                        if [[ -n "${__ARGS[option.${i}.choices]}" ]] && \
                           [[ ! "${__ARGS[option.${i}.choices]}" =~ (^|[[:space:]])"${value}"($|[[:space:]]) ]]; then
                            args_usage_line "${binary_name}"
                            __args_echo_error "${binary_name}" "option '${value}' is not a valid choise (${__ARGS[option.${i}.choices]// /, })"
                            return 1
                        fi
                        __args_parse_assign_option_multi_values "${i}" "${__ARGS[option.${i}.count]}" "${value}"
                        __ARGS[option.${i}.count]=$((${__ARGS[option.${i}.count]} + 1))
                        __ARGS[option.${i}.exists]="true"
                        shift 2
                    else
                        local value=""
                        if [[ "store" == "${__ARGS[option.${i}.action]}" ]]; then
                            if [[ $# -le 1 ]] || [[ "--" == "$2" ]] || \
                               { [[ "0" == "${__ARGS[option.${i}.nargs]}" ]] && \
                                 { [[ "$2" =~ ^"-"[[:alpha:]] ]] || [[ "$2" =~ ^"--"[[:alpha:]] ]]; }; }; then
                                if [[ "0" != "${__ARGS[option.${i}.nargs]}" ]]; then
                                    args_usage_line "${binary_name}"
                                    __args_echo_error "${binary_name}" "option '$1' require a argument"
                                    return 1
                                fi
                                value=""
                            else
                                value="$2"
                                if [[ -n "${__ARGS[option.${i}.choices]}" ]] && \
                                [[ ! "${__ARGS[option.${i}.choices]}" =~ (^|[[:space:]])"${value}"($|[[:space:]]) ]]; then
                                    args_usage_line "${binary_name}"
                                    __args_echo_error "${binary_name}" "option '${value}' is not a valid choise (${__ARGS[option.${i}.choices]// /, })"
                                    return 1
                                fi
                                shift
                            fi
                        elif [[ "store_true" == "${__ARGS[option.${i}.action]}" ]]; then
                            value="true"
                        elif [[ "store_false" == "${__ARGS[option.${i}.action]}" ]]; then
                            value="false"
                        elif [[ "count" == "${__ARGS[option.${i}.action]}" ]]; then
                            value=$((${__ARGS[option.${i}.count]} + 1))
                        fi
                        __args_parse_assign_option_value "${i}" "${value}"
                        __ARGS[option.${i}.count]=$((${__ARGS[option.${i}.count]} + 1))
                        __ARGS[option.${i}.exists]="true"
                        shift
                    fi
                    break
                elif __args_parse_option_is_alternative_assign_value "${i}" "$1"; then
                    if [[ "store" == "${__ARGS[option.${i}.action]}" ]] || \
                       [[ "append" == "${__ARGS[option.${i}.action]}" ]]; then
                        local value=""
                        value="${1#*=}"
                        if [[ -n "${__ARGS[option.${i}.choices]}" ]] && \
                           [[ ! "${__ARGS[option.${i}.choices]}" =~ (^|[[:space:]])"${value}"($|[[:space:]]) ]]; then
                            args_usage_line "${binary_name}"
                            __args_echo_error "${binary_name}" "option '${value}' is not a valid choise (${__ARGS[option.${i}.choices]// /, })"
                            return 1
                        fi
                        if [[ "append" == "${__ARGS[option.${i}.action]}" ]]; then
                            __args_parse_assign_option_multi_values "${i}" "${__ARGS[option.${i}.count]}" "${value}"
                        else
                            __args_parse_assign_option_value "${i}" "${value}"
                        fi
                        __ARGS[option.${i}.count]=$((${__ARGS[option.${i}.count]} + 1))
                        __ARGS[option.${i}.exists]="true"
                        shift
                    else
                        args_usage_line "${binary_name}"
                        __args_echo_error "${binary_name}" "option '$1' don't take a argument"
                        return 1
                    fi
                    break
                fi
                i=$((i + 1))
            done
            if [[ "${i}" -eq "${__ARGS[option.size]}" ]]; then
                i=0
            else
                continue
            fi
        fi
        cand=""
        [[ "$1" == *"="* ]] && cand="${__ARGS[map.opt.${1%%=*}]-}"
        [[ -z "${cand}" ]] && cand="${__ARGS[map.opt.$1]-}"
        [[ -z "${cand}" && "$1" == "-"?* && "$1" != "--"* ]] && cand="${__ARGS[map.short.${1:1:1}]-}"
        i="${cand:-${__ARGS[option.size]}}"
        while [[ "${i}" -lt "${__ARGS[option.size]}" ]]; do
            if __args_parse_option_is_value "${i}" "$1"; then
                if [[ "${__ARGS[option.${i}.nargs]}" -gt 1 ]]; then
                    local option_name="$1"
                    local nargs=0
                    while [[ "${nargs}" -lt "${__ARGS[option.${i}.nargs]}" ]]; do
                        if [[ $# -le 1 ]] || [[ "--" == "$2" ]]; then
                            args_usage_line "${binary_name}"
                            __args_echo_error "${binary_name}" "option '${option_name}' require '${__ARGS[option.${i}.nargs]}' arguments"
                            return 1
                        fi
                        __args_parse_assign_option_multi_values "${i}" "${nargs}" "$2"
                        nargs=$((nargs + 1))
                        shift
                    done
                    __ARGS[option.${i}.count]=$((${__ARGS[option.${i}.count]} + 1))
                    __ARGS[option.${i}.exists]="true"
                    shift
                elif [[ "infinite" == "${__ARGS[option.${i}.action]}" ]]; then
                    local option_name="$1"
                    while true; do
                        if [[ $# -le 1 ]] || \
                           [[ "--" == "$2" ]] || \
                           [[ "$2" =~ ^"-"[[:alpha:]] ]] || \
                           [[ "$2" =~ ^"--"[[:alpha:]] ]]; then
                            break
                        fi
                        __args_parse_assign_option_multi_values "${i}" "${__ARGS[option.${i}.count]}" "$2"
                        __ARGS[option.${i}.count]=$((${__ARGS[option.${i}.count]} + 1))
                        shift
                    done
                    __ARGS[option.${i}.exists]="true"
                    shift
                elif [[ "append" == "${__ARGS[option.${i}.action]}" ]]; then
                    local value=""
                    if [[ $# -le 1 ]] || [[ "--" == "$2" ]]; then
                        args_usage_line "${binary_name}"
                        __args_echo_error "${binary_name}" "option '$1' require a argument"
                        return 1
                    fi
                    value="$2"
                    if [[ -n "${__ARGS[option.${i}.choices]}" ]] && \
                       [[ ! "${__ARGS[option.${i}.choices]}" =~ (^|[[:space:]])"${value}"($|[[:space:]]) ]]; then
                        args_usage_line "${binary_name}"
                        __args_echo_error "${binary_name}" "option '${value}' is not a valid choise (${__ARGS[option.${i}.choices]// /, })"
                        return 1
                    fi
                    __args_parse_assign_option_multi_values "${i}" "${__ARGS[option.${i}.count]}" "${value}"
                    __ARGS[option.${i}.count]=$((${__ARGS[option.${i}.count]} + 1))
                    __ARGS[option.${i}.exists]="true"
                    shift 2
                else
                    local value=""
                    if [[ "store" == "${__ARGS[option.${i}.action]}" ]]; then
                        if [[ $# -le 1 ]] || [[ "--" == "$2" ]] || \
                           { [[ "0" == "${__ARGS[option.${i}.nargs]}" ]] && \
                             { [[ "$2" =~ ^"-"[[:alpha:]] ]] || [[ "$2" =~ ^"--"[[:alpha:]] ]]; }; }; then
                            if [[ "0" != "${__ARGS[option.${i}.nargs]}" ]]; then
                                args_usage_line "${binary_name}"
                                __args_echo_error "${binary_name}" "option '$1' require a argument"
                                return 1
                            fi
                            value=""
                        else
                            value="$2"
                            if [[ -n "${__ARGS[option.${i}.choices]}" ]] && \
                               [[ ! "${__ARGS[option.${i}.choices]}" =~ (^|[[:space:]])"${value}"($|[[:space:]]) ]]; then
                                args_usage_line "${binary_name}"
                                __args_echo_error "${binary_name}" "option '${value}' is not a valid choise (${__ARGS[option.${i}.choices]// /, })"
                                return 1
                            fi
                            shift
                        fi
                    elif [[ "store_true" == "${__ARGS[option.${i}.action]}" ]]; then
                        value="true"
                    elif [[ "store_false" == "${__ARGS[option.${i}.action]}" ]]; then
                        value="false"
                    elif [[ "count" == "${__ARGS[option.${i}.action]}" ]]; then
                        value=$((${__ARGS[option.${i}.count]} + 1))
                    fi
                    __args_parse_assign_option_value "${i}" "${value}"
                    __ARGS[option.${i}.count]=$((${__ARGS[option.${i}.count]} + 1))
                    __ARGS[option.${i}.exists]="true"
                    shift
                fi
                break
            elif __args_parse_option_is_assign_value "${i}" "$1"; then
                if [[ "store" == "${__ARGS[option.${i}.action]}" ]] || \
                   [[ "append" == "${__ARGS[option.${i}.action]}" ]]; then
                    local value=""
                    value="${1#*=}"
                    if [[ -n "${__ARGS[option.${i}.choices]}" ]] && \
                       [[ ! "${__ARGS[option.${i}.choices]}" =~ (^|[[:space:]])"${value}"($|[[:space:]]) ]]; then
                        args_usage_line "${binary_name}"
                        __args_echo_error "${binary_name}" "option '${value}' is not a valid choise (${__ARGS[option.${i}.choices]// /, })"
                        return 1
                    fi
                    if [[ "append" == "${__ARGS[option.${i}.action]}" ]]; then
                        __args_parse_assign_option_multi_values "${i}" "${__ARGS[option.${i}.count]}" "${value}"
                    else
                        __args_parse_assign_option_value "${i}" "${value}"
                    fi
                    __ARGS[option.${i}.count]=$((${__ARGS[option.${i}.count]} + 1))
                    __ARGS[option.${i}.exists]="true"
                    shift
                else
                    args_usage_line "${binary_name}"
                    __args_echo_error "${binary_name}" "option '$1' don't take a argument"
                    return 1
                fi
                break
            elif __args_parse_option_is_multi_short_value "${i}" "$1"; then
                local value=""
                if [[ "store" == "${__ARGS[option.${i}.action]}" ]] || \
                   [[ "append" == "${__ARGS[option.${i}.action]}" ]]; then
                    value="${1:2}"
                    if [[ -n "${__ARGS[option.${i}.choices]}" ]] && [[ ! "${__ARGS[option.${i}.choices]}" =~ (^|[[:space:]])"${value}"($|[[:space:]]) ]]; then
                        args_usage_line "${binary_name}"
                        __args_echo_error "${binary_name}" "option '${value}' is not a valid choise (${__ARGS[option.${i}.choices]// /, })"
                        return 1
                    fi
                    if [[ "append" == "${__ARGS[option.${i}.action]}" ]]; then
                        __args_parse_assign_option_multi_values "${i}" "${__ARGS[option.${i}.count]}" "${value}"
                    else
                        __args_parse_assign_option_value "${i}" "${value}"
                    fi
                    __ARGS[option.${i}.count]=$((${__ARGS[option.${i}.count]} + 1))
                    __ARGS[option.${i}.exists]="true"
                else
                    # remove first '-'
                    value="${1:1}"
                    local i_short
                    local value_short
                    while [[ ${#value} -ge 1 ]]; do
                        value_short="${value:0:1}"
                        value="${value:1}"
                        # Get options (direct short-char lookup)
                        i_short="${__ARGS[map.short.${value_short}]:-${__ARGS[option.size]}}"
                        while [[ "${i_short}" -lt "${__ARGS[option.size]}" ]]; do
                            if __args_parse_option_on_multi_short_value "${i_short}" "${value_short}"; then
                                if [[ "store_true" == "${__ARGS[option.${i_short}.action]}" ]]; then
                                    value_short="true"
                                elif [[ "store_false" == "${__ARGS[option.${i_short}.action]}" ]]; then
                                    value_short="false"
                                elif [[ "count" == "${__ARGS[option.${i_short}.action]}" ]]; then
                                    value_short=$((${__ARGS[option.${i_short}.count]} + 1))
                                else
                                    if [[ ${#value} -ge 1 ]]; then
                                        value_short="${value}"
                                        value=""
                                        if [[ -n "${__ARGS[option.${i_short}.choices]}" ]] && \
                                           [[ ! "${__ARGS[option.${i_short}.choices]}" =~ (^|[[:space:]])"${value_short}"($|[[:space:]]) ]]; then
                                            args_usage_line "${binary_name}"
                                            __args_echo_error "${binary_name}" "option '${value_short}' is not a valid choise (${__ARGS[option.${i_short}.choices]// /, })"
                                            return 1
                                        fi
                                    elif [[ $# -gt 1 ]] && \
                                         [[ "$2" != "--" ]]; then
                                        value_short="$2"
                                        value=""
                                        if [[ -n "${__ARGS[option.${i_short}.choices]}" ]] && \
                                           [[ ! "${__ARGS[option.${i_short}.choices]}" =~ (^|[[:space:]])"${value_short}"($|[[:space:]]) ]]; then
                                            args_usage_line "${binary_name}"
                                            __args_echo_error "${binary_name}" "option '${value_short}' is not a valid choise (${__ARGS[option.${i_short}.choices]// /, })"
                                            return 1
                                        fi
                                        shift
                                    else
                                        args_usage_line "${binary_name}"
                                        __args_echo_error "${binary_name}" "option '${value_short}' require a argument"
                                        return 1
                                    fi
                                fi
                                if [[ "append" == "${__ARGS[option.${i_short}.action]}" ]]; then
                                    __args_parse_assign_option_multi_values "${i_short}" "${__ARGS[option.${i_short}.count]}" "${value_short}"
                                elif [[ "infinite" == "${__ARGS[option.${i_short}.action]}" ]]; then
                                    __args_parse_assign_option_multi_values "${i_short}" "${__ARGS[option.${i_short}.count]}" "${value_short}"
                                else
                                    __args_parse_assign_option_value "${i_short}" "${value_short}"
                                fi
                                __ARGS[option.${i_short}.count]=$((${__ARGS[option.${i_short}.count]} + 1))
                                __ARGS[option.${i_short}.exists]="true"
                                break
                            fi
                            i_short=$((i_short + 1))
                        done
                        if [[ "${i_short}" -eq "${__ARGS[option.size]}" ]]; then
                            args_usage_line "${binary_name}"
                            __args_echo_error "${binary_name}" "invalid option -- '-${value_short}'"
                            return 1
                        fi
                    done
                fi
                shift
                break
            fi
            i=$((i + 1))
        done
        if [[ "${i}" -eq "${__ARGS[option.size]}" ]]; then
            # Try abbreviation matching for long options
            if [[ "$1" == "--"* ]] || ( [[ "true" == "${__ARGS[alternative]}" ]] && [[ "$1" == "-"* ]] && [[ "$1" != "-"[[:alpha:]] ]] ); then
                local abbrev_match=""
                local abbrev_arg="$1"

                # For alternative mode, convert single dash to double dash for abbreviation search
                if [[ "true" == "${__ARGS[alternative]}" ]] && [[ "$1" == "-"* ]] && [[ "$1" != "-"[[:alpha:]] ]]; then
                    abbrev_arg="--${1:1}"
                fi

                # Try to find a match by abbreviation
                abbrev_match=$(__args_parse_option_find_by_abbrev "${abbrev_arg}" "${binary_name}" || true)
                if [[ "${abbrev_match}" == "AMBIGUOUS" ]]; then
                    # Ambiguous match - error already printed, just return
                    return 1
                elif [[ -n "${abbrev_match}" ]]; then
                    # Match found - abbrev_match contains the option index
                    i="${abbrev_match}"

                    # Now handle the abbreviated option (same logic as exact match)
                    if [[ "$1" == *"="* ]]; then
                        # Handle assignment (--opt=value or -opt=value in alternative mode)
                        if [[ "store" == "${__ARGS[option.${i}.action]}" ]] || \
                           [[ "append" == "${__ARGS[option.${i}.action]}" ]]; then
                            local value=""
                            value="${1#*=}"
                            if [[ -n "${__ARGS[option.${i}.choices]}" ]] && \
                               [[ ! "${__ARGS[option.${i}.choices]}" =~ (^|[[:space:]])"${value}"($|[[:space:]]) ]]; then
                                args_usage_line "${binary_name}"
                                __args_echo_error "${binary_name}" "option '${value}' is not a valid choise (${__ARGS[option.${i}.choices]// /, })"
                                return 1
                            fi
                            if [[ "append" == "${__ARGS[option.${i}.action]}" ]]; then
                                __args_parse_assign_option_multi_values "${i}" "${__ARGS[option.${i}.count]}" "${value}"
                            else
                                __args_parse_assign_option_value "${i}" "${value}"
                            fi
                            __ARGS[option.${i}.count]=$((${__ARGS[option.${i}.count]} + 1))
                            __ARGS[option.${i}.exists]="true"
                            shift
                        else
                            args_usage_line "${binary_name}"
                            __args_echo_error "${binary_name}" "option '$1' don't take a argument"
                            return 1
                        fi
                    else
                        # Handle non-assignment option
                        if [[ "${__ARGS[option.${i}.nargs]}" -gt 1 ]]; then
                            local option_name="$1"
                            local nargs=0
                            while [[ "${nargs}" -lt "${__ARGS[option.${i}.nargs]}" ]]; do
                                if [[ $# -le 1 ]] || [[ "--" == "$2" ]]; then
                                    args_usage_line "${binary_name}"
                                    __args_echo_error "${binary_name}" "option '${option_name}' require '${__ARGS[option.${i}.nargs]}' arguments"
                                    return 1
                                fi
                                __args_parse_assign_option_multi_values "${i}" "${nargs}" "$2"
                                nargs=$((nargs + 1))
                                shift
                            done
                            __ARGS[option.${i}.count]=$((${__ARGS[option.${i}.count]} + 1))
                            __ARGS[option.${i}.exists]="true"
                            shift
                        elif [[ "infinite" == "${__ARGS[option.${i}.action]}" ]]; then
                            while true; do
                                if [[ $# -le 1 ]] || \
                                   [[ "--" == "$2" ]] || \
                                   [[ "$2" =~ ^"-"[[:alpha:]] ]] || \
                                   [[ "$2" =~ ^"--"[[:alpha:]] ]]; then
                                    break
                                fi
                                __args_parse_assign_option_multi_values "${i}" "${__ARGS[option.${i}.count]}" "$2"
                                __ARGS[option.${i}.count]=$((${__ARGS[option.${i}.count]} + 1))
                                shift
                            done
                            __ARGS[option.${i}.exists]="true"
                            shift
                        elif [[ "append" == "${__ARGS[option.${i}.action]}" ]]; then
                            local value=""
                            if [[ $# -le 1 ]] || [[ "--" == "$2" ]]; then
                                args_usage_line "${binary_name}"
                                __args_echo_error "${binary_name}" "option '$1' require a argument"
                                return 1
                            fi
                            value="$2"
                            if [[ -n "${__ARGS[option.${i}.choices]}" ]] && \
                               [[ ! "${__ARGS[option.${i}.choices]}" =~ (^|[[:space:]])"${value}"($|[[:space:]]) ]]; then
                                args_usage_line "${binary_name}"
                                __args_echo_error "${binary_name}" "option '${value}' is not a valid choise (${__ARGS[option.${i}.choices]// /, })"
                                return 1
                            fi
                            __args_parse_assign_option_multi_values "${i}" "${__ARGS[option.${i}.count]}" "${value}"
                            __ARGS[option.${i}.count]=$((${__ARGS[option.${i}.count]} + 1))
                            __ARGS[option.${i}.exists]="true"
                            shift 2
                        else
                            local value=""
                            if [[ "store" == "${__ARGS[option.${i}.action]}" ]]; then
                                if [[ $# -le 1 ]] || [[ "--" == "$2" ]]; then
                                    args_usage_line "${binary_name}"
                                    __args_echo_error "${binary_name}" "option '$1' require a argument"
                                    return 1
                                fi
                                value="$2"
                                if [[ -n "${__ARGS[option.${i}.choices]}" ]] && \
                                   [[ ! "${__ARGS[option.${i}.choices]}" =~ (^|[[:space:]])"${value}"($|[[:space:]]) ]]; then
                                    args_usage_line "${binary_name}"
                                    __args_echo_error "${binary_name}" "option '${value}' is not a valid choise (${__ARGS[option.${i}.choices]// /, })"
                                    return 1
                                fi
                                shift
                            elif [[ "store_true" == "${__ARGS[option.${i}.action]}" ]]; then
                                value="true"
                            elif [[ "store_false" == "${__ARGS[option.${i}.action]}" ]]; then
                                value="false"
                            elif [[ "count" == "${__ARGS[option.${i}.action]}" ]]; then
                                value=$((${__ARGS[option.${i}.count]} + 1))
                            fi
                            __args_parse_assign_option_value "${i}" "${value}"
                            __ARGS[option.${i}.count]=$((${__ARGS[option.${i}.count]} + 1))
                            __ARGS[option.${i}.exists]="true"
                            shift
                        fi
                    fi
                    continue
                fi
                # No match found - fall through to invalid option error
            fi

            # No exact or abbreviated match found - report error
            if [[ "$1" == "--"* ]]; then
                args_usage_line "${binary_name}"
                __args_echo_error "${binary_name}" "invalid option -- '$1'"
                return 1
            elif [[ "$1" == "-"* ]]; then
                args_usage_line "${binary_name}"
                __args_echo_error "${binary_name}" "invalid option -- '${1:0:2}'"
                return 1
            fi
            if [[ "${positional_index}" -lt "${__ARGS[argument.size]}" ]]; then
                if [[ -n "${__ARGS[argument.${positional_index}.choices]}" ]] && \
                   [[ ! "${__ARGS[argument.${positional_index}.choices]}" =~ (^|[[:space:]])"$1"($|[[:space:]]) ]]; then
                    args_usage_line "${binary_name}"
                    __args_echo_error "${binary_name}" "argument '$1' is not a valid choise (${__ARGS[argument.${positional_index}.choices]// /, })"
                    return 1
                fi
                local name=""
                name="${__ARGS[argument.${positional_index}.name]}"
                ARGS[${name}]="$1"
                __ARGS[argument.${positional_index}.count]=$((${__ARGS[argument.${positional_index}.count]} + 1))
                __ARGS[argument.${positional_index}.exists]="true"
                positional_index=$((positional_index + 1))
                shift
            else
                args_usage_line "${binary_name}"
                __args_echo_error "${binary_name}" "extra argument(s) '$*'"
                return 1
            fi
        fi
    done
    # Get arguments
    if [[ $# -gt 0 ]]; then
        while [[ "${positional_index}" -lt "${__ARGS[argument.size]}" ]]; do
            if [[ -n "${__ARGS[argument.${positional_index}.choices]}" ]] && \
               [[ ! "${__ARGS[argument.${positional_index}.choices]}" =~ (^|[[:space:]])"$1"($|[[:space:]]) ]]; then
                args_usage_line "${binary_name}"
                __args_echo_error "${binary_name}" "argument '$1' is not a valid choise (${__ARGS[argument.${j}.choices]// /, })"
                return 1
            fi
            local name=""
            name="${__ARGS[argument.${positional_index}.name]}"
            ARGS[${name}]="$1"
            __ARGS[argument.${positional_index}.count]=$((${__ARGS[argument.${positional_index}.count]} + 1))
            __ARGS[argument.${positional_index}.exists]="true"
            positional_index=$((positional_index + 1))
            shift
            if [[ $# -eq 0 ]]; then
                break
            fi
        done
    fi
    if [[ $# -ne 0 ]]; then
        args_usage_line "${binary_name}"
        __args_echo_error "${binary_name}" "extra argument(s) '$*'"
        return 1
    fi
    # Required
    i=0
    while [[ "${i}" -lt "${__ARGS[option.size]}" ]]; do
        if [[ "true" == "${__ARGS[option.${i}.required]}" ]]; then
            if [[ "false" == "${__ARGS[option.${i}.exists]}" ]]; then
                local name=""
                if [[ "${__ARGS[option.${i}.short.size]}" -ne 0 ]]; then
                    name="-${__ARGS[option.${i}.short.0]}"
                elif [[ "${__ARGS[option.${i}.long.size]}" -ne 0 ]]; then
                    name="--${__ARGS[option.${i}.long.0]}"
                fi
                args_usage_line "${binary_name}"
                __args_echo_error "${binary_name}" "option '${name}' is required"
                return 1
            fi
        fi
        i=$((i + 1))
    done
    i=0
    while [[ "${i}" -lt "${__ARGS[argument.size]}" ]]; do
        if [[ "true" == "${__ARGS[argument.${i}.required]}" ]]; then
            if [[ "false" == "${__ARGS[argument.${i}.exists]}" ]]; then
                args_usage_line "${binary_name}"
                __args_echo_error "${binary_name}" "argument '${__ARGS[argument.${i}.name]}' is required"
                return 1
            fi
        fi
        i=$((i + 1))
    done
    # Default
    i=0
    while [[ "${i}" -lt "${__ARGS[option.size]}" ]]; do
        if [[ "false" == "${__ARGS[option.${i}.exists]}" ]] && [[ -n "${__ARGS[option.${i}.default]}" ]]; then
            if [[ "${__ARGS[option.${i}.nargs]}" -gt 1 ]] || \
               [[ "infinite" == "${__ARGS[option.${i}.action]}" ]] || \
               [[ "append" == "${__ARGS[option.${i}.action]}" ]]; then
                # save last IFS
                local old_ifs
                old_ifs="${IFS}"
                IFS=$' '
                local value_default
                local index_default=0
                for value_default in ${__ARGS[option.${i}.default]}; do
                    __args_parse_assign_option_multi_values "${i}" "${index_default}" "${value_default}"
                    index_default=$((index_default + 1))
                done
                IFS="${old_ifs}"
                if [[ "infinite" == "${__ARGS[option.${i}.action]}" ]] || \
                   [[ "append" == "${__ARGS[option.${i}.action]}" ]]; then
                    __ARGS[option.${i}.count]="${index_default}"
                fi
            else
                __args_parse_assign_option_value "${i}" "${__ARGS[option.${i}.default]}"
            fi
        fi
        i=$((i + 1))
    done
    i=0
    while [[ "${i}" -lt "${__ARGS[argument.size]}" ]]; do
        if [[ "false" == "${__ARGS[argument.${i}.exists]}" ]] && [[ -n "${__ARGS[argument.${i}.default]}" ]]; then
            local name=""
            name="${__ARGS[argument.${i}.name]}"
            ARGS[${name}]="${__ARGS[argument.${i}.default]}"
        fi
        i=$((i + 1))
    done
    # Dest
    i=0
    while [[ "${i}" -lt "${__ARGS[option.size]}" ]]; do
        if [[ -n "${__ARGS[option.${i}.dest]}" ]]; then
            if [[ "${__ARGS[option.${i}.nargs]}" -gt 1 ]] || \
               [[ "infinite" == "${__ARGS[option.${i}.action]}" ]] || \
               [[ "append" == "${__ARGS[option.${i}.action]}" ]]; then
                declare -a -g "${__ARGS[option.${i}.dest]}=()"
                local nargs=0
                local nargs_max
                if [[ "infinite" == "${__ARGS[option.${i}.action]}" ]] || \
                   [[ "append" == "${__ARGS[option.${i}.action]}" ]]; then
                    nargs_max="${__ARGS[option.${i}.count]}"
                else
                    nargs_max="${__ARGS[option.${i}.nargs]}"
                fi
                while [[ "${nargs}" -lt "${nargs_max}" ]]; do
                    local name=""
                    if [[ "${__ARGS[option.${i}.short.size]}" -ne 0 ]]; then
                        name="${__ARGS[option.${i}.short.0]}"
                    elif [[ "${__ARGS[option.${i}.long.size]}" -ne 0 ]]; then
                        name="${__ARGS[option.${i}.long.0]}"
                    fi
                    declare -a -g "${__ARGS[option.${i}.dest]}+=('${ARGS[${name}.${nargs}]:-}')"
                    nargs=$((nargs + 1))
                done
            else
                local name=""
                if [[ "${__ARGS[option.${i}.short.size]}" -ne 0 ]]; then
                    name="${__ARGS[option.${i}.short.0]}"
                elif [[ "${__ARGS[option.${i}.long.size]}" -ne 0 ]]; then
                    name="${__ARGS[option.${i}.long.0]}"
                fi
                declare -a -g "${__ARGS[option.${i}.dest]}=${ARGS[${name}]:-}"
            fi
        fi
        i=$((i + 1))
    done
    i=0
    while [[ "${i}" -lt "${__ARGS[argument.size]}" ]]; do
        if [[ -n "${__ARGS[argument.${i}.dest]}" ]]; then
            declare -a -g "${__ARGS[argument.${i}.dest]}=${ARGS[${__ARGS[argument.${i}.name]}]:-}"
        fi
        i=$((i + 1))
    done
    return 0
}

# source call clean args
args_clean
