#compdef defaultasflag-test

__defaultasflag-test_complete() {
    local -ar non_empty_completions=("${@:#(|:*)}")
    local -ar empty_completions=("${(M)@:#(|:*)}")
    _describe -V '' non_empty_completions -- empty_completions -P $'\'\''
}

__defaultasflag-test_custom_complete() {
    local -a completions
    completions=("${(@f)"$("${command_name}" "${@}" "${command_line[@]}")"}")
    if [[ "${#completions[@]}" -gt 1 ]]; then
        __defaultasflag-test_complete "${completions[@]:0:-1}"
    fi
}

__defaultasflag-test_cursor_index_in_current_word() {
    if [[ -z "${QIPREFIX}${IPREFIX}${PREFIX}" ]]; then
        printf 0
    else
        printf %s "${#${(z)LBUFFER}[-1]}"
    fi
}

_defaultasflag-test() {
    emulate -RL zsh -G
    setopt extendedglob nullglob numericglobsort
    unsetopt aliases banghist

    local -xr SAP_SHELL=zsh
    local -x SAP_SHELL_VERSION
    SAP_SHELL_VERSION="$(builtin emulate zsh -c 'printf %s "${ZSH_VERSION}"')"
    local -r SAP_SHELL_VERSION

    local context state state_descr line
    local -A opt_args

    local -r command_name="${words[1]}"
    local -ar command_line=("${words[@]}")
    local -ir current_word_index="$((CURRENT - 1))"

    local -i ret=1
    local -ar ___log_level=('DEBUG' 'INFO' 'WARN' 'ERROR')
    local -ar arg_specs=(
        '--bin-path:bin-path:_files -/'
        '--count:count:'
        '--verbose:verbose:'
        '--log-level:log-level:{__defaultasflag-test_complete "${___log_level[@]}"}'
        '--help'
        ':input:_files'
        '(-h --help)'{-h,--help}'[Show help information.]'
        '(-): :->command'
        '(-)*:: :->arg'
    )
    _arguments -w -s -S : "${arg_specs[@]}" && ret=0
    case "${state}" in
    command)
        local -ar subcommands=(
            'help:Show subcommand help information.'
        )
        _describe -V subcommand subcommands
        ;;
    arg)
        case "${words[1]}" in
        help)
            "_defaultasflag-test_${words[1]}"
            ;;
        esac
        ;;
    esac

    return "${ret}"
}

_defaultasflag-test_help() {
    local -i ret=1
    local -ar arg_specs=(
        '*:subcommands:'
    )
    _arguments -w -s -S : "${arg_specs[@]}" && ret=0

    return "${ret}"
}

_defaultasflag-test