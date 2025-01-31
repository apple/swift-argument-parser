#!/bin/bash

# positional arguments:
#
# - 1: the current (sub)command's count of positional arguments
#
# required variables:
#
# - flags: the flags that the current (sub)command can accept
# - options: the options that the current (sub)command can accept
# - positional_number: value ignored
# - unparsed_words: unparsed words from the current command line
#
# modified variables:
#
# - flags: remove flags for this (sub)command that are already on the command line
# - options: remove options for this (sub)command that are already on the command line
# - positional_number: set to the current positional number
# - unparsed_words: remove all flags, options, and option values for this (sub)command
__base_test_offer_flags_options() {
    local -ir positional_count="${1}"
    positional_number=0

    local was_flag_option_terminator_seen=false
    local is_parsing_option_value=false

    local -ar unparsed_word_indices=("${!unparsed_words[@]}")
    local -i word_index
    for word_index in "${unparsed_word_indices[@]}"; do
        if "${is_parsing_option_value}"; then
            # This word is an option value:
            # Reset marker for next word iff not currently the last word
            [[ "${word_index}" -ne "${unparsed_word_indices[${#unparsed_word_indices[@]} - 1]}" ]] && is_parsing_option_value=false
            unset "unparsed_words[${word_index}]"
            # Do not process this word as a flag or an option
            continue
        fi

        local word="${unparsed_words["${word_index}"]}"
        if ! "${was_flag_option_terminator_seen}"; then
            case "${word}" in
            --)
                unset "unparsed_words[${word_index}]"
                # by itself -- is a flag/option terminator, but if it is the last word, it is the start of a completion
                if [[ "${word_index}" -ne "${unparsed_word_indices[${#unparsed_word_indices[@]} - 1]}" ]]; then
                    was_flag_option_terminator_seen=true
                fi
                continue
                ;;
            -*)
                # ${word} is a flag or an option
                # If ${word} is an option, mark that the next word to be parsed is an option value
                # TODO: handle joined-value options (-o=file.ext), stacked flags (-aBc), legacy long (-long), combos
                # TODO: if multi-valued options can exist, support them
                local option
                for option in "${options[@]}"; do
                    [[ "${word}" = "${option}" ]] && is_parsing_option_value=true && break
                done

                # Remove ${word} from ${flags} or ${options} so it isn't offered again
                # TODO: handle repeatable flags & options
                # TODO: remove equivalent options (-h/--help) & exclusive options (--yes/--no)
                local not_found=true
                local -i index
                for index in "${!flags[@]}"; do
                    if [[ "${flags[${index}]}" = "${word}" ]]; then
                        unset "flags[${index}]"
                        flags=("${flags[@]}")
                        not_found=false
                        break
                    fi
                done
                if "${not_found}"; then
                    for index in "${!options[@]}"; do
                        if [[ "${options[${index}]}" = "${word}" ]]; then
                            unset "options[${index}]"
                            options=("${options[@]}")
                            break
                        fi
                    done
                fi
                unset "unparsed_words[${word_index}]"
                continue
                ;;
            esac
        fi

        # ${word} is neither a flag, nor an option, nor an option value
        # TODO: can SAP be configured to require options before positionals?
        if [[ "${positional_number}" -lt "${positional_count}" ]]; then
            # ${word} is a positional
            ((positional_number++))
            unset "unparsed_words[${word_index}]"
        else
            if [[ -z "${word}" ]]; then
                # Could be completing a flag, option, or subcommand
                positional_number=-1
            else
                # ${word} is a subcommand or invalid, so stop processing this (sub)command
                positional_number=-2
            fi
            break
        fi
    done

    unparsed_words=("${unparsed_words[@]}")

    # TODO: offer flags & options after all positionals iff they're allowed after positionals
    if\
        ! "${was_flag_option_terminator_seen}"\
        && ! "${is_parsing_option_value}"\
        && [[ ("${cur}" = -* && "${positional_number}" -ge 0) || "${positional_number}" -eq -1 ]]
    then
        COMPREPLY+=($(compgen -W "${flags[*]} ${options[*]}" -- "${cur}"))
    fi
}

__base_test_add_completions() {
    local completion
    while IFS='' read -r completion; do
        COMPREPLY+=("${completion}")
    done < <(IFS=$'\n' compgen "${@}" -- "${cur}")
}

_base_test() {
    trap "$(shopt -p);$(shopt -po)" RETURN
    shopt -s extglob
    set +o history +o posix

    local -xr SAP_SHELL=bash
    local -x SAP_SHELL_VERSION
    SAP_SHELL_VERSION="$(IFS='.';printf %s "${BASH_VERSINFO[*]}")"
    local -r SAP_SHELL_VERSION

    local -r cur="${2}"
    local -r prev="${3}"

    local -i positional_number
    local -a unparsed_words=("${COMP_WORDS[@]:1:${COMP_CWORD}}")

    local -a flags=(--one --two --three --kind-counter -h --help)
    local -a options=(--name --kind --other-kind --path1 --path2 --path3 --rep1 -r --rep2)
    __base_test_offer_flags_options 2

    # Offer option value completions
    # TODO: only if ${prev} matches -* & is not an option value
    case "${prev}" in
    --name)
        return
        ;;
    --kind)
        COMPREPLY+=($(compgen -W "one two custom-three" -- "${cur}"))
        return
        ;;
    --other-kind)
        COMPREPLY+=($(compgen -W "b1_bash b2_bash b3_bash" -- "${cur}"))
        return
        ;;
    --path1)
        __base_test_add_completions -f
        return
        ;;
    --path2)
        __base_test_add_completions -f
        return
        ;;
    --path3)
        COMPREPLY+=($(compgen -W "c1_bash c2_bash c3_bash" -- "${cur}"))
        return
        ;;
    --rep1)
        return
        ;;
    -r|--rep2)
        return
        ;;
    esac

    # Offer positional completions
    case "${positional_number}" in
    1)
        COMPREPLY+=($(compgen -W "$("${COMP_WORDS[0]}" ---completion  -- argument "${COMP_WORDS[@]}")" -- "${cur}"))
        return
        ;;
    2)
        COMPREPLY+=($(compgen -W "$("${COMP_WORDS[0]}" ---completion  -- nested.nestedArgument "${COMP_WORDS[@]}")" -- "${cur}"))
        return
        ;;
    esac

    # Offer subcommand / subcommand argument completions
    local -r subcommand="${unparsed_words[0]}"
    unset 'unparsed_words[0]'
    unparsed_words=("${unparsed_words[@]}")
    case "${subcommand}" in
    sub-command|escaped-command|help)
        # Offer subcommand argument completions
        "_base_test_${subcommand}"
        ;;
    *)
        # Offer subcommand completions
        COMPREPLY+=($(compgen -W 'sub-command escaped-command help' -- "${cur}"))
        ;;
    esac
}

_base_test_sub_command() {
    flags=(-h --help)
    options=()
    __base_test_offer_flags_options 0
}

_base_test_escaped_command() {
    flags=(-h --help)
    options=(--one)
    __base_test_offer_flags_options 1

    # Offer option value completions
    # TODO: only if ${prev} matches -* & is not an option value
    case "${prev}" in
    --one)
        return
        ;;
    esac

    # Offer positional completions
    case "${positional_number}" in
    1)
        COMPREPLY+=($(compgen -W "$("${COMP_WORDS[0]}" ---completion escaped-command -- two "${COMP_WORDS[@]}")" -- "${cur}"))
        return
        ;;
    esac
}

_base_test_help() {
    :
}

complete -o filenames -F _base_test base-test