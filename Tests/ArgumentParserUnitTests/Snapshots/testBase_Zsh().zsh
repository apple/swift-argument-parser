#compdef base-test

_base-test() {
    local -xr SAP_SHELL=zsh
    local -x SAP_SHELL_VERSION
    SAP_SHELL_VERSION="$(builtin emulate zsh -c 'printf %s "${ZSH_VERSION}"')"
    local -r SAP_SHELL_VERSION

    local context state state_descr line
    local -A opt_args

    local -r command_name="${words[1]}"
    local -ar command_line=("${words[@]}")

    local -i ret=1
    local -ar args=(
        '--name[The user'\''s name.]:name:'
        '--kind:kind:(one two custom-three)'
        '--other-kind:other-kind:(b1_zsh b2_zsh b3_zsh)'
        '--path1:path1:_files'
        '--path2:path2:_files'
        '--path3:path3:(c1_zsh c2_zsh c3_zsh)'
        '--one'
        '--two'
        '--three'
        '*--kind-counter'
        '*--rep1:rep1:'
        '*'{-r,--rep2}':rep2:'
        ':argument:{_custom_completion "${command_name}" ---completion  -- argument "${command_line[@]}"}'
        ':nested-argument:{_custom_completion "${command_name}" ---completion  -- nested.nestedArgument "${command_line[@]}"}'
        '(-h --help)'{-h,--help}'[Show help information.]'
        '(-): :->command'
        '(-)*:: :->arg'
    )
    _arguments -w -s -S "${args[@]}" && ret=0
    case "${state}" in
    command)
        local -ar subcommands=(
            'sub-command:'
            'escaped-command:'
            'help:Show subcommand help information.'
        )
        _describe "subcommand" subcommands
        ;;
    arg)
        case "${words[1]}" in
        sub-command)
            _base-test_sub-command
            ;;
        escaped-command)
            _base-test_escaped-command
            ;;
        help)
            _base-test_help
            ;;
        esac
        ;;
    esac

    return "${ret}"
}

_base-test_sub-command() {
    local -i ret=1
    local -ar args=(
        '(-h --help)'{-h,--help}'[Show help information.]'
    )
    _arguments -w -s -S "${args[@]}" && ret=0

    return "${ret}"
}

_base-test_escaped-command() {
    local -i ret=1
    local -ar args=(
        '--one[Escaped chars: '\''\[\]\\.]:one:'
        ':two:{_custom_completion "${command_name}" ---completion escaped-command -- two "${command_line[@]}"}'
        '(-h --help)'{-h,--help}'[Show help information.]'
    )
    _arguments -w -s -S "${args[@]}" && ret=0

    return "${ret}"
}

_base-test_help() {
    local -i ret=1
    local -ar args=(
        ':subcommands:'
    )
    _arguments -w -s -S "${args[@]}" && ret=0

    return "${ret}"
}

_custom_completion() {
    local completions=("${(@f)$($*)}")
    _describe '' completions
}

_base-test
