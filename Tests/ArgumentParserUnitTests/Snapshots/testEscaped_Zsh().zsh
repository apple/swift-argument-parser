#compdef escaped-command
local context state state_descr line
_escaped_command_commandname=$words[1]
typeset -A opt_args

_escaped-command() {
    export SAP_SHELL=zsh
    SAP_SHELL_VERSION="$(builtin emulate zsh -c 'printf %s "${ZSH_VERSION}"')"
    export SAP_SHELL_VERSION
    integer ret=1
    local -a args
    args+=(
        '--one[Escaped chars: '"'"'\[\]\\.]:one:'
        ':two:{_custom_completion $_escaped_command_commandname ---completion  -- two $words}'
        '(-h --help)'{-h,--help}'[Show help information.]'
    )
    _arguments -w -s -S $args[@] && ret=0

    return ret
}


_custom_completion() {
    local completions=("${(@f)$($*)}")
    _describe '' completions
}

_escaped-command
