#compdef base-test
local context state state_descr line
_base_test_commandname=$words[1]
typeset -A opt_args

_base-test() {
    export SAP_SHELL=zsh
    SAP_SHELL_VERSION="$(builtin emulate zsh -c 'printf %s "${ZSH_VERSION}"')"
    export SAP_SHELL_VERSION
    integer ret=1
    local -a args
    args+=(
        '--name[The user'"'"'s name.]:name:'
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
        ':argument:{_custom_completion $_base_test_commandname ---completion  -- argument $words}'
        ':nested-argument:{_custom_completion $_base_test_commandname ---completion  -- nested.nestedArgument $words}'
        '(-h --help)'{-h,--help}'[Show help information.]'
        '(-): :->command'
        '(-)*:: :->arg'
    )
    _arguments -w -s -S $args[@] && ret=0
    case $state in
    command)
        local subcommands
        subcommands=(
            'sub-command:'
            'escaped-command:'
            'help:Show subcommand help information.'
        )
        _describe "subcommand" subcommands
        ;;
    arg)
        case ${words[1]} in
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

    return ret
}

_base-test_sub-command() {
    integer ret=1
    local -a args
    args+=(
        '(-h --help)'{-h,--help}'[Show help information.]'
    )
    _arguments -w -s -S $args[@] && ret=0

    return ret
}

_base-test_escaped-command() {
    integer ret=1
    local -a args
    args+=(
        '--one[Escaped chars: '"'"'\[\]\\.]:one:'
        ':two:{_custom_completion $_base_test_commandname ---completion escaped-command -- two $words}'
        '(-h --help)'{-h,--help}'[Show help information.]'
    )
    _arguments -w -s -S $args[@] && ret=0

    return ret
}

_base-test_help() {
    integer ret=1
    local -a args
    args+=(
        ':subcommands:'
    )
    _arguments -w -s -S $args[@] && ret=0

    return ret
}


_custom_completion() {
    local completions=("${(@f)$($*)}")
    _describe '' completions
}

_base-test
